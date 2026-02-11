import { supabaseServiceClient } from '../supabase.js';
const WHOOP_SPORT_MAP = new Map([
    [-1, 'other'],
    [0, 'strength_training'],
    [1, 'running'],
    [2, 'cycling'],
    [3, 'other'],
    [4, 'other'],
    [5, 'running'],
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
    [19, 'cycling'],
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
]);
export class WhoopService {
    baseUrl = 'https://api.prod.whoop.com/developer';
    clientId;
    clientSecret;
    constructor() {
        this.clientId = process.env.WHOOP_CLIENT_ID || '';
        this.clientSecret = process.env.WHOOP_CLIENT_SECRET || '';
        if (!this.clientId || !this.clientSecret) {
            console.warn('Whoop credentials not configured');
        }
    }
    getAuthorizationUrl(redirectUri, state) {
        const params = new URLSearchParams({
            response_type: 'code',
            client_id: this.clientId,
            redirect_uri: redirectUri,
            scope: 'read:recovery read:workout read:sleep',
            state
        });
        return `${this.baseUrl}/oauth/auth?${params.toString()}`;
    }
    async exchangeCodeForTokens(code, redirectUri) {
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
        });
        if (!response.ok) {
            throw new Error(`Whoop token exchange failed: ${response.status}`);
        }
        return await response.json();
    }
    async refreshAccessToken(refreshToken) {
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
        });
        if (!response.ok) {
            throw new Error(`Whoop token refresh failed: ${response.status}`);
        }
        return await response.json();
    }
    async getUserProfile(accessToken) {
        const response = await fetch(`${this.baseUrl}/v1/user/profile/basic`, {
            headers: {
                'Authorization': `Bearer ${accessToken}`
            }
        });
        if (!response.ok) {
            throw new Error(`Whoop profile fetch failed: ${response.status}`);
        }
        return await response.json();
    }
    async getRecoveryData(accessToken, date) {
        const startDate = `${date}T00:00:00.000Z`;
        const endDate = `${date}T23:59:59.999Z`;
        const response = await fetch(`${this.baseUrl}/v1/recovery?start=${startDate}&end=${endDate}`, {
            headers: {
                'Authorization': `Bearer ${accessToken}`
            }
        });
        if (!response.ok) {
            if (response.status === 404)
                return null;
            throw new Error(`Whoop recovery fetch failed: ${response.status}`);
        }
        const data = await response.json();
        if (!data.records || data.records.length === 0) {
            return null;
        }
        const recovery = data.records[0];
        return {
            recovery_score: recovery.score?.recovery_score || 0,
            strain_score: 0,
            sleep_performance: recovery.score?.sleep_performance_percentage || 0,
            hrv: recovery.score?.hrv_rmssd_milli || 0,
            resting_hr: recovery.score?.resting_heart_rate || 0
        };
    }
    async getStrainData(accessToken, date) {
        const startDate = `${date}T00:00:00.000Z`;
        const endDate = `${date}T23:59:59.999Z`;
        const response = await fetch(`${this.baseUrl}/v1/cycle?start=${startDate}&end=${endDate}`, {
            headers: {
                'Authorization': `Bearer ${accessToken}`
            }
        });
        if (!response.ok) {
            if (response.status === 404)
                return null;
            throw new Error(`Whoop strain fetch failed: ${response.status}`);
        }
        const data = await response.json();
        if (!data.records || data.records.length === 0) {
            return null;
        }
        const cycle = data.records[0];
        return {
            strain_score: cycle.score?.strain || 0
        };
    }
    async getCombinedData(accessToken, date) {
        try {
            const [recoveryData, strainData] = await Promise.all([
                this.getRecoveryData(accessToken, date),
                this.getStrainData(accessToken, date)
            ]);
            if (!recoveryData && !strainData) {
                return null;
            }
            return {
                recovery_score: recoveryData?.recovery_score || 0,
                strain_score: strainData?.strain_score || 0,
                sleep_performance: recoveryData?.sleep_performance || 0,
                hrv: recoveryData?.hrv || 0,
                resting_hr: recoveryData?.resting_hr || 0
            };
        }
        catch (error) {
            console.error('Error fetching Whoop data:', error);
            return null;
        }
    }
    async getWorkouts(accessToken, startDate, endDate) {
        const response = await fetch(`${this.baseUrl}/v1/workout?start=${startDate}T00:00:00.000Z&end=${endDate}T23:59:59.999Z`, {
            headers: {
                'Authorization': `Bearer ${accessToken}`
            }
        });
        if (!response.ok) {
            throw new Error(`Whoop workouts fetch failed: ${response.status}`);
        }
        const data = await response.json();
        return data.records || [];
    }
    async setupWebhook(accessToken, webhookUrl) {
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
        });
        if (!response.ok) {
            throw new Error(`Whoop webhook setup failed: ${response.status}`);
        }
        return await response.json();
    }
    validateWebhookSignature(payload, signature, secret) {
        const crypto = require('crypto');
        const expectedSignature = crypto
            .createHmac('sha256', secret)
            .update(payload)
            .digest('hex');
        return crypto.timingSafeEqual(Buffer.from(signature, 'hex'), Buffer.from(expectedSignature, 'hex'));
    }
    async importWhoopWorkout(userId, workout) {
        const whoopActivityId = String(workout.id);
        const { data: existing } = await supabaseServiceClient
            .from('workout_reflections')
            .select('id')
            .eq('user_id', userId)
            .eq('whoop_activity_id', whoopActivityId)
            .limit(1);
        if (existing && existing.length > 0) {
            return null;
        }
        const sportId = workout.sport_id ?? -1;
        const activityType = (WHOOP_SPORT_MAP.get(sportId) || 'other');
        const startTime = workout.start ? new Date(workout.start) : new Date();
        const endTime = workout.end ? new Date(workout.end) : startTime;
        const durationMinutes = Math.round((endTime.getTime() - startTime.getTime()) / 60000);
        const dateStr = startTime.toISOString().split('T')[0];
        const timeStr = startTime.toISOString().split('T')[1]?.substring(0, 8) || '00:00:00';
        const { data: existingPlans } = await supabaseServiceClient
            .from('training_plans')
            .select('sequence')
            .eq('user_id', userId)
            .eq('date', dateStr)
            .order('sequence', { ascending: false })
            .limit(1);
        const planSequence = existingPlans?.[0]?.sequence ? existingPlans[0].sequence + 1 : 1;
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
        });
        const { data: existingReflections } = await supabaseServiceClient
            .from('workout_reflections')
            .select('workout_sequence')
            .eq('user_id', userId)
            .eq('date', dateStr)
            .order('workout_sequence', { ascending: false })
            .limit(1);
        const reflectionSequence = existingReflections?.[0]?.workout_sequence
            ? existingReflections[0].workout_sequence + 1
            : 1;
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
        })
            .select('id')
            .single();
        if (error) {
            console.error('Error importing Whoop workout:', error);
            return null;
        }
        return reflection?.id ?? null;
    }
}
//# sourceMappingURL=whoop.js.map