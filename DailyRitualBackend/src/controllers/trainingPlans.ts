import { Request, Response } from 'express'
import { DatabaseService, getUserFromToken, supabaseServiceClient } from '../services/supabase.js'
import type { APIResponse } from '../types/api.js'
import type { Database } from '../types/database.js'

type TrainingPlanInsert = Database['public']['Tables']['training_plans']['Insert']
type TrainingPlanUpdate = Database['public']['Tables']['training_plans']['Update']

export class TrainingPlansController {
  static async list(req: Request, res: Response) {
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

      const date = req.query.date as string
      if (!date || !date.match(/^\d{4}-\d{2}-\d{2}$/)) {
        return res.status(400).json({ error: 'date query param (YYYY-MM-DD) required' })
      }

      // Ensure user exists
      try {
        await DatabaseService.ensureUserRecord({ id: user.id, email: (user as any).email || null })
      } catch (e) {
        console.warn('ensureUserRecord failed:', e)
      }

      const { data, error } = await (supabaseServiceClient as any)
        .from('training_plans')
        .select('*')
        .eq('user_id', user.id)
        .eq('date', date)
        .order('sequence', { ascending: true })

      if (error) throw error
      const response: APIResponse = { success: true, data: data || [] }
      res.json(response)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      console.error('Error listing training plans:', error)
      res.status(500).json({ success: false, error: { error: 'Internal server error', message } })
    }
  }

  static async create(req: Request, res: Response) {
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

      const { date, sequence = 1, type, start_time, intensity, duration_minutes, notes } = req.body || {}
      if (!date || !date.match(/^\d{4}-\d{2}-\d{2}$/)) {
        return res.status(400).json({ error: 'date (YYYY-MM-DD) required' })
      }

      if (!type) {
        return res.status(400).json({ error: 'type is required' })
      }

      // Ensure user exists
      try {
        await DatabaseService.ensureUserRecord({ id: user.id, email: (user as any).email || null })
      } catch (e) {
        console.warn('ensureUserRecord failed:', e)
      }

      const insertData: TrainingPlanInsert = {
        user_id: user.id,
        date,
        sequence,
        type,
        start_time,
        intensity,
        duration_minutes,
        notes
      }

      const { data, error } = await (supabaseServiceClient as any)
        .from('training_plans')
        .insert(insertData)
        .select()
        .single()

      if (error) throw error
      const response: APIResponse = { success: true, data }
      res.json(response)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      console.error('Error creating training plan:', error)
      res.status(500).json({ success: false, error: { error: 'Internal server error', message } })
    }
  }

  static async update(req: Request, res: Response) {
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

      const id = req.params.id
      if (!id) {
        return res.status(400).json({ error: 'Training plan ID required' })
      }

      const updates: TrainingPlanUpdate = { 
        ...req.body, 
        updated_at: new Date().toISOString() 
      }

      const { data, error } = await (supabaseServiceClient as any)
        .from('training_plans')
        .update(updates)
        .eq('id', id)
        .eq('user_id', user.id)
        .select()
        .single()

      if (error) throw error
      const response: APIResponse = { success: true, data }
      res.json(response)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      console.error('Error updating training plan:', error)
      res.status(500).json({ success: false, error: { error: 'Internal server error', message } })
    }
  }

  static async remove(req: Request, res: Response) {
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

      const id = req.params.id
      if (!id) {
        return res.status(400).json({ error: 'Training plan ID required' })
      }

      const { error } = await (supabaseServiceClient as any)
        .from('training_plans')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id)

      if (error) throw error
      const response: APIResponse = { success: true, message: 'Training plan deleted successfully' }
      res.json(response)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      console.error('Error deleting training plan:', error)
      res.status(500).json({ success: false, error: { error: 'Internal server error', message } })
    }
  }
}


