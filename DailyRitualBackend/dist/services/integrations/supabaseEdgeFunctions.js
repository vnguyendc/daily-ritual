export class SupabaseEdgeFunctions {
    static async generateAffirmation({ supabaseUrl, authToken, recent_goals, next_workout_type }) {
        if (!supabaseUrl)
            throw new Error('SUPABASE_URL not configured');
        try {
            const resp = await fetch(`${supabaseUrl}/functions/v1/generate-affirmation`, {
                method: 'POST',
                headers: {
                    'Authorization': authToken ? `Bearer ${authToken}` : '',
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ recent_goals, next_workout_type })
            });
            if (!resp.ok) {
                return {};
            }
            const data = await resp.json();
            return { affirmation: data.affirmation };
        }
        catch {
            return {};
        }
    }
    static async generateInsights({ supabaseUrl, authToken, insight_type, data_period_end }) {
        if (!supabaseUrl)
            throw new Error('SUPABASE_URL not configured');
        try {
            await fetch(`${supabaseUrl}/functions/v1/generate-insights`, {
                method: 'POST',
                headers: {
                    'Authorization': authToken ? `Bearer ${authToken}` : '',
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ insight_type, data_period_end })
            });
        }
        catch {
        }
    }
}
//# sourceMappingURL=supabaseEdgeFunctions.js.map