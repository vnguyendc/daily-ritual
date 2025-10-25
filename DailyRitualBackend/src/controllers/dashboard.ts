// Dashboard Controller - provides overview data for the main app dashboard
import { Request, Response } from 'express'
import { DatabaseService, getUserFromToken, supabaseServiceClient } from '../services/supabase.js'
import type { APIResponse, DashboardData } from '../types/api.js'

export class DashboardController {
  
  // Get comprehensive dashboard data
  static async getDashboardData(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      if (!token) {
        return res.status(401).json({ error: 'Authorization token required' })
      }

      const user = await getUserFromToken(token)

      // Get all dashboard data in parallel for better performance
      const [
        streaks,
        recentEntries,
        upcomingCompetitions,
        recentInsights,
        weeklyStats
      ] = await Promise.all([
        DatabaseService.getUserStreaks(user.id),
        DatabaseService.getRecentEntries(user.id, 5),
        DatabaseService.getUpcomingCompetitions(user.id),
        DatabaseService.getRecentInsights(user.id, 3),
        DashboardController.getWeeklyStats(user.id)
      ])

      // Format streaks data
      const currentStreaks = streaks?.reduce((acc, streak: any) => {
        acc[streak.streak_type] = streak.current_streak
        return acc
      }, {} as Record<string, number>) || {}

      const dashboardData: DashboardData = {
        current_streak: {
          morning_ritual: currentStreaks.morning_ritual || 0,
          workout_reflection: currentStreaks.workout_reflection || 0,
          evening_reflection: currentStreaks.evening_reflection || 0,
          daily_complete: currentStreaks.daily_complete || 0
        },
        recent_entries: recentEntries,
        upcoming_competitions: upcomingCompetitions,
        recent_insights: recentInsights,
        weekly_stats: weeklyStats
      }

      const response: APIResponse<DashboardData> = {
        success: true,
        data: dashboardData
      }

      res.json(response)
    } catch (error) {
      console.error('Error getting dashboard data:', error)
      res.status(500).json({
        success: false,
        error: { error: 'Internal server error', message: error.message }
      })
    }
  }

  // Get weekly statistics
  private static async getWeeklyStats(userId: string) {
    const oneWeekAgo = new Date()
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7)
    const startDate = oneWeekAgo.toISOString().split('T')[0]
    const endDate = new Date().toISOString().split('T')[0]

    // Get weekly daily entries
    const { data: weeklyEntries, error: entriesError } = await supabaseServiceClient
      .from('daily_entries')
      .select('goals, overall_mood')
      .eq('user_id', userId)
      .gte('date', startDate)
      .lte('date', endDate)

    if (entriesError) throw entriesError

    // Get weekly workout reflections
    const { data: weeklyWorkouts, error: workoutsError } = await supabaseServiceClient
      .from('workout_reflections')
      .select('training_feeling')
      .eq('user_id', userId)
      .gte('date', startDate)
      .lte('date', endDate)

    if (workoutsError) throw workoutsError

    // Calculate stats
    const entries: any[] = weeklyEntries || []
    const workouts: any[] = weeklyWorkouts || []

    const totalGoals = entries.reduce((sum, entry) => sum + (entry.goals?.length || 0), 0)
    const goalsCompleted = totalGoals // Assuming all set goals are completed for now
    const avgMood = entries.length > 0 ? 
      entries.reduce((sum, entry) => sum + (entry.overall_mood || 0), 0) / entries.length : 0
    const avgTrainingFeeling = workouts.length > 0 ? 
      workouts.reduce((sum, workout) => sum + (workout.training_feeling || 0), 0) / workouts.length : 0

    return {
      goals_completed: goalsCompleted,
      total_goals: totalGoals,
      avg_mood: Math.round(avgMood * 10) / 10,
      workout_count: workouts.length,
      avg_training_feeling: Math.round(avgTrainingFeeling * 10) / 10
    }
  }

  // Get user profile with subscription info
  static async getUserProfile(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      if (!token) {
        return res.status(401).json({ error: 'Authorization token required' })
      }

      const user = await getUserFromToken(token)
      const profile = await DatabaseService.getUserProfile(user.id)

      const response: APIResponse = {
        success: true,
        data: profile
      }

      res.json(response)
    } catch (error) {
      console.error('Error getting user profile:', error)
      res.status(500).json({
        success: false,
        error: { error: 'Internal server error', message: error.message }
      })
    }
  }

  // Update user profile
  static async updateUserProfile(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      if (!token) {
        return res.status(401).json({ error: 'Authorization token required' })
      }

      const user = await getUserFromToken(token)
      
      // Only allow certain fields to be updated
      const allowedFields = [
        'name', 
        'primary_sport', 
        'morning_reminder_time', 
        'timezone',
        'fitness_connected',
        'whoop_connected',
        'strava_connected',
        'apple_health_connected'
      ]

      const updates = Object.keys(req.body)
        .filter(key => allowedFields.includes(key))
        .reduce((obj, key) => {
          obj[key] = req.body[key]
          return obj
        }, {} as any)

      if (Object.keys(updates).length === 0) {
        return res.status(400).json({
          success: false,
          error: { error: 'No valid fields to update', message: 'Provide at least one valid field to update' }
        })
      }

      const updatedProfile = await DatabaseService.updateUserProfile(user.id, updates)

      const response: APIResponse = {
        success: true,
        data: updatedProfile,
        message: 'Profile updated successfully'
      }

      res.json(response)
    } catch (error) {
      console.error('Error updating user profile:', error)
      res.status(500).json({
        success: false,
        error: { error: 'Internal server error', message: error.message }
      })
    }
  }

  // Get user streaks
  static async getUserStreaks(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      if (!token) {
        return res.status(401).json({ error: 'Authorization token required' })
      }

      const user = await getUserFromToken(token)
      const streaks = await DatabaseService.getUserStreaks(user.id)

      const response: APIResponse = {
        success: true,
        data: streaks || []
      }

      res.json(response)
    } catch (error) {
      console.error('Error getting user streaks:', error)
      res.status(500).json({
        success: false,
        error: { error: 'Internal server error', message: error.message }
      })
    }
  }

  // Get AI insights
  static async getAIInsights(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      if (!token) {
        return res.status(401).json({ error: 'Authorization token required' })
      }

      const user = await getUserFromToken(token)
      const limit = Math.min(parseInt(req.query.limit as string) || 10, 50)
      const insightType = req.query.insight_type as string
      const unreadOnly = req.query.unread_only === 'true'

      let query = supabaseServiceClient
        .from('ai_insights')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false })
        .limit(limit)

      if (insightType) {
        query = query.eq('insight_type', insightType)
      }

      if (unreadOnly) {
        query = query.eq('is_read', false)
      }

      const { data, error } = await query

      if (error) throw error

      const response: APIResponse = {
        success: true,
        data: data || []
      }

      res.json(response)
    } catch (error) {
      console.error('Error getting AI insights:', error)
      res.status(500).json({
        success: false,
        error: { error: 'Internal server error', message: error.message }
      })
    }
  }

  // Mark AI insight as read
  static async markInsightAsRead(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      if (!token) {
        return res.status(401).json({ error: 'Authorization token required' })
      }

      const user = await getUserFromToken(token)
      const { insightId } = req.params

      if (!insightId) {
        return res.status(400).json({ 
          success: false, 
          error: { error: 'Bad request', message: 'Insight ID is required' }
        })
      }

      await DatabaseService.markInsightAsRead(insightId, user.id)

      const response: APIResponse = {
        success: true,
        message: 'Insight marked as read'
      }

      res.json(response)
    } catch (error) {
      console.error('Error marking insight as read:', error)
      res.status(500).json({
        success: false,
        error: { error: 'Internal server error', message: error.message }
      })
    }
  }

  // Generate weekly insights
  static async generateWeeklyInsights(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      if (!token) {
        return res.status(401).json({ error: 'Authorization token required' })
      }

      const user = await getUserFromToken(token)

      // Call the generate-insights Edge Function
      const insightResponse = await fetch(`${process.env.SUPABASE_URL}/functions/v1/generate-insights`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          insight_type: 'weekly'
        })
      })

      if (!insightResponse.ok) {
        throw new Error(`Insight generation failed: ${insightResponse.status}`)
      }

      const insightData = await insightResponse.json()

      const response: APIResponse = {
        success: true,
        data: insightData.insight,
        message: 'Weekly insights generated successfully'
      }

      res.json(response)
    } catch (error) {
      console.error('Error generating weekly insights:', error)
      res.status(500).json({
        success: false,
        error: { error: 'Internal server error', message: error.message }
      })
    }
  }
}
