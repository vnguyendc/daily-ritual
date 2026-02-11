import { WhoopService } from './whoop.js';
import { StravaService } from './strava.js';
import { supabaseServiceClient } from '../supabase.js';
export { WhoopService } from './whoop.js';
export { StravaService } from './strava.js';
export { SupabaseEdgeFunctions } from './supabaseEdgeFunctions.js';
export class AppleHealthService {
    static mapWorkoutType(appleType) {
        const typeMapping = {
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
        };
        return typeMapping[appleType] || 'cardio';
    }
    static convertToWorkoutReflection(workout, userId) {
        const date = new Date(workout.start_date).toISOString().split('T')[0];
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
        };
    }
    static processBatchData(data, userId) {
        const workout_reflections = data.workouts.map(workout => this.convertToWorkoutReflection(workout, userId));
        const activity_summaries = data.activity_summary || [];
        return {
            workout_reflections,
            activity_summaries
        };
    }
    static validateHealthData(data) {
        if (!data || typeof data !== 'object')
            return false;
        if (!Array.isArray(data.workouts))
            return false;
        for (const workout of data.workouts) {
            if (!workout.id || !workout.start_date || !workout.duration) {
                return false;
            }
        }
        return true;
    }
}
export class IntegrationManager {
    whoopService;
    stravaService;
    constructor() {
        this.whoopService = new WhoopService();
        this.stravaService = new StravaService();
    }
    async getUserIntegrations(userId) {
        const result = {
            whoop: { connected: false },
            strava: { connected: false },
            apple_health: { connected: false }
        };
        const { data } = await supabaseServiceClient
            .from('user_integrations')
            .select('service, last_sync_at')
            .eq('user_id', userId);
        for (const row of data || []) {
            result[row.service] = {
                connected: true,
                last_sync: row.last_sync_at ?? undefined
            };
        }
        return result;
    }
    async syncAllIntegrations(userId, date) {
        const errors = [];
        const results = {};
        const targetDate = date || new Date().toISOString().split('T')[0];
        const { data: integrations } = await supabaseServiceClient
            .from('user_integrations')
            .select('*')
            .eq('user_id', userId);
        const whoopIntegration = integrations?.find(i => i.service === 'whoop');
        if (whoopIntegration?.access_token) {
            try {
                results.whoop_data = await this.whoopService.getCombinedData(whoopIntegration.access_token, targetDate);
            }
            catch (error) {
                errors.push(`Whoop sync failed: ${error.message}`);
            }
        }
        const stravaIntegration = integrations?.find(i => i.service === 'strava');
        if (stravaIntegration?.access_token) {
            try {
            }
            catch (error) {
                errors.push(`Strava sync failed: ${error.message}`);
            }
        }
        return { ...results, errors };
    }
    async handleWebhookEvent(source, event) {
        switch (source) {
            case 'strava':
                const processedEvent = this.stravaService.processWebhookEvent(event);
                if (processedEvent && processedEvent.aspect_type === 'create' && processedEvent.object_type === 'activity') {
                }
                break;
            case 'whoop':
                break;
        }
    }
}
//# sourceMappingURL=index.js.map