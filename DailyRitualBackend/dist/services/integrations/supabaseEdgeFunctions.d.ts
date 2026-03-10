import type { InsightType } from '../../types/api.js';
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
        insight_type: InsightType;
        data_period_end?: string;
    }): Promise<void>;
    static generateInsight({ supabaseUrl, authToken, insight_type, context_data, data_period_end }: {
        supabaseUrl: string;
        authToken: string | undefined;
        insight_type: InsightType;
        context_data?: Record<string, any>;
        data_period_end?: string;
    }): Promise<{
        insight?: any;
    }>;
}
//# sourceMappingURL=supabaseEdgeFunctions.d.ts.map