// Integrations Controller — Whoop OAuth + sync
import { Request, Response } from 'express'
import crypto from 'crypto'
import { supabaseServiceClient, getUserFromToken } from '../services/supabase.js'
import { WhoopService } from '../services/integrations/whoop.js'
import type { APIResponse } from '../types/api.js'

const whoopService = new WhoopService()

export class IntegrationsController {

  // List all connected integrations for the authenticated user
  static async getIntegrations(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      if (!token) return res.status(401).json({ error: 'Authorization token required' })

      const user = await getUserFromToken(token)

      const { data, error } = await supabaseServiceClient
        .from('user_integrations')
        .select('service, external_user_id, last_sync_at, connected_at')
        .eq('user_id', user.id)

      if (error) throw error

      const integrations: Record<string, { connected: boolean; last_sync?: string; connected_at?: string }> = {
        whoop: { connected: false },
        strava: { connected: false },
        apple_health: { connected: false }
      }

      for (const row of data || []) {
        integrations[row.service] = {
          connected: true,
          last_sync: row.last_sync_at ?? undefined,
          connected_at: row.connected_at ?? undefined
        }
      }

      const response: APIResponse = { success: true, data: integrations }
      res.json(response)
    } catch (error: any) {
      console.error('Error getting integrations:', error)
      res.status(500).json({ success: false, error: { error: 'Internal server error', message: error.message } })
    }
  }

  // Generate Whoop OAuth authorization URL
  static async getWhoopAuthUrl(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      if (!token) return res.status(401).json({ error: 'Authorization token required' })

      const user = await getUserFromToken(token)

      const redirectUri = process.env.WHOOP_REDIRECT_URI || `${process.env.API_BASE_URL || 'http://localhost:3000'}/api/integrations/whoop/callback`
      const state = crypto.randomBytes(32).toString('hex')

      // Store state in a short-lived record so we can verify on callback
      // For simplicity, encode user_id in the state
      const statePayload = Buffer.from(JSON.stringify({ user_id: user.id, nonce: state })).toString('base64url')

      const authUrl = whoopService.getAuthorizationUrl(redirectUri, statePayload)

      const response: APIResponse = { success: true, data: { auth_url: authUrl, state: statePayload } }
      res.json(response)
    } catch (error: any) {
      console.error('Error generating Whoop auth URL:', error)
      res.status(500).json({ success: false, error: { error: 'Internal server error', message: error.message } })
    }
  }

  // Exchange authorization code for tokens and store them
  static async connectWhoop(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      if (!token) return res.status(401).json({ error: 'Authorization token required' })

      const user = await getUserFromToken(token)
      const { code, redirect_uri } = req.body

      if (!code) {
        return res.status(400).json({ success: false, error: { error: 'Bad request', message: 'Authorization code is required' } })
      }

      const redirectUri = redirect_uri || process.env.WHOOP_REDIRECT_URI || `${process.env.API_BASE_URL || 'http://localhost:3000'}/api/integrations/whoop/callback`

      // Exchange code for tokens
      const tokens = await whoopService.exchangeCodeForTokens(code, redirectUri)

      // Get Whoop user profile for external_user_id
      const profile = await whoopService.getUserProfile(tokens.access_token)

      const expiresAt = new Date(Date.now() + tokens.expires_in * 1000).toISOString()

      // Upsert integration record
      const { error: upsertError } = await supabaseServiceClient
        .from('user_integrations')
        .upsert({
          user_id: user.id,
          service: 'whoop',
          access_token: tokens.access_token,
          refresh_token: tokens.refresh_token,
          token_expires_at: expiresAt,
          external_user_id: String(profile.user_id),
          connected_at: new Date().toISOString()
        }, { onConflict: 'user_id,service' })

      if (upsertError) throw upsertError

      // Update users table flag
      await supabaseServiceClient
        .from('users')
        .update({ whoop_connected: true })
        .eq('id', user.id)

      const response: APIResponse = { success: true, message: 'Whoop connected successfully' }
      res.json(response)
    } catch (error: any) {
      console.error('Error connecting Whoop:', error)
      res.status(500).json({ success: false, error: { error: 'Internal server error', message: error.message } })
    }
  }

  // Disconnect Whoop — delete tokens and update flag
  static async disconnectWhoop(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      if (!token) return res.status(401).json({ error: 'Authorization token required' })

      const user = await getUserFromToken(token)

      const { error: deleteError } = await supabaseServiceClient
        .from('user_integrations')
        .delete()
        .eq('user_id', user.id)
        .eq('service', 'whoop')

      if (deleteError) throw deleteError

      await supabaseServiceClient
        .from('users')
        .update({ whoop_connected: false })
        .eq('id', user.id)

      const response: APIResponse = { success: true, message: 'Whoop disconnected' }
      res.json(response)
    } catch (error: any) {
      console.error('Error disconnecting Whoop:', error)
      res.status(500).json({ success: false, error: { error: 'Internal server error', message: error.message } })
    }
  }

  // OAuth callback — Whoop redirects here after user authorizes
  // This is a GET route with no auth middleware (browser redirect)
  static async whoopCallback(req: Request, res: Response) {
    try {
      const { code, state } = req.query

      if (!code || !state) {
        return res.status(400).send('Missing code or state parameter')
      }

      // Decode state to get user_id
      let statePayload: { user_id: string; nonce: string }
      try {
        statePayload = JSON.parse(Buffer.from(String(state), 'base64url').toString())
      } catch {
        return res.status(400).send('Invalid state parameter')
      }

      const userId = statePayload.user_id
      if (!userId) {
        return res.status(400).send('Invalid state: missing user_id')
      }

      const redirectUri = process.env.WHOOP_REDIRECT_URI || `${process.env.API_BASE_URL || 'http://localhost:3000'}/api/integrations/whoop/callback`

      // Exchange code for tokens
      const tokens = await whoopService.exchangeCodeForTokens(String(code), redirectUri)

      // Get Whoop user profile for external_user_id
      const profile = await whoopService.getUserProfile(tokens.access_token)

      const expiresAt = new Date(Date.now() + tokens.expires_in * 1000).toISOString()

      // Upsert integration record
      const { error: upsertError } = await supabaseServiceClient
        .from('user_integrations')
        .upsert({
          user_id: userId,
          service: 'whoop',
          access_token: tokens.access_token,
          refresh_token: tokens.refresh_token,
          token_expires_at: expiresAt,
          external_user_id: String(profile.user_id),
          connected_at: new Date().toISOString()
        }, { onConflict: 'user_id,service' })

      if (upsertError) throw upsertError

      // Update users table flag
      await supabaseServiceClient
        .from('users')
        .update({ whoop_connected: true })
        .eq('id', userId)

      // Redirect to iOS app via deep link
      const deepLink = `dailyritual://whoop/connected?success=true`
      res.redirect(deepLink)
    } catch (error: any) {
      console.error('Error in Whoop OAuth callback:', error)
      // Redirect to app with error
      const deepLink = `dailyritual://whoop/connected?success=false&error=${encodeURIComponent(error.message)}`
      res.redirect(deepLink)
    }
  }

  // Get combined Whoop data (recovery + sleep + strain) for a date
  static async getWhoopData(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      if (!token) return res.status(401).json({ error: 'Authorization token required' })

      const user = await getUserFromToken(token)
      const date = (req.query.date as string) || new Date().toISOString().split('T')[0]!

      // Check for connected integration
      const { data: integration, error: fetchError } = await supabaseServiceClient
        .from('user_integrations')
        .select('*')
        .eq('user_id', user.id)
        .eq('service', 'whoop')
        .single()

      if (fetchError || !integration) {
        return res.status(400).json({
          success: false,
          error: { error: 'Not connected', message: 'Whoop is not connected' }
        })
      }

      // Check server-side cache
      const { data: cached } = await supabaseServiceClient
        .from('whoop_daily_data')
        .select('*')
        .eq('user_id', user.id)
        .eq('date', date)
        .single()

      const cacheAge = cached?.fetched_at
        ? Date.now() - new Date(cached.fetched_at).getTime()
        : Infinity
      const CACHE_TTL = 15 * 60 * 1000 // 15 minutes

      if (cached && cacheAge < CACHE_TTL) {
        return res.json({ success: true, data: formatWhoopResponse(cached) })
      }

      // Refresh token if needed
      let accessToken = integration.access_token!
      if (integration.token_expires_at && new Date(integration.token_expires_at) < new Date()) {
        const refreshed = await whoopService.refreshAccessToken(integration.refresh_token!)
        accessToken = refreshed.access_token
        await supabaseServiceClient
          .from('user_integrations')
          .update({
            access_token: refreshed.access_token,
            refresh_token: refreshed.refresh_token,
            token_expires_at: new Date(Date.now() + refreshed.expires_in * 1000).toISOString()
          })
          .eq('id', integration.id)
      }

      // Fetch all data in parallel
      const [recoveryData, sleepData, strainData] = await Promise.all([
        whoopService.getRecoveryData(accessToken, date),
        whoopService.getSleepData(accessToken, date),
        whoopService.getStrainData(accessToken, date)
      ])

      if (!recoveryData && !sleepData && !strainData) {
        return res.json({ success: true, data: null, message: 'No Whoop data available for this date' })
      }

      // Compute recovery zone
      const recoveryScore = recoveryData?.recovery_score ?? 0
      const recoveryZone = recoveryScore >= 67 ? 'green' : recoveryScore >= 34 ? 'yellow' : 'red'

      // Upsert cache
      const cacheRow = {
        user_id: user.id,
        date,
        recovery_score: recoveryData?.recovery_score ?? null,
        recovery_zone: recoveryData ? recoveryZone : null,
        sleep_performance: sleepData?.performance ?? recoveryData?.sleep_performance ?? null,
        sleep_duration_minutes: sleepData?.duration_minutes ?? null,
        sleep_efficiency: sleepData?.efficiency ?? null,
        sleep_stages: sleepData?.stages ?? null,
        respiratory_rate: sleepData?.respiratory_rate ?? null,
        skin_temp_delta: sleepData?.skin_temp_delta ?? null,
        hrv: recoveryData?.hrv ?? null,
        resting_hr: recoveryData?.resting_hr ?? null,
        strain_score: strainData?.strain_score ?? null,
        fetched_at: new Date().toISOString()
      }

      await supabaseServiceClient
        .from('whoop_daily_data')
        .upsert(cacheRow as any, { onConflict: 'user_id,date' })

      res.json({ success: true, data: formatWhoopResponse(cacheRow) })
    } catch (error: any) {
      console.error('Error fetching Whoop data:', error)
      res.status(500).json({ success: false, error: { error: 'Internal server error', message: error.message } })
    }
  }

  // Manual sync — pull Whoop workouts for a date range
  static async syncWhoop(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      if (!token) return res.status(401).json({ error: 'Authorization token required' })

      const user = await getUserFromToken(token)

      // Get stored tokens
      const { data: integration, error: fetchError } = await supabaseServiceClient
        .from('user_integrations')
        .select('*')
        .eq('user_id', user.id)
        .eq('service', 'whoop')
        .single()

      if (fetchError || !integration) {
        return res.status(400).json({ success: false, error: { error: 'Not connected', message: 'Whoop is not connected' } })
      }

      // Refresh token if expired
      let accessToken = integration.access_token!
      if (integration.token_expires_at && new Date(integration.token_expires_at) < new Date()) {
        const refreshed = await whoopService.refreshAccessToken(integration.refresh_token!)
        accessToken = refreshed.access_token
        const expiresAt = new Date(Date.now() + refreshed.expires_in * 1000).toISOString()

        await supabaseServiceClient
          .from('user_integrations')
          .update({
            access_token: refreshed.access_token,
            refresh_token: refreshed.refresh_token,
            token_expires_at: expiresAt
          })
          .eq('id', integration.id)
      }

      // Default: sync last 7 days
      const endDate = req.body.end_date || new Date().toISOString().split('T')[0]
      const startDate = req.body.start_date || (() => {
        const d = new Date()
        d.setDate(d.getDate() - 7)
        return d.toISOString().split('T')[0]
      })()

      const workouts = await whoopService.getWorkouts(accessToken!, startDate, endDate)

      // Import each workout
      const imported: string[] = []
      for (const workout of workouts) {
        const result = await whoopService.importWhoopWorkout(user.id, workout)
        if (result) imported.push(result)
      }

      // Update last_sync_at
      await supabaseServiceClient
        .from('user_integrations')
        .update({ last_sync_at: new Date().toISOString() })
        .eq('id', integration.id)

      const response: APIResponse = {
        success: true,
        data: {
          workouts_found: workouts.length,
          workouts_imported: imported.length,
          imported_ids: imported
        },
        message: `Synced ${imported.length} workout(s) from Whoop`
      }
      res.json(response)
    } catch (error: any) {
      console.error('Error syncing Whoop:', error)
      res.status(500).json({ success: false, error: { error: 'Internal server error', message: error.message } })
    }
  }
}

// Helper to format whoop_daily_data row into API response shape
function formatWhoopResponse(row: any) {
  return {
    recovery: {
      score: row.recovery_score,
      zone: row.recovery_zone,
      hrv: row.hrv,
      resting_hr: row.resting_hr
    },
    sleep: {
      performance: row.sleep_performance,
      duration_minutes: row.sleep_duration_minutes,
      efficiency: row.sleep_efficiency,
      stages: row.sleep_stages,
      respiratory_rate: row.respiratory_rate,
      skin_temp_delta: row.skin_temp_delta
    },
    strain: {
      score: row.strain_score
    },
    fetched_at: row.fetched_at
  }
}
