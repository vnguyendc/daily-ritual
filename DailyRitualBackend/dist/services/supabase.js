import dotenv from 'dotenv';
dotenv.config();
import { createClient } from '@supabase/supabase-js';
const supabaseUrl = process.env.SUPABASE_URL || 'https://placeholder.supabase.co';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'placeholder-key';
const useMock = process.env.USE_MOCK === 'true' || supabaseUrl === 'https://placeholder.supabase.co';
if (useMock) {
    console.warn('⚠️  Running in mock mode - database writes/reads are simulated');
}
else {
    console.log(`🔗 Using Supabase at ${supabaseUrl}`);
}
export const supabaseServiceClient = createClient(supabaseUrl, supabaseServiceKey, {
    auth: {
        autoRefreshToken: false,
        persistSession: false
    }
});
export const supabaseClient = createClient(supabaseUrl, process.env.SUPABASE_ANON_KEY || supabaseServiceKey);
export async function getUserFromToken(token) {
    const { data: { user }, error } = await supabaseServiceClient.auth.getUser(token);
    if (error || !user) {
        throw new Error('Invalid or expired token');
    }
    return user;
}
export async function verifyUserOwnership(userId, resourceUserId) {
    if (userId !== resourceUserId) {
        throw new Error('Unauthorized: Resource does not belong to user');
    }
}
export class DatabaseService {
    static async ensureUserRecord(user) {
        if (useMock)
            return;
        const payload = {
            id: user.id,
            email: user.email || null,
            updated_at: new Date().toISOString()
        };
        const { error } = await supabaseServiceClient
            .from('users')
            .upsert(payload, { onConflict: 'id' });
        if (error)
            throw error;
    }
    static async getDailyEntry(userId, date) {
        if (useMock) {
            console.log('📝 Returning mock daily entry for development');
            return null;
        }
        const { data, error } = await supabaseServiceClient
            .from('daily_entries')
            .select('*')
            .eq('user_id', userId)
            .eq('date', date)
            .single();
        if (error && error.code !== 'PGRST116') {
            throw error;
        }
        return data;
    }
    static async createOrUpdateDailyEntry(userId, date, updates) {
        if (useMock) {
            console.log('📝 Creating mock daily entry for development');
            return {
                id: 'mock-entry-id',
                user_id: userId,
                date,
                ...updates,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
            };
        }
        const { data, error } = await supabaseServiceClient
            .from('daily_entries')
            .upsert({
            user_id: userId,
            date,
            ...updates,
            updated_at: new Date().toISOString()
        })
            .select()
            .single();
        if (error)
            throw error;
        return data;
    }
    static async createWorkoutReflection(userId, reflection) {
        const { data, error } = await supabaseServiceClient
            .from('workout_reflections')
            .insert({
            user_id: userId,
            ...reflection
        })
            .select()
            .single();
        if (error)
            throw error;
        return data;
    }
    static async getUserProfile(userId) {
        const { data, error } = await supabaseServiceClient
            .from('users')
            .select('*')
            .eq('id', userId)
            .single();
        if (error)
            throw error;
        return data;
    }
    static async updateUserProfile(userId, updates) {
        const query = supabaseServiceClient
            .from('users')
            .update({
            ...updates,
            updated_at: new Date().toISOString()
        })
            .eq('id', userId)
            .select()
            .single();
        const { data, error } = await query;
        if (error)
            throw error;
        return data;
    }
    static async getUserStreaks(userId) {
        const { data, error } = await supabaseServiceClient
            .from('user_streaks')
            .select('*')
            .eq('user_id', userId);
        if (error)
            throw error;
        return data;
    }
    static async updateUserStreak(userId, streakType, dateParam) {
        const date = dateParam || new Date().toISOString().split('T')[0];
        if (useMock) {
            console.log(`📝 Mock streak update: ${streakType} for ${userId} on ${date}`);
            return;
        }
        const { error } = await supabaseServiceClient.rpc('update_user_streak', {
            p_user_id: userId,
            p_streak_type: streakType,
            p_completed_date: date
        });
        if (error)
            throw error;
    }
    static async getDailyQuote(userId, dateParam) {
        const date = dateParam || new Date().toISOString().split('T')[0];
        if (useMock) {
            console.log('📝 Returning mock daily quote for development');
            const mockQuotes = [
                { quote_text: "The only impossible journey is the one you never begin.", author: "Tony Robbins" },
                { quote_text: "Success is not final, failure is not fatal: it is the courage to continue that counts.", author: "Winston Churchill" },
                { quote_text: "Champions aren't made in the gyms. Champions are made from something deep inside them.", author: "Muhammad Ali" }
            ];
            return mockQuotes[Math.floor(Math.random() * mockQuotes.length)];
        }
        const { data, error } = await supabaseServiceClient.rpc('get_daily_quote', {
            p_user_id: userId,
            p_date: date
        });
        if (error)
            throw error;
        return data?.[0] || null;
    }
    static async getRecentEntries(userId, limit = 7) {
        const { data: dailyEntries, error: dailyError } = await supabaseServiceClient
            .from('daily_entries')
            .select('*')
            .eq('user_id', userId)
            .order('date', { ascending: false })
            .limit(limit);
        const { data: workoutReflections, error: workoutError } = await supabaseServiceClient
            .from('workout_reflections')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', { ascending: false })
            .limit(limit);
        const { data: journalEntries, error: journalError } = await supabaseServiceClient
            .from('journal_entries')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', { ascending: false })
            .limit(limit);
        if (dailyError)
            throw dailyError;
        if (workoutError)
            throw workoutError;
        if (journalError)
            throw journalError;
        return {
            daily_entries: dailyEntries || [],
            workout_reflections: workoutReflections || [],
            journal_entries: journalEntries || []
        };
    }
    static async getUpcomingCompetitions(userId) {
        const { data, error } = await supabaseServiceClient
            .from('competitions')
            .select('*')
            .eq('user_id', userId)
            .eq('status', 'upcoming')
            .gte('competition_date', new Date().toISOString().split('T')[0])
            .order('competition_date', { ascending: true })
            .limit(5);
        if (error)
            throw error;
        return data || [];
    }
    static async getRecentInsights(userId, limit = 5) {
        const { data, error } = await supabaseServiceClient
            .from('ai_insights')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', { ascending: false })
            .limit(limit);
        if (error)
            throw error;
        return data || [];
    }
    static async markInsightAsRead(insightId, userId) {
        const { error } = await supabaseServiceClient
            .from('ai_insights')
            .update({ is_read: true })
            .eq('id', insightId)
            .eq('user_id', userId);
        if (error)
            throw error;
    }
}
//# sourceMappingURL=supabase.js.map