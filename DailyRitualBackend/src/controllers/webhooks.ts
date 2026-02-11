// Webhooks Controller — handles incoming webhooks from integrations
import { Request, Response } from 'express'
import { supabaseServiceClient } from '../services/supabase.js'
import { WhoopService } from '../services/integrations/whoop.js'
import type { APIResponse } from '../types/api.js'

const whoopService = new WhoopService()

export class WebhooksController {

  // Handle incoming Whoop webhook events
  static async handleWhoopWebhook(req: Request, res: Response) {
    try {
      // Validate webhook signature
      const signature = req.headers['x-whoop-signature'] as string
      const webhookSecret = process.env.WHOOP_WEBHOOK_SECRET

      if (webhookSecret && signature) {
        const payload = JSON.stringify(req.body)
        const isValid = whoopService.validateWebhookSignature(payload, signature, webhookSecret)
        if (!isValid) {
          return res.status(401).json({ error: 'Invalid webhook signature' })
        }
      }

      const event = req.body

      if (!event || !event.type) {
        return res.status(400).json({ error: 'Invalid webhook payload' })
      }

      console.log(`Whoop webhook received: ${event.type}`, JSON.stringify(event))

      switch (event.type) {
        case 'workout.updated':
        case 'workout.created': {
          await handleWhoopWorkoutEvent(event)
          break
        }
        case 'recovery.updated': {
          await handleWhoopRecoveryEvent(event)
          break
        }
        default:
          console.log(`Unhandled Whoop webhook event type: ${event.type}`)
      }

      // Always acknowledge quickly
      res.status(200).json({ received: true })
    } catch (error: any) {
      console.error('Error handling Whoop webhook:', error)
      // Still return 200 to prevent webhook retries
      res.status(200).json({ received: true, error: error.message })
    }
  }
}

// Process a Whoop workout event
async function handleWhoopWorkoutEvent(event: any) {
  try {
    const externalUserId = String(event.user_id)

    // Look up our user by external Whoop user ID
    const { data: integration } = await supabaseServiceClient
      .from('user_integrations')
      .select('user_id, access_token, refresh_token, token_expires_at')
      .eq('service', 'whoop')
      .eq('external_user_id', externalUserId)
      .single()

    if (!integration) {
      console.log(`No integration found for Whoop user ${externalUserId}`)
      return
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
        .eq('user_id', integration.user_id!)
        .eq('service', 'whoop')
    }

    // Fetch the workout details from Whoop
    const workoutId = event.id || event.workout_id
    if (!workoutId) return

    // For workout events, get workout data for today and import
    const today = new Date().toISOString().split('T')[0]!
    const workouts = await whoopService.getWorkouts(accessToken, today, today)

    for (const workout of workouts) {
      await whoopService.importWhoopWorkout(integration.user_id!, workout)
    }
  } catch (error) {
    console.error('Error processing Whoop workout event:', error)
  }
}

// Process a Whoop recovery event
async function handleWhoopRecoveryEvent(event: any) {
  try {
    const externalUserId = String(event.user_id)

    const { data: integration } = await supabaseServiceClient
      .from('user_integrations')
      .select('user_id, access_token, refresh_token, token_expires_at')
      .eq('service', 'whoop')
      .eq('external_user_id', externalUserId)
      .single()

    if (!integration) return

    // Refresh token if expired
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
        .eq('user_id', integration.user_id!)
        .eq('service', 'whoop')
    }

    // Fetch recovery data
    const today = new Date().toISOString().split('T')[0]!
    const recoveryData = await whoopService.getRecoveryData(accessToken, today)

    if (!recoveryData) return

    // Update the latest workout reflection for today with recovery data
    const { data: latestReflection } = await supabaseServiceClient
      .from('workout_reflections')
      .select('id')
      .eq('user_id', integration.user_id!)
      .eq('date', today)
      .order('created_at', { ascending: false })
      .limit(1)
      .single()

    if (latestReflection) {
      await supabaseServiceClient
        .from('workout_reflections')
        .update({
          recovery_score: recoveryData.recovery_score,
          sleep_performance: recoveryData.sleep_performance,
          hrv: recoveryData.hrv,
          resting_hr: recoveryData.resting_hr,
          updated_at: new Date().toISOString()
        })
        .eq('id', latestReflection.id)
    }
  } catch (error) {
    console.error('Error processing Whoop recovery event:', error)
  }
}
