import { supabaseServiceClient } from '../services/supabase.js';
import { WhoopService } from '../services/integrations/whoop.js';
const whoopService = new WhoopService();
export class WebhooksController {
    static async handleWhoopWebhook(req, res) {
        try {
            const signature = req.headers['x-whoop-signature'];
            const webhookSecret = process.env.WHOOP_WEBHOOK_SECRET;
            if (webhookSecret && signature) {
                const payload = JSON.stringify(req.body);
                const isValid = whoopService.validateWebhookSignature(payload, signature, webhookSecret);
                if (!isValid) {
                    return res.status(401).json({ error: 'Invalid webhook signature' });
                }
            }
            const event = req.body;
            if (!event || !event.type) {
                return res.status(400).json({ error: 'Invalid webhook payload' });
            }
            console.log(`Whoop webhook received: ${event.type}`, JSON.stringify(event));
            switch (event.type) {
                case 'workout.updated':
                case 'workout.created': {
                    await handleWhoopWorkoutEvent(event);
                    break;
                }
                case 'recovery.updated': {
                    await handleWhoopRecoveryEvent(event);
                    break;
                }
                default:
                    console.log(`Unhandled Whoop webhook event type: ${event.type}`);
            }
            res.status(200).json({ received: true });
        }
        catch (error) {
            console.error('Error handling Whoop webhook:', error);
            res.status(200).json({ received: true, error: error.message });
        }
    }
}
async function handleWhoopWorkoutEvent(event) {
    try {
        const externalUserId = String(event.user_id);
        const { data: integration } = await supabaseServiceClient
            .from('user_integrations')
            .select('user_id, access_token, refresh_token, token_expires_at')
            .eq('service', 'whoop')
            .eq('external_user_id', externalUserId)
            .single();
        if (!integration) {
            console.log(`No integration found for Whoop user ${externalUserId}`);
            return;
        }
        let accessToken = integration.access_token;
        if (integration.token_expires_at && new Date(integration.token_expires_at) < new Date()) {
            const refreshed = await whoopService.refreshAccessToken(integration.refresh_token);
            accessToken = refreshed.access_token;
            const expiresAt = new Date(Date.now() + refreshed.expires_in * 1000).toISOString();
            await supabaseServiceClient
                .from('user_integrations')
                .update({
                access_token: refreshed.access_token,
                refresh_token: refreshed.refresh_token,
                token_expires_at: expiresAt
            })
                .eq('user_id', integration.user_id)
                .eq('service', 'whoop');
        }
        const workoutId = event.id || event.workout_id;
        if (!workoutId)
            return;
        const today = new Date().toISOString().split('T')[0];
        const workouts = await whoopService.getWorkouts(accessToken, today, today);
        for (const workout of workouts) {
            await whoopService.importWhoopWorkout(integration.user_id, workout);
        }
    }
    catch (error) {
        console.error('Error processing Whoop workout event:', error);
    }
}
async function handleWhoopRecoveryEvent(event) {
    try {
        const externalUserId = String(event.user_id);
        const { data: integration } = await supabaseServiceClient
            .from('user_integrations')
            .select('user_id, access_token, refresh_token, token_expires_at')
            .eq('service', 'whoop')
            .eq('external_user_id', externalUserId)
            .single();
        if (!integration)
            return;
        let accessToken = integration.access_token;
        if (integration.token_expires_at && new Date(integration.token_expires_at) < new Date()) {
            const refreshed = await whoopService.refreshAccessToken(integration.refresh_token);
            accessToken = refreshed.access_token;
            await supabaseServiceClient
                .from('user_integrations')
                .update({
                access_token: refreshed.access_token,
                refresh_token: refreshed.refresh_token,
                token_expires_at: new Date(Date.now() + refreshed.expires_in * 1000).toISOString()
            })
                .eq('user_id', integration.user_id)
                .eq('service', 'whoop');
        }
        const today = new Date().toISOString().split('T')[0];
        const recoveryData = await whoopService.getRecoveryData(accessToken, today);
        if (!recoveryData)
            return;
        const { data: latestReflection } = await supabaseServiceClient
            .from('workout_reflections')
            .select('id')
            .eq('user_id', integration.user_id)
            .eq('date', today)
            .order('created_at', { ascending: false })
            .limit(1)
            .single();
        if (latestReflection) {
            await supabaseServiceClient
                .from('workout_reflections')
                .update({
                recovery_score: recoveryData.recovery_score,
                sleep_performance: recoveryData.sleep_performance,
                hrv: recoveryData.hrv,
                resting_hr: recoveryData.resting_hr,
                updated_at: new Date().toISOString()
            })
                .eq('id', latestReflection.id);
        }
    }
    catch (error) {
        console.error('Error processing Whoop recovery event:', error);
    }
}
//# sourceMappingURL=webhooks.js.map