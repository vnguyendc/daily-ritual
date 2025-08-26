// Whoop API integration service
import type { WhoopData } from '../../types/api.js'

export class WhoopService {
  private readonly baseUrl = 'https://api.prod.whoop.com/developer'
  private readonly clientId: string
  private readonly clientSecret: string

  constructor() {
    this.clientId = process.env.WHOOP_CLIENT_ID || ''
    this.clientSecret = process.env.WHOOP_CLIENT_SECRET || ''
    
    if (!this.clientId || !this.clientSecret) {
      console.warn('Whoop credentials not configured')
    }
  }

  // OAuth flow - get authorization URL
  getAuthorizationUrl(redirectUri: string, state: string): string {
    const params = new URLSearchParams({
      response_type: 'code',
      client_id: this.clientId,
      redirect_uri: redirectUri,
      scope: 'read:recovery read:workout read:sleep',
      state
    })

    return `${this.baseUrl}/oauth/auth?${params.toString()}`
  }

  // Exchange authorization code for access token
  async exchangeCodeForTokens(code: string, redirectUri: string): Promise<{
    access_token: string
    refresh_token: string
    expires_in: number
  }> {
    const response = await fetch(`${this.baseUrl}/oauth/token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        client_id: this.clientId,
        client_secret: this.clientSecret,
        code,
        redirect_uri: redirectUri
      })
    })

    if (!response.ok) {
      throw new Error(`Whoop token exchange failed: ${response.status}`)
    }

    return await response.json()
  }

  // Refresh access token
  async refreshAccessToken(refreshToken: string): Promise<{
    access_token: string
    refresh_token: string
    expires_in: number
  }> {
    const response = await fetch(`${this.baseUrl}/oauth/token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'refresh_token',
        client_id: this.clientId,
        client_secret: this.clientSecret,
        refresh_token: refreshToken
      })
    })

    if (!response.ok) {
      throw new Error(`Whoop token refresh failed: ${response.status}`)
    }

    return await response.json()
  }

  // Get user profile
  async getUserProfile(accessToken: string) {
    const response = await fetch(`${this.baseUrl}/v1/user/profile/basic`, {
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    })

    if (!response.ok) {
      throw new Error(`Whoop profile fetch failed: ${response.status}`)
    }

    return await response.json()
  }

  // Get recovery data for a specific date
  async getRecoveryData(accessToken: string, date: string): Promise<WhoopData | null> {
    const startDate = `${date}T00:00:00.000Z`
    const endDate = `${date}T23:59:59.999Z`

    const response = await fetch(`${this.baseUrl}/v1/recovery?start=${startDate}&end=${endDate}`, {
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    })

    if (!response.ok) {
      if (response.status === 404) return null
      throw new Error(`Whoop recovery fetch failed: ${response.status}`)
    }

    const data = await response.json()
    
    if (!data.records || data.records.length === 0) {
      return null
    }

    const recovery = data.records[0]
    
    return {
      recovery_score: recovery.score?.recovery_score || 0,
      strain_score: 0, // Will be filled by strain data
      sleep_performance: recovery.score?.sleep_performance_percentage || 0,
      hrv: recovery.score?.hrv_rmssd_milli || 0,
      resting_hr: recovery.score?.resting_heart_rate || 0
    }
  }

  // Get strain data for a specific date
  async getStrainData(accessToken: string, date: string): Promise<{ strain_score: number } | null> {
    const startDate = `${date}T00:00:00.000Z`
    const endDate = `${date}T23:59:59.999Z`

    const response = await fetch(`${this.baseUrl}/v1/cycle?start=${startDate}&end=${endDate}`, {
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    })

    if (!response.ok) {
      if (response.status === 404) return null
      throw new Error(`Whoop strain fetch failed: ${response.status}`)
    }

    const data = await response.json()
    
    if (!data.records || data.records.length === 0) {
      return null
    }

    const cycle = data.records[0]
    
    return {
      strain_score: cycle.score?.strain || 0
    }
  }

  // Get combined recovery and strain data
  async getCombinedData(accessToken: string, date: string): Promise<WhoopData | null> {
    try {
      const [recoveryData, strainData] = await Promise.all([
        this.getRecoveryData(accessToken, date),
        this.getStrainData(accessToken, date)
      ])

      if (!recoveryData && !strainData) {
        return null
      }

      return {
        recovery_score: recoveryData?.recovery_score || 0,
        strain_score: strainData?.strain_score || 0,
        sleep_performance: recoveryData?.sleep_performance || 0,
        hrv: recoveryData?.hrv || 0,
        resting_hr: recoveryData?.resting_hr || 0
      }
    } catch (error) {
      console.error('Error fetching Whoop data:', error)
      return null
    }
  }

  // Get workouts for a date range
  async getWorkouts(accessToken: string, startDate: string, endDate: string) {
    const response = await fetch(`${this.baseUrl}/v1/workout?start=${startDate}T00:00:00.000Z&end=${endDate}T23:59:59.999Z`, {
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    })

    if (!response.ok) {
      throw new Error(`Whoop workouts fetch failed: ${response.status}`)
    }

    const data = await response.json()
    return data.records || []
  }

  // Setup webhook for real-time updates
  async setupWebhook(accessToken: string, webhookUrl: string) {
    const response = await fetch(`${this.baseUrl}/v1/webhook`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        url: webhookUrl,
        enabled: true
      })
    })

    if (!response.ok) {
      throw new Error(`Whoop webhook setup failed: ${response.status}`)
    }

    return await response.json()
  }

  // Validate webhook signature
  validateWebhookSignature(payload: string, signature: string, secret: string): boolean {
    const crypto = require('crypto')
    const expectedSignature = crypto
      .createHmac('sha256', secret)
      .update(payload)
      .digest('hex')
    
    return crypto.timingSafeEqual(
      Buffer.from(signature, 'hex'),
      Buffer.from(expectedSignature, 'hex')
    )
  }
}
