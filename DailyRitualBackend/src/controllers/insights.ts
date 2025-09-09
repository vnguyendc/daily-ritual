// AI Insights Controller
import { Request, Response } from 'express'
import { DatabaseService, getUserFromToken, supabaseServiceClient } from '../services/supabase.js'
import type { APIResponse } from '../types/api.js'

export class InsightsController {
  
  // Get AI insights with filtering and pagination
  static async getInsights(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      const useMock = process.env.USE_MOCK === 'true'
      const devUserId = process.env.DEV_USER_ID
      
      let user: any
      if (!token) {
        if (useMock) {
          user = { id: 'mock-user-id' }
        } else if (devUserId) {
          user = { id: devUserId }
        } else {
          return res.status(401).json({ error: 'Authorization token required' })
        }
      } else {
        user = await getUserFromToken(token)
      }

      // Parse query parameters
      const limit = Math.min(parseInt(req.query.limit as string) || 5, 50)
      const type = req.query.type as string // weekly|morning|evening|pattern_analysis|competition_prep
      const unreadOnly = req.query.unread_only === 'true'
      const startDate = req.query.start_date as string
      const endDate = req.query.end_date as string

      // Ensure user exists
      try {
        await DatabaseService.ensureUserRecord({ id: user.id, email: (user as any).email || null })
      } catch (e) {
        console.warn('ensureUserRecord failed:', e)
      }

      // For mock mode, return sample insights
      if (useMock) {
        const mockInsights = [
          {
            id: 'mock-insight-1',
            user_id: user.id,
            insight_type: 'weekly',
            content: 'This week you showed consistent dedication to your morning routine, completing 6 out of 7 days. Your gratitude themes centered around family and progress in training.',
            data_period_start: '2024-01-01',
            data_period_end: '2024-01-07',
            confidence_score: 0.85,
            is_read: false,
            created_at: new Date().toISOString()
          },
          {
            id: 'mock-insight-2',
            user_id: user.id,
            insight_type: 'morning',
            content: 'Your morning energy levels have been consistently high when you complete your gratitude practice before 8 AM.',
            data_period_start: '2024-01-07',
            data_period_end: '2024-01-07',
            confidence_score: 0.92,
            is_read: false,
            created_at: new Date(Date.now() - 86400000).toISOString() // Yesterday
          }
        ]

        let filteredInsights = mockInsights
        if (type) {
          filteredInsights = filteredInsights.filter(insight => insight.insight_type === type)
        }
        if (unreadOnly) {
          filteredInsights = filteredInsights.filter(insight => !insight.is_read)
        }

        console.log(`📝 Returning ${filteredInsights.length} mock insights for development`)
        const response: APIResponse = {
          success: true,
          data: filteredInsights.slice(0, limit)
        }
        return res.json(response)
      }

      // Build query for production
      let query = (supabaseServiceClient as any)
        .from('ai_insights')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false })
        .limit(limit)

      if (type) {
        query = query.eq('insight_type', type)
      }

      if (unreadOnly) {
        query = query.eq('is_read', false)
      }

      if (startDate) {
        query = query.gte('data_period_start', startDate)
      }

      if (endDate) {
        query = query.lte('data_period_end', endDate)
      }

      const { data, error } = await query

      if (error) throw error

      const response: APIResponse = {
        success: true,
        data: data || []
      }

      res.json(response)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      console.error('Error getting insights:', error)
      res.status(500).json({
        success: false,
        error: { error: 'Internal server error', message }
      })
    }
  }

  // Mark an insight as read
  static async markAsRead(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      const useMock = process.env.USE_MOCK === 'true'
      const devUserId = process.env.DEV_USER_ID
      
      let user: any
      if (!token) {
        if (useMock) {
          user = { id: 'mock-user-id' }
        } else if (devUserId) {
          user = { id: devUserId }
        } else {
          return res.status(401).json({ error: 'Authorization token required' })
        }
      } else {
        user = await getUserFromToken(token)
      }

      const insightId = req.params.id
      if (!insightId) {
        return res.status(400).json({ error: 'Insight ID required' })
      }

      // For mock mode, just return success
      if (useMock) {
        console.log(`📝 Mock: Marking insight ${insightId} as read for user ${user.id}`)
        return res.json({
          success: true,
          message: 'Insight marked as read (mock mode)'
        })
      }

      const { error } = await (supabaseServiceClient as any)
        .from('ai_insights')
        .update({ is_read: true })
        .eq('id', insightId)
        .eq('user_id', user.id)

      if (error) throw error

      const response: APIResponse = {
        success: true,
        message: 'Insight marked as read'
      }

      res.json(response)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      console.error('Error marking insight as read:', error)
      res.status(500).json({
        success: false,
        error: { error: 'Internal server error', message }
      })
    }
  }

  // Get insights statistics
  static async getInsightsStats(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      const useMock = process.env.USE_MOCK === 'true'
      const devUserId = process.env.DEV_USER_ID
      
      let user: any
      if (!token) {
        if (useMock) {
          user = { id: 'mock-user-id' }
        } else if (devUserId) {
          user = { id: devUserId }
        } else {
          return res.status(401).json({ error: 'Authorization token required' })
        }
      } else {
        user = await getUserFromToken(token)
      }

      // For mock mode, return sample stats
      if (useMock) {
        const mockStats = {
          total_insights: 12,
          unread_count: 3,
          insights_by_type: {
            weekly: 4,
            morning: 3,
            evening: 3,
            pattern_analysis: 2
          },
          latest_insight_date: new Date().toISOString()
        }

        console.log('📝 Returning mock insights stats for development')
        return res.json({
          success: true,
          data: mockStats
        })
      }

      // Get stats from database
      const [totalResult, unreadResult, typeStatsResult] = await Promise.all([
        (supabaseServiceClient as any)
          .from('ai_insights')
          .select('*', { count: 'exact', head: true })
          .eq('user_id', user.id),
        (supabaseServiceClient as any)
          .from('ai_insights')
          .select('*', { count: 'exact', head: true })
          .eq('user_id', user.id)
          .eq('is_read', false),
        (supabaseServiceClient as any)
          .from('ai_insights')
          .select('insight_type')
          .eq('user_id', user.id)
      ])

      if (totalResult.error) throw totalResult.error
      if (unreadResult.error) throw unreadResult.error
      if (typeStatsResult.error) throw typeStatsResult.error

      // Count insights by type
      const insightsByType = (typeStatsResult.data || []).reduce((acc: any, insight: any) => {
        acc[insight.insight_type] = (acc[insight.insight_type] || 0) + 1
        return acc
      }, {})

      const stats = {
        total_insights: totalResult.count || 0,
        unread_count: unreadResult.count || 0,
        insights_by_type: insightsByType,
        latest_insight_date: typeStatsResult.data?.[0]?.created_at || null
      }

      res.json({
        success: true,
        data: stats
      })
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      console.error('Error getting insights stats:', error)
      res.status(500).json({
        success: false,
        error: { error: 'Internal server error', message }
      })
    }
  }
}
