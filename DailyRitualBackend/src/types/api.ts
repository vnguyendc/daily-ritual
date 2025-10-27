// API Types for Daily Ritual
import { Database } from './database.js'

// Convenience type aliases
export type User = Database['public']['Tables']['users']['Row']
export type DailyEntry = Database['public']['Tables']['daily_entries']['Row']
export type WorkoutReflection = Database['public']['Tables']['workout_reflections']['Row']
export type JournalEntry = Database['public']['Tables']['journal_entries']['Row']
export type Competition = Database['public']['Tables']['competitions']['Row']
export type CompetitionPrepEntry = Database['public']['Tables']['competition_prep_entries']['Row']
export type AIInsight = Database['public']['Tables']['ai_insights']['Row']
export type Quote = Database['public']['Tables']['quotes']['Row']
export type UserStreak = Database['public']['Tables']['user_streaks']['Row']

// Insert types
export type UserInsert = Database['public']['Tables']['users']['Insert']
export type DailyEntryInsert = Database['public']['Tables']['daily_entries']['Insert']
export type WorkoutReflectionInsert = Database['public']['Tables']['workout_reflections']['Insert']
export type JournalEntryInsert = Database['public']['Tables']['journal_entries']['Insert']
export type CompetitionInsert = Database['public']['Tables']['competitions']['Insert']
export type CompetitionPrepEntryInsert = Database['public']['Tables']['competition_prep_entries']['Insert']
export type AIInsightInsert = Database['public']['Tables']['ai_insights']['Insert']

// Update types
export type UserUpdate = Database['public']['Tables']['users']['Update']
export type DailyEntryUpdate = Database['public']['Tables']['daily_entries']['Update']
export type WorkoutReflectionUpdate = Database['public']['Tables']['workout_reflections']['Update']
export type JournalEntryUpdate = Database['public']['Tables']['journal_entries']['Update']
export type CompetitionUpdate = Database['public']['Tables']['competitions']['Update']
export type CompetitionPrepEntryUpdate = Database['public']['Tables']['competition_prep_entries']['Update']

// API Request/Response types
export interface MorningRitualRequest {
  goals: string[]
  gratitudes: string[]
  affirmation?: string
  quote_reflection?: string
  planned_training_type?: string
  planned_training_time?: string
  planned_intensity?: string
  planned_duration?: number
  planned_notes?: string
  // Alias accepted by API; mapped to planned_notes on write
  morning_notes?: string
}

export interface MorningRitualResponse {
  daily_entry: DailyEntry
  affirmation: string | null
  daily_quote: Quote
  ai_insight?: string
}

export interface EveningReflectionRequest {
  quote_application: string
  day_went_well: string
  day_improve: string
  overall_mood: number
}

export interface WorkoutReflectionRequest {
  training_feeling: number
  what_went_well: string
  what_to_improve: string
  energy_level?: number
  focus_level?: number
  workout_type?: string
  workout_intensity?: string
  duration_minutes?: number
}

export interface CompetitionRequest {
  name: string
  sport?: string
  competition_date: string
  location?: string
  description?: string
  goal_time?: string
  goal_placement?: string
  importance_level?: number
}

export interface CompetitionPrepRequest {
  confidence_level?: number
  anxiety_level?: number
  readiness_level?: number
  mental_focus_notes?: string
  physical_preparation_notes?: string
  strategy_notes?: string
  concerns?: string
}

// Dashboard/Analytics types
export interface DashboardData {
  current_streak: {
    morning_ritual: number
    workout_reflection: number
    evening_reflection: number
    daily_complete: number
  }
  recent_entries: {
    daily_entries: DailyEntry[]
    workout_reflections: WorkoutReflection[]
    journal_entries: JournalEntry[]
  }
  upcoming_competitions: Competition[]
  recent_insights: AIInsight[]
  weekly_stats: {
    goals_completed: number
    total_goals: number
    avg_mood: number
    workout_count: number
    avg_training_feeling: number
  }
}

export interface WeeklyInsightData {
  goal_completion_rate: number
  avg_satisfaction: number
  top_gratitudes: string[]
  energy_by_time_of_day: Record<string, number>
  mood_patterns: Array<{ date: string; mood: number }>
  training_patterns: Array<{ type: string; feeling: number; count: number }>
}

// External integration types
export interface WhoopData {
  recovery_score: number
  strain_score: number
  sleep_performance: number
  hrv: number
  resting_hr: number
}

export interface StravaActivity {
  id: string
  name: string
  type: string
  start_date: string
  elapsed_time: number
  distance: number
  average_heartrate?: number
  max_heartrate?: number
  calories?: number
}

export interface AppleHealthWorkout {
  id: string
  workout_type: string
  start_date: string
  end_date: string
  duration: number
  calories_burned?: number
  average_heart_rate?: number
  max_heart_rate?: number
}

// AI Generation types
export interface AffirmationGenerationRequest {
  user_id: string
  sport?: string
  recent_goals: string[]
  next_workout_type?: string
  recent_challenges: string[]
  recovery_data?: Partial<WhoopData>
}

export interface InsightGenerationRequest {
  user_id: string
  insight_type: 'morning' | 'evening' | 'weekly' | 'competition_prep' | 'pattern_analysis'
  data_period_start?: string
  data_period_end?: string
  context_data?: Record<string, any>
}

// Error types
export interface APIError {
  error: string
  message: string
  code?: string
  details?: Record<string, any>
}

// Success response wrapper
export interface APIResponse<T = any> {
  success: boolean
  data?: T
  error?: APIError
  message?: string
}

// Helpers
export function ok<T>(data: T, message?: string): APIResponse<T> {
  return { success: true, data, ...(message ? { message } : {}) }
}

export function fail(message: string, code?: string, details?: Record<string, any>): APIResponse<null> {
  return { success: false, error: { error: 'Error', message, code, details } }
}

// Pagination
export interface PaginationParams {
  page?: number
  limit?: number
  sort_by?: string
  sort_order?: 'asc' | 'desc'
}

export interface PaginatedResponse<T> {
  data: T[]
  pagination: {
    page: number
    limit: number
    total: number
    total_pages: number
    has_next: boolean
    has_prev: boolean
  }
}

// Filter types
export interface DailyEntryFilters extends PaginationParams {
  start_date?: string
  end_date?: string
  has_morning_ritual?: boolean
  has_evening_reflection?: boolean
  mood_min?: number
  mood_max?: number
}

export interface WorkoutReflectionFilters extends PaginationParams {
  start_date?: string
  end_date?: string
  workout_type?: string
  training_feeling_min?: number
  training_feeling_max?: number
}

export interface JournalEntryFilters extends PaginationParams {
  start_date?: string
  end_date?: string
  tags?: string[]
  mood_min?: number
  mood_max?: number
  search_query?: string
}
