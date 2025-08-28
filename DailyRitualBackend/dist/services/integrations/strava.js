export class StravaService {
    baseUrl = 'https://www.strava.com/api/v3';
    authUrl = 'https://www.strava.com/oauth';
    clientId;
    clientSecret;
    constructor() {
        this.clientId = process.env.STRAVA_CLIENT_ID || '';
        this.clientSecret = process.env.STRAVA_CLIENT_SECRET || '';
        if (!this.clientId || !this.clientSecret) {
            console.warn('Strava credentials not configured');
        }
    }
    getAuthorizationUrl(redirectUri, state) {
        const params = new URLSearchParams({
            client_id: this.clientId,
            redirect_uri: redirectUri,
            response_type: 'code',
            approval_prompt: 'auto',
            scope: 'read,activity:read',
            state
        });
        return `${this.authUrl}/authorize?${params.toString()}`;
    }
    async exchangeCodeForTokens(code) {
        const response = await fetch(`${this.authUrl}/token`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                client_id: this.clientId,
                client_secret: this.clientSecret,
                code,
                grant_type: 'authorization_code'
            })
        });
        if (!response.ok) {
            throw new Error(`Strava token exchange failed: ${response.status}`);
        }
        return await response.json();
    }
    async refreshAccessToken(refreshToken) {
        const response = await fetch(`${this.authUrl}/token`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                client_id: this.clientId,
                client_secret: this.clientSecret,
                refresh_token: refreshToken,
                grant_type: 'refresh_token'
            })
        });
        if (!response.ok) {
            throw new Error(`Strava token refresh failed: ${response.status}`);
        }
        return await response.json();
    }
    async getAthleteProfile(accessToken) {
        const response = await fetch(`${this.baseUrl}/athlete`, {
            headers: {
                'Authorization': `Bearer ${accessToken}`
            }
        });
        if (!response.ok) {
            throw new Error(`Strava profile fetch failed: ${response.status}`);
        }
        return await response.json();
    }
    async getActivities(accessToken, before, after, page = 1, perPage = 30) {
        const params = new URLSearchParams({
            page: page.toString(),
            per_page: perPage.toString()
        });
        if (before) {
            params.append('before', Math.floor(before.getTime() / 1000).toString());
        }
        if (after) {
            params.append('after', Math.floor(after.getTime() / 1000).toString());
        }
        const response = await fetch(`${this.baseUrl}/athlete/activities?${params.toString()}`, {
            headers: {
                'Authorization': `Bearer ${accessToken}`
            }
        });
        if (!response.ok) {
            throw new Error(`Strava activities fetch failed: ${response.status}`);
        }
        const activities = await response.json();
        return activities.map((activity) => ({
            id: activity.id.toString(),
            name: activity.name,
            type: activity.sport_type || activity.type,
            start_date: activity.start_date,
            elapsed_time: activity.elapsed_time,
            distance: activity.distance,
            average_heartrate: activity.average_heartrate,
            max_heartrate: activity.max_heartrate,
            calories: activity.calories
        }));
    }
    async getActivitiesForDate(accessToken, date) {
        const startOfDay = new Date(`${date}T00:00:00.000Z`);
        const endOfDay = new Date(`${date}T23:59:59.999Z`);
        return await this.getActivities(accessToken, endOfDay, startOfDay);
    }
    async getActivityById(accessToken, activityId) {
        const response = await fetch(`${this.baseUrl}/activities/${activityId}`, {
            headers: {
                'Authorization': `Bearer ${accessToken}`
            }
        });
        if (!response.ok) {
            if (response.status === 404)
                return null;
            throw new Error(`Strava activity fetch failed: ${response.status}`);
        }
        return await response.json();
    }
    async createWebhookSubscription(callbackUrl, verifyToken) {
        const response = await fetch(`${this.baseUrl}/push_subscriptions`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                client_id: this.clientId,
                client_secret: this.clientSecret,
                callback_url: callbackUrl,
                verify_token: verifyToken
            })
        });
        if (!response.ok) {
            throw new Error(`Strava webhook subscription failed: ${response.status}`);
        }
        return await response.json();
    }
    async deleteWebhookSubscription(subscriptionId) {
        const response = await fetch(`${this.baseUrl}/push_subscriptions/${subscriptionId}`, {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                client_id: this.clientId,
                client_secret: this.clientSecret
            })
        });
        if (!response.ok) {
            throw new Error(`Strava webhook deletion failed: ${response.status}`);
        }
    }
    async getWebhookSubscriptions() {
        const response = await fetch(`${this.baseUrl}/push_subscriptions`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                client_id: this.clientId,
                client_secret: this.clientSecret
            })
        });
        if (!response.ok) {
            throw new Error(`Strava webhook fetch failed: ${response.status}`);
        }
        return await response.json();
    }
    validateWebhookChallenge(mode, token, challenge, verifyToken) {
        if (mode === 'subscribe' && token === verifyToken) {
            return challenge;
        }
        return null;
    }
    processWebhookEvent(event) {
        if (!event.aspect_type || !event.object_type || !event.object_id) {
            return null;
        }
        return {
            aspect_type: event.aspect_type,
            object_type: event.object_type,
            object_id: event.object_id,
            owner_id: event.owner_id,
            subscription_id: event.subscription_id,
            event_time: event.event_time
        };
    }
    mapActivityType(stravaType) {
        const typeMapping = {
            'Run': 'cardio',
            'Ride': 'cardio',
            'Swim': 'cardio',
            'WeightTraining': 'strength',
            'Workout': 'strength',
            'Yoga': 'recovery',
            'Crossfit': 'cross_training',
            'Soccer': 'skills',
            'Basketball': 'skills',
            'Tennis': 'skills',
            'Golf': 'skills',
            'Hike': 'cardio',
            'Walk': 'recovery'
        };
        return typeMapping[stravaType] || 'cardio';
    }
    convertToWorkoutReflection(activity, userId) {
        const date = new Date(activity.start_date).toISOString().split('T')[0];
        return {
            user_id: userId,
            date,
            workout_type: this.mapActivityType(activity.type),
            duration_minutes: Math.round(activity.elapsed_time / 60),
            calories_burned: activity.calories,
            average_hr: activity.average_heartrate,
            max_hr: activity.max_heartrate,
            strava_activity_id: activity.id,
            created_at: new Date().toISOString()
        };
    }
}
//# sourceMappingURL=strava.js.map