// Integration services index
import { WhoopService } from './whoop.js'
import { StravaService } from './strava.js'
import { supabaseServiceClient } from '../supabase.js'

export { WhoopService } from './whoop.js'
export { StravaService } from './strava.js'
export { SupabaseEdgeFunctions } from './supabaseEdgeFunctions.js'

// Apple Health integration would be handled client-side (iOS app)
// but we can provide utilities for processing the data sent from the app

export interface AppleHealthData {
  workouts: Array<{
    id: string
    workout_type: string
    start_date: string
    end_date: string
    duration: number
    calories_burned?: number
    average_heart_rate?: number
    max_heart_rate?: number
    distance?: number
  }>
  heart_rate_samples?: Array<{
    date: string
    value: number
    source: string
  }>
  activity_summary?: Array<{
    date: string
    active_energy: number
    exercise_minutes: number
    stand_hours: number
  }>
}

export class AppleHealthService {
  // Convert Apple Health workout types to our internal types
  static mapWorkoutType(appleType: string): string {
    const typeMapping: Record<string, string> = {
      'HKWorkoutActivityTypeRunning': 'cardio',
      'HKWorkoutActivityTypeCycling': 'cardio',
      'HKWorkoutActivityTypeSwimming': 'cardio',
      'HKWorkoutActivityTypeFunctionalStrengthTraining': 'strength',
      'HKWorkoutActivityTypeTraditionalStrengthTraining': 'strength',
      'HKWorkoutActivityTypeYoga': 'recovery',
      'HKWorkoutActivityTypeCrossTraining': 'cross_training',
      'HKWorkoutActivityTypeSoccer': 'skills',
      'HKWorkoutActivityTypeBasketball': 'skills',
      'HKWorkoutActivityTypeTennis': 'skills',
      'HKWorkoutActivityTypeGolf': 'skills',
      'HKWorkoutActivityTypeHiking': 'cardio',
      'HKWorkoutActivityTypeWalking': 'recovery',
      'HKWorkoutActivityTypePreparationAndRecovery': 'recovery'
    }

    return typeMapping[appleType] || 'cardio'
  }

  // Convert Apple Health workout to our workout reflection format
  static convertToWorkoutReflection(workout: any, userId: string): any {
    const date = new Date(workout.start_date).toISOString().split('T')[0]
    
    return {
      user_id: userId,
      date,
      workout_type: this.mapWorkoutType(workout.workout_type),
      duration_minutes: Math.round(workout.duration / 60),
      calories_burned: workout.calories_burned,
      average_hr: workout.average_heart_rate,
      max_hr: workout.max_heart_rate,
      apple_workout_id: workout.id,
      created_at: new Date().toISOString()
    }
  }

  // Process batch of Apple Health data
  static processBatchData(data: AppleHealthData, userId: string): {
    workout_reflections: any[]
    activity_summaries: any[]
  } {
    const workout_reflections = data.workouts.map(workout => 
      this.convertToWorkoutReflection(workout, userId)
    )

    const activity_summaries = data.activity_summary || []

    return {
      workout_reflections,
      activity_summaries
    }
  }

  // Validate Apple Health data structure
  static validateHealthData(data: any): data is AppleHealthData {
    if (!data || typeof data !== 'object') return false
    
    if (!Array.isArray(data.workouts)) return false
    
    // Validate each workout has required fields
    for (const workout of data.workouts) {
      if (!workout.id || !workout.start_date || !workout.duration) {
        return false
      }
    }

    return true
  }
}

// Integration manager to coordinate all fitness integrations
export class IntegrationManager {
  private whoopService: WhoopService
  private stravaService: StravaService

  constructor() {
    this.whoopService = new WhoopService()
    this.stravaService = new StravaService()
  }

  // Get all available integrations for a user (real DB query)
  async getUserIntegrations(userId: string): Promise<{
    whoop: { connected: boolean; last_sync?: string }
    strava: { connected: boolean; last_sync?: string }
    apple_health: { connected: boolean; last_sync?: string }
  }> {
    const result: Record<string, { connected: boolean; last_sync?: string }> = {
      whoop: { connected: false },
      strava: { connected: false },
      apple_health: { connected: false }
    }

    const { data } = await supabaseServiceClient
      .from('user_integrations')
      .select('service, last_sync_at')
      .eq('user_id', userId)

    for (const row of data || []) {
      result[row.service] = {
        connected: true,
        last_sync: row.last_sync_at ?? undefined
      }
    }

    return result as any
  }

  // Sync data from all connected integrations
  async syncAllIntegrations(userId: string, date?: string): Promise<{
    whoop_data?: any
    strava_activities?: any[]
    apple_health_data?: any
    errors: string[]
  }> {
    const errors: string[] = []
    const results: any = {}
    const targetDate = date || new Date().toISOString().split('T')[0]!

    // Get user integration tokens from database
    const { data: integrations } = await supabaseServiceClient
      .from('user_integrations')
      .select('*')
      .eq('user_id', userId)

    const whoopIntegration = integrations?.find(i => i.service === 'whoop')

    // Sync Whoop data
    if (whoopIntegration?.access_token) {
      try {
        results.whoop_data = await this.whoopService.getCombinedData(
          whoopIntegration.access_token!,
          targetDate
        )
      } catch (error: any) {
        errors.push(`Whoop sync failed: ${error.message}`)
      }
    }

    // Strava sync placeholder
    const stravaIntegration = integrations?.find(i => i.service === 'strava')
    if (stravaIntegration?.access_token) {
      try {
        // Strava sync would go here when implemented
      } catch (error: any) {
        errors.push(`Strava sync failed: ${error.message}`)
      }
    }

    return { ...results, errors }
  }

  // Handle webhook events from integrations
  async handleWebhookEvent(source: 'whoop' | 'strava', event: any): Promise<void> {
    switch (source) {
      case 'strava':
        const processedEvent = this.stravaService.processWebhookEvent(event)
        if (processedEvent && processedEvent.aspect_type === 'create' && processedEvent.object_type === 'activity') {
          // Trigger sync for the user who created the activity
          // await this.syncUserStravaData(processedEvent.owner_id, processedEvent.object_id)
        }
        break
      
      case 'whoop':
        // Handle Whoop webhook events
        // Implementation would depend on Whoop's webhook structure
        break
    }
  }
}
