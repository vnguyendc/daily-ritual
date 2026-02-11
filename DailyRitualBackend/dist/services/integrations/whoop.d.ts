import type { WhoopData } from '../../types/api.js';
export declare class WhoopService {
    private readonly baseUrl;
    private readonly clientId;
    private readonly clientSecret;
    constructor();
    getAuthorizationUrl(redirectUri: string, state: string): string;
    exchangeCodeForTokens(code: string, redirectUri: string): Promise<{
        access_token: string;
        refresh_token: string;
        expires_in: number;
    }>;
    refreshAccessToken(refreshToken: string): Promise<{
        access_token: string;
        refresh_token: string;
        expires_in: number;
    }>;
    getUserProfile(accessToken: string): Promise<any>;
    getRecoveryData(accessToken: string, date: string): Promise<WhoopData | null>;
    getStrainData(accessToken: string, date: string): Promise<{
        strain_score: number;
    } | null>;
    getCombinedData(accessToken: string, date: string): Promise<WhoopData | null>;
    getWorkouts(accessToken: string, startDate: string, endDate: string): Promise<any>;
    setupWebhook(accessToken: string, webhookUrl: string): Promise<any>;
    validateWebhookSignature(payload: string, signature: string, secret: string): boolean;
    importWhoopWorkout(userId: string, workout: any): Promise<string | null>;
}
//# sourceMappingURL=whoop.d.ts.map