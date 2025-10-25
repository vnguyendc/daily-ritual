export declare class SupabaseEdgeFunctions {
    static generateAffirmation({ supabaseUrl, authToken, recent_goals, next_workout_type }: {
        supabaseUrl: string;
        authToken: string | undefined;
        recent_goals?: string[];
        next_workout_type?: string;
    }): Promise<{
        affirmation?: string;
    }>;
    static generateInsights({ supabaseUrl, authToken, insight_type, data_period_end }: {
        supabaseUrl: string;
        authToken: string | undefined;
        insight_type: 'morning' | 'evening' | 'weekly' | 'competition_prep' | 'pattern_analysis';
        data_period_end?: string;
    }): Promise<void>;
}
//# sourceMappingURL=supabaseEdgeFunctions.d.ts.map