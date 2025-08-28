import type { Database } from '../types/database.js';
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
    static markInsightAsRead(insightId: string, userId: string): Promise<void>;
}
//# sourceMappingURL=supabase.d.ts.map