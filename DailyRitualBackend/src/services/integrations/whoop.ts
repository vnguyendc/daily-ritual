// Whoop API integration service
import type { WhoopData } from '../../types/api.js'
import type { TrainingActivityType } from '../../types/database.js'
import { supabaseServiceClient } from '../supabase.js'

// Whoop sport_id → TrainingActivityType mapping
const WHOOP_SPORT_MAP = new Map<number, string>([
  [-1, 'other'],
  [0, 'strength_training'],
  [1, 'running'],
  [2, 'cycling'],
  [3, 'other'],           // Generic Sport
  [4, 'other'],           // Miscellaneous
  [5, 'running'],         // Treadmill
  [6, 'rowing'],
  [7, 'swimming'],
  [8, 'crossfit'],
  [9, 'yoga'],
  [10, 'basketball'],
  [11, 'soccer'],
  [12, 'tennis'],
  [13, 'hiking'],
  [14, 'golf'],
  [15, 'skiing'],
  [16, 'snowboarding'],
  [17, 'boxing'],
  [18, 'mma'],
  [19, 'cycling'],        // Spin
  [20, 'pilates'],
  [21, 'stretching'],
  [22, 'meditation'],
  [23, 'football'],
  [24, 'baseball'],
  [25, 'volleyball'],
  [26, 'hockey'],
  [27, 'lacrosse'],
  [28, 'rugby'],
  [29, 'surfing'],
  [30, 'rock_climbing'],
  [31, 'walking'],
  [32, 'elliptical'],
  [33, 'stair_climbing'],
  [34, 'jump_rope'],
  [35, 'skateboarding'],
  [36, 'wrestling'],
  [37, 'jiu_jitsu'],
  [38, 'muay_thai'],
  [39, 'kickboxing'],
  [40, 'taekwondo'],
  [41, 'karate'],
  [42, 'badminton'],
  [43, 'squash'],
  [44, 'racquetball'],
  [45, 'pickleball'],
  [46, 'weightlifting'],
  [47, 'calisthenics'],
  [48, 'functional_fitness'],
  [49, 'trail_running'],
  [50, 'bouldering']
])

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

  // Get detailed sleep data for a specific date
  async getSleepData(accessToken: string, date: string): Promise<{
    performance: number
    duration_minutes: number
    efficiency: number
    stages: { awake: number; light: number; rem: number; deep: number }
    respiratory_rate: number
    skin_temp_delta: number
  } | null> {
    const startDate = `${date}T00:00:00.000Z`
    const endDate = `${date}T23:59:59.999Z`

    const response = await fetch(`${this.baseUrl}/v1/activity/sleep?start=${startDate}&end=${endDate}`, {
      headers: { 'Authorization': `Bearer ${accessToken}` }
    })

    if (!response.ok) {
      if (response.status === 404) return null
      throw new Error(`Whoop sleep fetch failed: ${response.status}`)
    }

    const data = await response.json()
    if (!data.records || data.records.length === 0) return null

    const sleep = data.records[0]
    const score = sleep.score || {}

    return {
      performance: score.sleep_performance_percentage || 0,
      duration_minutes: Math.round((score.total_sleep_duration || 0) / 60000),
      efficiency: score.sleep_efficiency_percentage || 0,
      stages: {
        awake: Math.round((score.stage_summary?.total_awake_time || 0) / 60000),
        light: Math.round((score.stage_summary?.total_light_sleep_time || 0) / 60000),
        rem: Math.round((score.stage_summary?.total_rem_sleep_time || 0) / 60000),
        deep: Math.round((score.stage_summary?.total_slow_wave_sleep_time || 0) / 60000)
      },
      respiratory_rate: score.respiratory_rate || 0,
      skin_temp_delta: score.skin_temp_celsius_delta || 0
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

  // Import a Whoop workout: creates training_plan + draft workout_reflection
  // Returns the workout_reflection id if created, null if skipped (duplicate)
  async importWhoopWorkout(userId: string, workout: any): Promise<string | null> {
    const whoopActivityId = String(workout.id)

    // Dedup check — skip if this Whoop workout was already imported
    const { data: existing } = await supabaseServiceClient
      .from('workout_reflections')
      .select('id')
      .eq('user_id', userId)
      .eq('whoop_activity_id', whoopActivityId)
      .limit(1)

    if (existing && existing.length > 0) {
      return null // Already imported
    }

    // Map Whoop sport to TrainingActivityType
    const sportId = workout.sport_id ?? -1
    const activityType: TrainingActivityType = (WHOOP_SPORT_MAP.get(sportId) || 'other') as TrainingActivityType

    // Parse dates & duration
    const startTime = workout.start ? new Date(workout.start) : new Date()
    const endTime = workout.end ? new Date(workout.end) : startTime
    const durationMinutes = Math.round((endTime.getTime() - startTime.getTime()) / 60000)
    const dateStr = startTime.toISOString().split('T')[0]!
    const timeStr = startTime.toISOString().split('T')[1]?.substring(0, 8) || '00:00:00'

    // 1. Create a training_plan entry
    // Get next sequence for this date
    const { data: existingPlans } = await supabaseServiceClient
      .from('training_plans')
      .select('sequence')
      .eq('user_id', userId)
      .eq('date', dateStr)
      .order('sequence', { ascending: false })
      .limit(1)

    const planSequence = existingPlans?.[0]?.sequence ? existingPlans[0].sequence + 1 : 1

    await supabaseServiceClient
      .from('training_plans')
      .insert({
        user_id: userId,
        date: dateStr,
        sequence: planSequence,
        type: activityType,
        start_time: timeStr,
        duration_minutes: durationMinutes > 0 ? durationMinutes : null,
        notes: 'Imported from Whoop'
      })

    // 2. Create a draft workout_reflection
    const { data: existingReflections } = await supabaseServiceClient
      .from('workout_reflections')
      .select('workout_sequence')
      .eq('user_id', userId)
      .eq('date', dateStr)
      .order('workout_sequence', { ascending: false })
      .limit(1)

    const reflectionSequence = existingReflections?.[0]?.workout_sequence
      ? existingReflections[0].workout_sequence + 1
      : 1

    const { data: reflection, error } = await supabaseServiceClient
      .from('workout_reflections')
      .insert({
        user_id: userId,
        date: dateStr,
        workout_sequence: reflectionSequence,
        whoop_activity_id: whoopActivityId,
        workout_type: activityType,
        duration_minutes: durationMinutes > 0 ? durationMinutes : null,
        calories_burned: workout.score?.kilojoule ? Math.round(workout.score.kilojoule * 0.239006) : null,
        average_hr: workout.score?.average_heart_rate ? Math.round(workout.score.average_heart_rate) : null,
        max_hr: workout.score?.max_heart_rate ? Math.round(workout.score.max_heart_rate) : null,
        strain_score: workout.score?.strain ?? null
        // training_feeling, what_went_well, what_to_improve left NULL for user to fill
      })
      .select('id')
      .single()

    if (error) {
      console.error('Error importing Whoop workout:', error)
      return null
    }

    return reflection?.id ?? null
  }
}
