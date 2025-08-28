import type { StravaActivity } from '../../types/api.js';
export declare class StravaService {
    private readonly baseUrl;
    private readonly authUrl;
    private readonly clientId;
    private readonly clientSecret;
    constructor();
    getAuthorizationUrl(redirectUri: string, state: string): string;
    exchangeCodeForTokens(code: string): Promise<{
        access_token: string;
        refresh_token: string;
        expires_in: number;
        expires_at: number;
        athlete: any;
    }>;
    refreshAccessToken(refreshToken: string): Promise<{
        access_token: string;
        refresh_token: string;
        expires_in: number;
        expires_at: number;
    }>;
    getAthleteProfile(accessToken: string): Promise<any>;
    getActivities(accessToken: string, before?: Date, after?: Date, page?: number, perPage?: number): Promise<StravaActivity[]>;
    getActivitiesForDate(accessToken: string, date: string): Promise<StravaActivity[]>;
    getActivityById(accessToken: string, activityId: string): Promise<any>;
    createWebhookSubscription(callbackUrl: string, verifyToken: string): Promise<{
        id: number;
        callback_url: string;
        created_at: string;
        updated_at: string;
    }>;
    deleteWebhookSubscription(subscriptionId: number): Promise<void>;
    getWebhookSubscriptions(): Promise<any[]>;
    validateWebhookChallenge(mode: string, token: string, challenge: string, verifyToken: string): string | null;
    processWebhookEvent(event: any): {
        aspect_type: 'create' | 'update' | 'delete';
        object_type: 'activity' | 'athlete';
        object_id: number;
        owner_id: number;
        subscription_id: number;
        event_time: number;
    } | null;
    mapActivityType(stravaType: string): string;
    convertToWorkoutReflection(activity: StravaActivity, userId: string): any;
}
//# sourceMappingURL=strava.d.ts.map