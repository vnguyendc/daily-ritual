// Streaks Controller
import { Request, Response } from 'express'
import { DatabaseService, supabaseServiceClient } from '../services/supabase.js'

export class StreaksController {

  // GET /streaks/current - Returns current streak stats for authenticated user
  static async getCurrentStreaks(req: Request, res: Response) {
    try {
      const user: any = (req as any).user
      if (!user?.id) {
        return res.status(401).json({ error: 'Unauthorized' })
      }

      const streaks = await DatabaseService.getUserStreaks(user.id)

      return res.json({
        streaks: streaks || [],
        lastUpdated: new Date().toISOString()
      })
    } catch (error) {
      console.error('Error fetching streaks:', error)
      return res.status(500).json({ error: 'Failed to fetch streaks' })
    }
  }

  // GET /streaks/history?start=YYYY-MM-DD&end=YYYY-MM-DD - Returns completion history
  static async getCompletionHistory(req: Request, res: Response) {
    try {
      const user: any = (req as any).user
      if (!user?.id) {
        return res.status(401).json({ error: 'Unauthorized' })
      }

      const { start, end } = req.query
      if (!start || !end) {
        return res.status(400).json({ error: 'start and end query parameters are required (YYYY-MM-DD)' })
      }

      const startDate = String(start)
      const endDate = String(end)

      // Validate date format
      const dateRegex = /^\d{4}-\d{2}-\d{2}$/
      if (!dateRegex.test(startDate) || !dateRegex.test(endDate)) {
        return res.status(400).json({ error: 'Dates must be in YYYY-MM-DD format' })
      }

      const history = await DatabaseService.getCompletionHistory(user.id, startDate, endDate)

      return res.json({
        history: history || []
      })
    } catch (error) {
      console.error('Error fetching completion history:', error)
      return res.status(500).json({ error: 'Failed to fetch completion history' })
    }
  }
}
