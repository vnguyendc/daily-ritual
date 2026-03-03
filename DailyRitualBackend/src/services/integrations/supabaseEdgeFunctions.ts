// Supabase Edge Functions service wrappers
import type { InsightType } from '../../types/api.js'

export class SupabaseEdgeFunctions {
  static async generateAffirmation({
    supabaseUrl,
    authToken,
    recent_goals,
    next_workout_type
  }: {
    supabaseUrl: string
    authToken: string | undefined
    recent_goals?: string[]
    next_workout_type?: string
  }): Promise<{ affirmation?: string }> {
    if (!supabaseUrl) throw new Error('SUPABASE_URL not configured')
    try {
      const resp = await fetch(`${supabaseUrl}/functions/v1/generate-affirmation`, {
        method: 'POST',
        headers: {
          'Authorization': authToken ? `Bearer ${authToken}` : '',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ recent_goals, next_workout_type })
      })
      if (!resp.ok) {
        return {}
      }
      const data = await resp.json()
      return { affirmation: data.affirmation }
    } catch {
      return {}
    }
  }

  static async generateInsights({
    supabaseUrl,
    authToken,
    insight_type,
    data_period_end
  }: {
    supabaseUrl: string
    authToken: string | undefined
    insight_type: InsightType
    data_period_end?: string
  }): Promise<void> {
    if (!supabaseUrl) throw new Error('SUPABASE_URL not configured')
    try {
      await fetch(`${supabaseUrl}/functions/v1/generate-insights`, {
        method: 'POST',
        headers: {
          'Authorization': authToken ? `Bearer ${authToken}` : '',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ insight_type, data_period_end })
      })
    } catch {
      // swallow
    }
  }

  /**
   * Fire-and-forget insight generation with context data.
   * Used after actions (post-workout, post-meal) to trigger contextual insights.
   */
  static async generateInsight({
    supabaseUrl,
    authToken,
    insight_type,
    context_data,
    data_period_end
  }: {
    supabaseUrl: string
    authToken: string | undefined
    insight_type: InsightType
    context_data?: Record<string, any>
    data_period_end?: string
  }): Promise<{ insight?: any }> {
    if (!supabaseUrl) throw new Error('SUPABASE_URL not configured')
    try {
      const resp = await fetch(`${supabaseUrl}/functions/v1/generate-insights`, {
        method: 'POST',
        headers: {
          'Authorization': authToken ? `Bearer ${authToken}` : '',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ insight_type, context_data, data_period_end })
      })
      if (!resp.ok) return {}
      const data = await resp.json()
      return { insight: data.insight }
    } catch {
      return {}
    }
  }
}
