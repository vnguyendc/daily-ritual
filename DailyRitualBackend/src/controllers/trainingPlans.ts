import { Request, Response } from 'express'
import { DatabaseService, getUserFromToken } from '../services/supabase.js'
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

      const plans = await DatabaseService.listTrainingPlans(user.id, date)
      const response: APIResponse = { success: true, data: plans }
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

      const { date, sequence, type, start_time, intensity, duration_minutes, notes } = req.body || {}
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

      const payload: TrainingPlanInsert = {
        user_id: user.id,
        date,
        sequence,
        type,
        start_time,
        intensity,
        duration_minutes,
        notes
      }
      const created = await DatabaseService.createTrainingPlan(user.id, payload)
      const response: APIResponse = { success: true, data: created }
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

      const updates: TrainingPlanUpdate = { ...req.body }
      const updated = await DatabaseService.updateTrainingPlanById(id, user.id, updates)
      const response: APIResponse = { success: true, data: updated }
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

      await DatabaseService.deleteTrainingPlanById(id, user.id)
      const response: APIResponse = { success: true, message: 'Training plan deleted successfully' }
      res.json(response)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      console.error('Error deleting training plan:', error)
      res.status(500).json({ success: false, error: { error: 'Internal server error', message } })
    }
  }
}


