// Daily Entries Controller
import { Request, Response } from 'express'
import { z } from 'zod'
import { DatabaseService, getUserFromToken, supabaseServiceClient } from '../services/supabase.js'
import type { MorningRitualRequest, EveningReflectionRequest, APIResponse } from '../types/api.js'

// Validation schemas
const morningRitualSchema = z.object({
  goals: z.array(z.string().min(1).max(200)).min(1).max(3),
  gratitudes: z.array(z.string().min(1).max(200)).min(1).max(3),
  quote_reflection: z.string().max(500).optional(),
  planned_training_type: z.enum(['strength', 'cardio', 'skills', 'competition', 'rest', 'cross_training', 'recovery']).optional(),
  planned_training_time: z.string().optional(),
  planned_intensity: z.enum(['light', 'moderate', 'hard', 'very_hard']).optional(),
  planned_duration: z.number().min(5).max(600).optional(),
  planned_notes: z.string().max(2000).optional()
})

const eveningReflectionSchema = z.object({
  quote_application: z.string().min(1).max(1000),
  day_went_well: z.string().min(1).max(1000),
  day_improve: z.string().min(1).max(1000),
  overall_mood: z.number().min(1).max(5)
})

export class DailyEntriesController {
  
  // Get daily entry for a specific date
  static async getDailyEntry(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      const useMock = process.env.USE_MOCK === 'true'
      const devUserId = process.env.DEV_USER_ID
      
      let user: any = (req as any).user
      if (!user) {
        if (!token) {
          if (useMock) {
            console.log('🔓 No auth token provided, using mock user for development')
            user = { id: 'mock-user-id' }
          } else if (devUserId) {
            console.log('👤 Using DEV_USER_ID from environment for development without auth')
            user = { id: devUserId }
          } else {
            return res.status(401).json({ error: 'Authorization token required' })
          }
        } else {
          user = await getUserFromToken(token)
        }
      }
      const date = req.params.date as string

      // Ensure user exists in public.users for FK
      try {
        await DatabaseService.ensureUserRecord({ id: user.id, email: (user as any).email || null })
      } catch (e) {
        console.warn('ensureUserRecord failed:', e)
      }

      // Validate date format
      if (!date.match(/^\d{4}-\d{2}-\d{2}$/)) {
        return res.status(400).json({ error: 'Invalid date format. Use YYYY-MM-DD' })
      }

      const entry = await DatabaseService.getDailyEntry(user.id, date)
      
      const response: APIResponse = {
        success: true,
        data: entry || null
      }

      res.json(response)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      console.error('Error getting daily entry:', error)
      res.status(500).json({
        success: false,
        error: { error: 'Internal server error', message }
      })
    }
  }

  // Get daily entry + training plans for a date
  static async getDailyEntryWithPlans(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      const useMock = process.env.USE_MOCK === 'true'
      const devUserId = process.env.DEV_USER_ID
      
      let user: any = (req as any).user
      if (!user) {
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
      }
      const date = req.params.date as string
      if (!date.match(/^\d{4}-\d{2}-\d{2}$/)) {
        return res.status(400).json({ error: 'Invalid date format. Use YYYY-MM-DD' })
      }

      try {
        await DatabaseService.ensureUserRecord({ id: user.id, email: (user as any).email || null })
      } catch (e) {
        console.warn('ensureUserRecord failed:', e)
      }

      const entry = await DatabaseService.getDailyEntry(user.id, date)
      const plans = await DatabaseService.listTrainingPlans(user.id, date)

      const response: APIResponse = {
        success: true,
        data: {
          daily_entry: entry || null,
          training_plans: plans || []
        }
      }
      res.json(response)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      console.error('Error getting daily entry with plans:', error)
      res.status(500).json({ success: false, error: { error: 'Internal server error', message } })
    }
  }
  // Get only the daily quote for a specific date
  static async getDailyQuote(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      const useMock = process.env.USE_MOCK === 'true'
      const devUserId = process.env.DEV_USER_ID
      
      let user: any = (req as any).user
      if (!user) {
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
      }
      const date = req.params.date as string
      if (!date.match(/^\d{4}-\d{2}-\d{2}$/)) {
        return res.status(400).json({ error: 'Invalid date format. Use YYYY-MM-DD' })
      }

      // Ensure user exists
      try {
        await DatabaseService.ensureUserRecord({ id: user.id, email: (user as any).email || null })
      } catch (e) {
        console.warn('ensureUserRecord failed:', e)
      }

      const dailyQuote = await DatabaseService.getDailyQuote(user.id, date)
      const response: APIResponse = { success: true, data: dailyQuote }
      res.json(response)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      console.error('Error getting daily quote:', error)
      res.status(500).json({ success: false, error: { error: 'Internal server error', message } })
    }
  }

  // Complete morning ritual
  static async completeMorningRitual(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      const useMock = process.env.USE_MOCK === 'true'
      const devUserId = process.env.DEV_USER_ID
      
      let user: any = (req as any).user
      if (!user) {
        if (!token) {
          if (useMock) {
            console.log('🔓 No auth token provided, using mock user for development')
            user = { id: 'mock-user-id' }
          } else if (devUserId) {
            console.log('👤 Using DEV_USER_ID from environment for development without auth')
            user = { id: devUserId }
          } else {
            return res.status(401).json({ error: 'Authorization token required' })
          }
        } else {
          user = await getUserFromToken(token)
        }
      }
      const date = req.params.date as string

      // Validate date format
      if (!date.match(/^\d{4}-\d{2}-\d{2}$/)) {
        return res.status(400).json({ error: 'Invalid date format. Use YYYY-MM-DD' })
      }

      // Validate request body
      const validationResult = morningRitualSchema.safeParse(req.body)
      if (!validationResult.success) {
        return res.status(400).json({
          error: 'Validation failed',
          details: validationResult.error.errors
        })
      }

      const morningData: Partial<MorningRitualRequest> = validationResult.data as Partial<MorningRitualRequest>

      // Ensure user exists in public.users for FK
      try {
        await DatabaseService.ensureUserRecord({ id: user.id, email: (user as any).email || null })
      } catch (e) {
        console.warn('ensureUserRecord failed:', e)
      }

      // Get daily quote for the user
      const dailyQuote = await DatabaseService.getDailyQuote(user.id, date)

      // Generate AI affirmation
      let affirmation = "I am prepared, focused, and ready to give my best effort today."
      try {
        // Call the generate-affirmation Edge Function
        const affirmationResponse = await fetch(`${process.env.SUPABASE_URL}/functions/v1/generate-affirmation`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            recent_goals: morningData.goals,
            next_workout_type: morningData.planned_training_type
          })
        })

        if (affirmationResponse.ok) {
          const affirmationData = await affirmationResponse.json()
          affirmation = affirmationData.affirmation || affirmation
        }
      } catch (error) {
        console.warn('Failed to generate AI affirmation, using default:', error)
      }

      // Update daily entry
      const entry = await DatabaseService.createOrUpdateDailyEntry(user.id, date, {
        goals: morningData.goals,
        gratitudes: morningData.gratitudes,
        affirmation,
        daily_quote: dailyQuote?.quote_text || null,
        quote_reflection: morningData.quote_reflection,
        planned_training_type: morningData.planned_training_type,
        planned_training_time: morningData.planned_training_time,
        planned_intensity: morningData.planned_intensity,
        planned_duration: morningData.planned_duration,
        planned_notes: morningData.planned_notes,
        morning_completed_at: new Date().toISOString()
      })

      // Update streak
      await DatabaseService.updateUserStreak(user.id, 'morning_ritual', date)

      // Generate morning insight
      try {
        await fetch(`${process.env.SUPABASE_URL}/functions/v1/generate-insights`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            insight_type: 'morning',
            data_period_end: date
          })
        })
      } catch (error) {
        console.warn('Failed to generate morning insight:', error)
      }

      const response: APIResponse = {
        success: true,
        data: {
          daily_entry: entry,
          affirmation,
          daily_quote: dailyQuote
        },
        message: 'Morning ritual completed successfully'
      }

      res.json(response)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      console.error('Error completing morning ritual:', error)
      res.status(500).json({
        success: false,
        error: { error: 'Internal server error', message }
      })
    }
  }

  // Complete evening reflection
  static async completeEveningReflection(req: Request, res: Response) {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '')
      const useMock = process.env.USE_MOCK === 'true'
      const devUserId = process.env.DEV_USER_ID
      
      let user: any = (req as any).user
      if (!user) {
        if (!token) {
          if (useMock) {
            console.log('🔓 No auth token provided, using mock user for development')
            user = { id: 'mock-user-id' }
          } else if (devUserId) {
            console.log('👤 Using DEV_USER_ID from environment for development without auth')
            user = { id: devUserId }
          } else {
            return res.status(401).json({ error: 'Authorization token required' })
          }
        } else {
          user = await getUserFromToken(token)
        }
      }
      const date = req.params.date as string

      // Ensure user exists in public.users for FK
      try {
        await DatabaseService.ensureUserRecord({ id: user.id, email: (user as any).email || null })
      } catch (e) {
        console.warn('ensureUserRecord failed:', e)
      }

      // Validate date format
      if (!date.match(/^\d{4}-\d{2}-\d{2}$/)) {
        return res.status(400).json({ error: 'Invalid date format. Use YYYY-MM-DD' })
      }

      // Validate request body
      const validationResult = eveningReflectionSchema.safeParse(req.body)
      if (!validationResult.success) {
        return res.status(400).json({
          error: 'Validation failed',
          details: validationResult.error.errors
        })
      }

      const eveningData: EveningReflectionRequest = validationResult.data

      // Update daily entry
      const entry = await DatabaseService.createOrUpdateDailyEntry(user.id, date, {
        quote_application: eveningData.quote_application,
        day_went_well: eveningData.day_went_well,
        day_improve: eveningData.day_improve,
        overall_mood: eveningData.overall_mood,
        evening_completed_at: new Date().toISOString()
      })

      // Update streaks
      await DatabaseService.updateUserStreak(user.id, 'evening_reflection', date)
      
      // Check if daily is complete (both morning and evening)
      if (entry.morning_completed_at && entry.evening_completed_at) {
        await DatabaseService.updateUserStreak(user.id, 'daily_complete', date)
      }

      // Generate evening insight
      try {
        await fetch(`${process.env.SUPABASE_URL}/functions/v1/generate-insights`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            insight_type: 'evening',
            data_period_end: date
          })
        })
      } catch (error) {
        console.warn('Failed to generate evening insight:', error)
      }

      const response: APIResponse = {
        success: true,
        data: entry,
        message: 'Evening reflection completed successfully'
      }

      res.json(response)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      console.error('Error completing evening reflection:', error)
      res.status(500).json({
        success: false,
        error: { error: 'Internal server error', message }
      })
    }
  }

  // Get daily entries with pagination and filtering
  static async getDailyEntries(req: Request, res: Response) {
    try {
      let user: any = (req as any).user
      if (!user) {
        const token = req.headers.authorization?.replace('Bearer ', '')
        if (!token) {
          return res.status(401).json({ error: 'Authorization token required' })
        }
        user = await getUserFromToken(token)
      }
      
      // Parse query parameters
      const page = parseInt(req.query.page as string) || 1
      const limit = Math.min(parseInt(req.query.limit as string) || 10, 50)
      const startDate = req.query.start_date as string
      const endDate = req.query.end_date as string
      const hasMorningRitual = req.query.has_morning_ritual === 'true'
      const hasEveningReflection = req.query.has_evening_reflection === 'true'

      // Build query
      let query = supabaseServiceClient
        .from('daily_entries')
        .select('*', { count: 'exact' })
        .eq('user_id', user.id)
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

      // Apply pagination
      const offset = (page - 1) * limit
      query = query.range(offset, offset + limit - 1)

      const { data, error, count } = await query

      if (error) throw error

      const totalPages = Math.ceil((count || 0) / limit)

      const response: APIResponse = {
        success: true,
        data: {
          data: data || [],
          pagination: {
            page,
            limit,
            total: count || 0,
            total_pages: totalPages,
            has_next: page < totalPages,
            has_prev: page > 1
          }
        }
      }

      res.json(response)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      console.error('Error getting daily entries:', error)
      res.status(500).json({
        success: false,
        error: { error: 'Internal server error', message }
      })
    }
  }

  // Delete a daily entry
  static async deleteDailyEntry(req: Request, res: Response) {
    try {
      let user: any = (req as any).user
      if (!user) {
        const token = req.headers.authorization?.replace('Bearer ', '')
        if (!token) {
          return res.status(401).json({ error: 'Authorization token required' })
        }
        user = await getUserFromToken(token)
      }
      const date = req.params.date as string

      // Validate date format
      if (!date.match(/^\d{4}-\d{2}-\d{2}$/)) {
        return res.status(400).json({ error: 'Invalid date format. Use YYYY-MM-DD' })
      }

      const { error } = await supabaseServiceClient
        .from('daily_entries')
        .delete()
        .eq('user_id', user.id)
        .eq('date', date)

      if (error) throw error

      const response: APIResponse = {
        success: true,
        message: 'Daily entry deleted successfully'
      }

      res.json(response)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      console.error('Error deleting daily entry:', error)
      res.status(500).json({
        success: false,
        error: { error: 'Internal server error', message }
      })
    }
  }
}
