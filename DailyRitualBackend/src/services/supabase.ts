// Supabase client configuration and utilities
import { createClient } from '@supabase/supabase-js'
import type { Database } from '../types/database.js'

// For development, use placeholder values if env vars are missing
const supabaseUrl = process.env.SUPABASE_URL || 'https://placeholder.supabase.co'
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'placeholder-key'

if (supabaseUrl === 'https://placeholder.supabase.co') {
  console.warn('⚠️  Using placeholder Supabase credentials - database features will not work')
}

// Service role client for server-side operations
export const supabaseServiceClient = createClient<Database>(
  supabaseUrl,
  supabaseServiceKey,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  }
)

// Regular client for user-authenticated operations
export const supabaseClient = createClient<Database>(
  supabaseUrl,
  process.env.SUPABASE_ANON_KEY || supabaseServiceKey
)

// Utility function to get user from JWT token
export async function getUserFromToken(token: string) {
  const { data: { user }, error } = await supabaseServiceClient.auth.getUser(token)
  
  if (error || !user) {
    throw new Error('Invalid or expired token')
  }
  
  return user
}

// Utility function to verify user owns resource
export async function verifyUserOwnership(userId: string, resourceUserId: string) {
  if (userId !== resourceUserId) {
    throw new Error('Unauthorized: Resource does not belong to user')
  }
}

// Database utility functions
export class DatabaseService {
  
  static async getDailyEntry(userId: string, date: string) {
    // For development with placeholder credentials, return mock data
    if (supabaseUrl === 'https://placeholder.supabase.co') {
      console.log('📝 Returning mock daily entry for development')
      return null // No existing entry, will create new one
    }

    const { data, error } = await supabaseServiceClient
      .from('daily_entries')
      .select('*')
      .eq('user_id', userId)
      .eq('date', date)
      .single()
    
    if (error && error.code !== 'PGRST116') { // PGRST116 = no rows returned
      throw error
    }
    
    return data
  }

  static async createOrUpdateDailyEntry(userId: string, date: string, updates: any) {
    // For development with placeholder credentials, return mock data
    if (supabaseUrl === 'https://placeholder.supabase.co') {
      console.log('📝 Creating mock daily entry for development')
      return {
        id: 'mock-entry-id',
        user_id: userId,
        date,
        ...updates,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }
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
      .single()
    
    if (error) throw error
    return data
  }

  static async createWorkoutReflection(userId: string, reflection: any) {
    const { data, error } = await supabaseServiceClient
      .from('workout_reflections')
      .insert({
        user_id: userId,
        ...reflection
      })
      .select()
      .single()
    
    if (error) throw error
    return data
  }

  static async getUserProfile(userId: string) {
    const { data, error } = await supabaseServiceClient
      .from('users')
      .select('*')
      .eq('id', userId)
      .single()
    
    if (error) throw error
    return data
  }

  static async updateUserProfile(userId: string, updates: any) {
    const { data, error } = await supabaseServiceClient
      .from('users')
      .update({
        ...updates,
        updated_at: new Date().toISOString()
      })
      .eq('id', userId)
      .select()
      .single()
    
    if (error) throw error
    return data
  }

  static async getUserStreaks(userId: string) {
    const { data, error } = await supabaseServiceClient
      .from('user_streaks')
      .select('*')
      .eq('user_id', userId)
    
    if (error) throw error
    return data
  }

  static async updateUserStreak(userId: string, streakType: string, date: string = new Date().toISOString().split('T')[0]) {
    // For development with placeholder credentials, just log
    if (supabaseUrl === 'https://placeholder.supabase.co') {
      console.log(`📝 Mock streak update: ${streakType} for ${userId} on ${date}`)
      return
    }

    const { error } = await supabaseServiceClient.rpc('update_user_streak', {
      p_user_id: userId,
      p_streak_type: streakType,
      p_completed_date: date
    })
    
    if (error) throw error
  }

  static async getDailyQuote(userId: string, date: string = new Date().toISOString().split('T')[0]) {
    // For development with placeholder credentials, return mock quote
    if (supabaseUrl === 'https://placeholder.supabase.co') {
      console.log('📝 Returning mock daily quote for development')
      const mockQuotes = [
        { quote_text: "The only impossible journey is the one you never begin.", author: "Tony Robbins" },
        { quote_text: "Success is not final, failure is not fatal: it is the courage to continue that counts.", author: "Winston Churchill" },
        { quote_text: "Champions aren't made in the gyms. Champions are made from something deep inside them.", author: "Muhammad Ali" }
      ]
      return mockQuotes[Math.floor(Math.random() * mockQuotes.length)]
    }

    const { data, error } = await supabaseServiceClient.rpc('get_daily_quote', {
      p_user_id: userId,
      p_date: date
    })
    
    if (error) throw error
    return data?.[0] || null
  }

  static async getRecentEntries(userId: string, limit: number = 7) {
    const { data: dailyEntries, error: dailyError } = await supabaseServiceClient
      .from('daily_entries')
      .select('*')
      .eq('user_id', userId)
      .order('date', { ascending: false })
      .limit(limit)

    const { data: workoutReflections, error: workoutError } = await supabaseServiceClient
      .from('workout_reflections')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(limit)

    const { data: journalEntries, error: journalError } = await supabaseServiceClient
      .from('journal_entries')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(limit)

    if (dailyError) throw dailyError
    if (workoutError) throw workoutError
    if (journalError) throw journalError

    return {
      daily_entries: dailyEntries || [],
      workout_reflections: workoutReflections || [],
      journal_entries: journalEntries || []
    }
  }

  static async getUpcomingCompetitions(userId: string) {
    const { data, error } = await supabaseServiceClient
      .from('competitions')
      .select('*')
      .eq('user_id', userId)
      .eq('status', 'upcoming')
      .gte('competition_date', new Date().toISOString().split('T')[0])
      .order('competition_date', { ascending: true })
      .limit(5)

    if (error) throw error
    return data || []
  }

  static async getRecentInsights(userId: string, limit: number = 5) {
    const { data, error } = await supabaseServiceClient
      .from('ai_insights')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(limit)

    if (error) throw error
    return data || []
  }

  static async markInsightAsRead(insightId: string, userId: string) {
    const { error } = await supabaseServiceClient
      .from('ai_insights')
      .update({ is_read: true })
      .eq('id', insightId)
      .eq('user_id', userId)

    if (error) throw error
  }
}
