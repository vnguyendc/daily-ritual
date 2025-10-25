export { WhoopService } from './whoop.js';
export { StravaService } from './strava.js';
export { SupabaseEdgeFunctions } from './supabaseEdgeFunctions.js';
export interface AppleHealthData {
    workouts: Array<{
        id: string;
        workout_type: string;
        start_date: string;
        end_date: string;
        duration: number;
        calories_burned?: number;
        average_heart_rate?: number;
        max_heart_rate?: number;
        distance?: number;
    }>;
    heart_rate_samples?: Array<{
        date: string;
        value: number;
        source: string;
    }>;
    activity_summary?: Array<{
        date: string;
        active_energy: number;
        exercise_minutes: number;
        stand_hours: number;
    }>;
}
export declare class AppleHealthService {
    static mapWorkoutType(appleType: string): string;
    static convertToWorkoutReflection(workout: any, userId: string): any;
    static processBatchData(data: AppleHealthData, userId: string): {
        workout_reflections: any[];
        activity_summaries: any[];
    };
    static validateHealthData(data: any): data is AppleHealthData;
}
export declare class IntegrationManager {
    private whoopService;
    private stravaService;
    constructor();
    getUserIntegrations(userId: string): Promise<{
        whoop: {
            connected: boolean;
            last_sync?: string;
        };
        strava: {
            connected: boolean;
            last_sync?: string;
        };
        apple_health: {
            connected: boolean;
            last_sync?: string;
        };
    }>;
    syncAllIntegrations(userId: string, date?: string): Promise<{
        whoop_data?: any;
        strava_activities?: any[];
        apple_health_data?: any;
        errors: string[];
    }>;
    handleWebhookEvent(source: 'whoop' | 'strava', event: any): Promise<void>;
}
//# sourceMappingURL=index.d.ts.map