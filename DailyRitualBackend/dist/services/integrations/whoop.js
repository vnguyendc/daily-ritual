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
}
//# sourceMappingURL=whoop.js.map