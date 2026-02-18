// Supabase client configuration and utilities
import dotenv from 'dotenv'
dotenv.config()
import { createClient } from '@supabase/supabase-js'
import type { Database } from '../types/database.js'

// Local type aliases for clarity
type TrainingPlanRow = Database['public']['Tables']['training_plans']['Row']
type TrainingPlanInsert = Database['public']['Tables']['training_plans']['Insert']
type TrainingPlanUpdate = Database['public']['Tables']['training_plans']['Update']

// For development, allow explicit mock mode or placeholder values if env vars are missing
const supabaseUrl = process.env.SUPABASE_URL || 'https://placeholder.supabase.co'
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'placeholder-key'
const useMock = process.env.USE_MOCK === 'true' || supabaseUrl === 'https://placeholder.supabase.co'

if (useMock) {
  console.warn('⚠️  Running in mock mode - database writes/reads are simulated')
} else {
  console.log(`🔗 Using Supabase at ${supabaseUrl}`)
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
  static async ensureUserRecord(user: { id: string; email?: string | null; user_metadata?: any }) {
    if (useMock) return
    const payload: any = {
      id: user.id,
      email: user.email || null,
      updated_at: new Date().toISOString()
    }
    const { error } = await supabaseServiceClient
      .from('users')
      .upsert(payload, { onConflict: 'id' })
    if (error) throw error
  }
  
  static async getDailyEntry(userId: string, date: string) {
    // For development with placeholder credentials, return mock data
    if (useMock) {
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

  // Batch fetch multiple daily entries by dates (optimized for calendar views)
  static async getDailyEntriesBatch(userId: string, dates: string[]): Promise<Record<string, any>> {
    if (useMock) {
      console.log('📝 Returning mock batch daily entries for development')
      return {}
    }

    if (dates.length === 0) return {}

    const { data, error } = await (supabaseServiceClient as any)
      .from('daily_entries')
      .select('*')
      .eq('user_id', userId)
      .in('date', dates)

    if (error) throw error

    // Return as a map keyed by date for O(1) lookup
    const entriesMap: Record<string, any> = {}
    for (const entry of (data || [])) {
      entriesMap[entry.date] = entry
    }
    return entriesMap
  }

  // Batch fetch entries with training plans (optimized combined query)
  static async getDailyEntriesWithPlansBatch(userId: string, dates: string[]): Promise<{ entries: Record<string, any>, plans: Record<string, any[]> }> {
    if (useMock) {
      console.log('📝 Returning mock batch entries with plans for development')
      return { entries: {}, plans: {} }
    }

    if (dates.length === 0) return { entries: {}, plans: {} }

    // Parallel fetch for better performance
    const [entriesResult, plansResult] = await Promise.all([
      (supabaseServiceClient as any)
        .from('daily_entries')
        .select('*')
        .eq('user_id', userId)
        .in('date', dates),
      (supabaseServiceClient as any)
        .from('training_plans')
        .select('*')
        .eq('user_id', userId)
        .in('date', dates)
        .order('sequence', { ascending: true })
    ])

    if (entriesResult.error) throw entriesResult.error
    if (plansResult.error) throw plansResult.error

    // Build maps keyed by date
    const entriesMap: Record<string, any> = {}
    for (const entry of (entriesResult.data || [])) {
      entriesMap[entry.date] = entry
    }

    const plansMap: Record<string, any[]> = {}
    for (const plan of (plansResult.data || [])) {
      const dateKey = plan.date as string
      if (!plansMap[dateKey]) plansMap[dateKey] = []
      plansMap[dateKey]!.push(plan)
    }

    return { entries: entriesMap, plans: plansMap }
  }

  static async createOrUpdateDailyEntry(userId: string, date: string, updates: any) {
    // For development with placeholder credentials, return mock data
    if (useMock) {
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
      }, { onConflict: 'user_id,date' })
      .select()
      .single()
    
    if (error) throw error
    return data
  }

  static async listDailyEntries(
    userId: string,
    options: {
      page: number
      limit: number
      startDate?: string
      endDate?: string
      hasMorningRitual?: boolean
      hasEveningReflection?: boolean
    }
  ): Promise<{ data: any[]; count: number }> {
    const { page, limit, startDate, endDate, hasMorningRitual, hasEveningReflection } = options
    let query = (supabaseServiceClient as any)
      .from('daily_entries')
      .select('*', { count: 'exact' })
      .eq('user_id', userId)
      .order('date', { ascending: false })

    if (startDate) {
      query = query.gte('date', startDate)
    }

    if (endDate) {
      query = query.lte('date', endDate)
    }

    if (hasMorningRitual) {
      query = query.not('morning_completed_at', 'is', null)
    }

    if (hasEveningReflection) {
      query = query.not('evening_completed_at', 'is', null)
    }

    const offset = (page - 1) * limit
    query = query.range(offset, offset + limit - 1)

    const { data, error, count } = await query
    if (error) throw error
    return { data: data || [], count: count || 0 }
  }

  static async deleteDailyEntry(userId: string, date: string): Promise<void> {
    const { error } = await (supabaseServiceClient as any)
      .from('daily_entries')
      .delete()
      .eq('user_id', userId)
      .eq('date', date)
    if (error) throw error
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

  static async updateUserProfile(userId: string, updates: Record<string, any>) {
    const query = (supabaseServiceClient as any)
      .from('users')
      .update({
        ...updates,
        updated_at: new Date().toISOString()
      })
      .eq('id', userId)
      .select()
      .single()
    const { data, error } = await query
    
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

  static async updateUserStreak(userId: string, streakType: string, dateParam?: string) {
    // For development with placeholder credentials, just log
    const date = dateParam || new Date().toISOString().split('T')[0]
    if (useMock) {
      console.log(`📝 Mock streak update: ${streakType} for ${userId} on ${date}`)
      return
    }

    const { error } = await (supabaseServiceClient as any).rpc('update_user_streak', {
      p_user_id: userId,
      p_streak_type: streakType,
      p_completed_date: date
    })
    
    if (error) throw error
  }

  static async getCompletionHistory(userId: string, startDate: string, endDate: string) {
    if (useMock) {
      console.log(`📝 Mock completion history: ${userId} from ${startDate} to ${endDate}`)
      return []
    }

    const { data, error } = await supabaseServiceClient
      .from('daily_entries')
      .select('id, date, morning_completed_at, evening_completed_at')
      .eq('user_id', userId)
      .gte('date', startDate)
      .lte('date', endDate)
      .order('date', { ascending: false })

    if (error) throw error
    return data
  }

  static async getDailyQuote(userId: string, dateParam?: string) {
    // For development with placeholder credentials, return mock quote
    const date = dateParam || new Date().toISOString().split('T')[0]
    if (useMock) {
      console.log('📝 Returning mock daily quote for development')
      const mockQuotes = [
        { quote_text: "The only impossible journey is the one you never begin.", author: "Tony Robbins" },
        { quote_text: "Success is not final, failure is not fatal: it is the courage to continue that counts.", author: "Winston Churchill" },
        { quote_text: "Champions aren't made in the gyms. Champions are made from something deep inside them.", author: "Muhammad Ali" }
      ]
      return mockQuotes[Math.floor(Math.random() * mockQuotes.length)]
    }

    const { data, error } = await (supabaseServiceClient as any).rpc('get_daily_quote', {
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

  // ──────────────────────────────────────────────────────────────────────────────
  // Training Plans
  // ──────────────────────────────────────────────────────────────────────────────
  static async listTrainingPlans(userId: string, date: string): Promise<TrainingPlanRow[]> {
    if (useMock) {
      return []
    }
    const { data, error } = await supabaseServiceClient
      .from('training_plans')
      .select('*')
      .eq('user_id', userId)
      .eq('date', date)
      .order('sequence', { ascending: true })

    if (error) throw error
    return (data as unknown as TrainingPlanRow[]) || []
  }

  static async getTrainingPlanById(id: string, userId: string): Promise<TrainingPlanRow | null> {
    if (useMock) {
      return null
    }
    const { data, error } = await supabaseServiceClient
      .from('training_plans')
      .select('*')
      .eq('id', id)
      .eq('user_id', userId)
      .single()

    if (error && error.code !== 'PGRST116') { // PGRST116 = no rows returned
      throw error
    }
    return (data as unknown as TrainingPlanRow) || null
  }

  static async listTrainingPlansInRange(
    userId: string,
    startDate: string,
    endDate: string
  ): Promise<TrainingPlanRow[]> {
    if (useMock) {
      return []
    }
    const { data, error } = await supabaseServiceClient
      .from('training_plans')
      .select('*')
      .eq('user_id', userId)
      .gte('date', startDate)
      .lte('date', endDate)
      .order('date', { ascending: false })
      .order('sequence', { ascending: true })

    if (error) throw error
    return (data as unknown as TrainingPlanRow[]) || []
  }

  private static async getNextTrainingPlanSequence(userId: string, date: string): Promise<number> {
    if (useMock) return 1
    const { data, error } = await supabaseServiceClient
      .from('training_plans')
      .select('sequence')
      .eq('user_id', userId)
      .eq('date', date)
      .order('sequence', { ascending: false })
      .limit(1)
    if (error) throw error
    const last = (data as any)?.[0]?.sequence || 0
    return Number(last) + 1
  }

  static async createTrainingPlan(
    userId: string,
    payload: Omit<TrainingPlanInsert, 'user_id'> & { user_id?: string }
  ): Promise<TrainingPlanRow> {
    if (useMock) {
      return {
        id: 'mock-plan-id',
        user_id: userId,
        date: payload.date,
        sequence: payload.sequence || 1,
        type: payload.type,
        start_time: payload.start_time ?? null,
        intensity: payload.intensity ?? null,
        duration_minutes: payload.duration_minutes ?? null,
        notes: payload.notes ?? null,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      } as unknown as TrainingPlanRow
    }

    const insertData: TrainingPlanInsert = {
      user_id: userId,
      date: payload.date,
      sequence: payload.sequence,
      type: payload.type,
      start_time: payload.start_time ?? null,
      intensity: payload.intensity ?? null,
      duration_minutes: payload.duration_minutes ?? null,
      notes: payload.notes ?? null
    }

    if (!insertData.sequence) {
      insertData.sequence = await this.getNextTrainingPlanSequence(userId, payload.date)
    }

    const tryInsert = async (body: TrainingPlanInsert) => {
      return (supabaseServiceClient as any)
        .from('training_plans')
        .insert(body)
        .select()
        .single()
    }

    let { data, error } = await tryInsert(insertData)
    if (error && ((error as any).code === '23505' || (error as any).message?.includes('duplicate key'))) {
      // Bump sequence and retry once
      const nextSeq = await this.getNextTrainingPlanSequence(userId, payload.date)
      insertData.sequence = nextSeq
      const retry = await tryInsert(insertData)
      data = retry.data
      error = retry.error as any
    }
    if (error) throw error
    return data as unknown as TrainingPlanRow
  }

  static async updateTrainingPlanById(
    id: string,
    userId: string,
    updates: TrainingPlanUpdate
  ): Promise<TrainingPlanRow> {
    if (useMock) {
      return {
        id,
        user_id: userId,
        date: updates.date || new Date().toISOString().split('T')[0],
        sequence: updates.sequence || 1,
        type: (updates as any).type || 'strength',
        start_time: (updates as any).start_time ?? null,
        intensity: updates.intensity ?? null,
        duration_minutes: updates.duration_minutes ?? null,
        notes: updates.notes ?? null,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      } as unknown as TrainingPlanRow
    }

    const { data, error } = await (supabaseServiceClient as any)
      .from('training_plans')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .eq('user_id', userId)
      .select()
      .single()

    if (error) throw error
    return data as unknown as TrainingPlanRow
  }

  static async deleteTrainingPlanById(id: string, userId: string): Promise<void> {
    if (useMock) return
    const { error } = await supabaseServiceClient
      .from('training_plans')
      .delete()
      .eq('id', id)
      .eq('user_id', userId)
    if (error) throw error
  }

  static async markInsightAsRead(insightId: string, userId: string) {
    const { error } = await (supabaseServiceClient as any)
      .from('ai_insights')
      .update({ is_read: true })
      .eq('id', insightId)
      .eq('user_id', userId)

    if (error) throw error
  }
}
