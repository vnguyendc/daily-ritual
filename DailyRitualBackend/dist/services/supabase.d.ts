import type { Database } from '../types/database.js';
type TrainingPlanRow = Database['public']['Tables']['training_plans']['Row'];
type TrainingPlanInsert = Database['public']['Tables']['training_plans']['Insert'];
type TrainingPlanUpdate = Database['public']['Tables']['training_plans']['Update'];
export declare const supabaseServiceClient: import("@supabase/supabase-js").SupabaseClient<Database, "public", "public", never, {
    PostgrestVersion: "12";
}>;
export declare const supabaseClient: import("@supabase/supabase-js").SupabaseClient<Database, "public", "public", never, {
    PostgrestVersion: "12";
}>;
export declare function getUserFromToken(token: string): Promise<import("@supabase/supabase-js").AuthUser>;
export declare function verifyUserOwnership(userId: string, resourceUserId: string): Promise<void>;
export declare class DatabaseService {
    static ensureUserRecord(user: {
        id: string;
        email?: string | null;
        user_metadata?: any;
    }): Promise<void>;
    static getDailyEntry(userId: string, date: string): Promise<null>;
    static createOrUpdateDailyEntry(userId: string, date: string, updates: any): Promise<any>;
    static listDailyEntries(userId: string, options: {
        page: number;
        limit: number;
        startDate?: string;
        endDate?: string;
        hasMorningRitual?: boolean;
        hasEveningReflection?: boolean;
    }): Promise<{
        data: any[];
        count: number;
    }>;
    static deleteDailyEntry(userId: string, date: string): Promise<void>;
    static createWorkoutReflection(userId: string, reflection: any): Promise<never>;
    static getUserProfile(userId: string): Promise<never>;
    static updateUserProfile(userId: string, updates: Record<string, any>): Promise<any>;
    static getUserStreaks(userId: string): Promise<never[]>;
    static updateUserStreak(userId: string, streakType: string, dateParam?: string): Promise<void>;
    static getDailyQuote(userId: string, dateParam?: string): Promise<any>;
    static getRecentEntries(userId: string, limit?: number): Promise<{
        daily_entries: never[];
        workout_reflections: never[];
        journal_entries: never[];
    }>;
    static getUpcomingCompetitions(userId: string): Promise<never[]>;
    static getRecentInsights(userId: string, limit?: number): Promise<never[]>;
    static listTrainingPlans(userId: string, date: string): Promise<TrainingPlanRow[]>;
    private static getNextTrainingPlanSequence;
    static createTrainingPlan(userId: string, payload: Omit<TrainingPlanInsert, 'user_id'> & {
        user_id?: string;
    }): Promise<TrainingPlanRow>;
    static updateTrainingPlanById(id: string, userId: string, updates: TrainingPlanUpdate): Promise<TrainingPlanRow>;
    static deleteTrainingPlanById(id: string, userId: string): Promise<void>;
    static markInsightAsRead(insightId: string, userId: string): Promise<void>;
}
export {};
//# sourceMappingURL=supabase.d.ts.map