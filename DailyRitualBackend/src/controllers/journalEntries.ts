import { Request, Response } from 'express'
import { supabaseServiceClient } from '../services/supabase.js'
import { ok, fail, PaginatedResponse, JournalEntry } from '../types/api.js'

export const JournalController = {
  // Get all journal entries for a user (paginated)
  async getJournalEntries(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user?.id
      if (!userId) {
        res.status(401).json(fail('Unauthorized'))
        return
      }

      const page = parseInt(req.query.page as string) || 1
      const limit = Math.min(parseInt(req.query.limit as string) || 20, 50)
      const offset = (page - 1) * limit

      // Count total
      const { count, error: countError } = await (supabaseServiceClient as any)
        .from('journal_entries')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', userId)

      if (countError) throw countError

      // Fetch entries
      const { data: entries, error } = await (supabaseServiceClient as any)
        .from('journal_entries')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .range(offset, offset + limit - 1)

      if (error) throw error

      const total = count || 0
      const totalPages = Math.ceil(total / limit)

      const response: PaginatedResponse<JournalEntry> = {
        data: (entries || []) as JournalEntry[],
        pagination: {
          page,
          limit,
          total,
          total_pages: totalPages,
          has_next: page < totalPages,
          has_prev: page > 1
        }
      }

      res.json(ok(response))
    } catch (error: any) {
      console.error('Error fetching journal entries:', error.message, error.stack)
      res.status(500).json(fail(error.message || 'Failed to fetch journal entries'))
    }
  },

  // Get a single journal entry
  async getJournalEntry(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user?.id
      const { id } = req.params

      if (!userId) {
        res.status(401).json(fail('Unauthorized'))
        return
      }

      const { data: entry, error } = await (supabaseServiceClient as any)
        .from('journal_entries')
        .select('*')
        .eq('id', id)
        .eq('user_id', userId)
        .single()

      if (error) {
        if (error.code === 'PGRST116') {
          res.status(404).json(fail('Journal entry not found'))
          return
        }
        throw error
      }

      res.json(ok(entry))
    } catch (error: any) {
      console.error('Error fetching journal entry:', error.message, error.stack)
      res.status(500).json(fail(error.message || 'Failed to fetch journal entry'))
    }
  },

  // Create a new journal entry
  async createJournalEntry(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user?.id
      if (!userId) {
        res.status(401).json(fail('Unauthorized'))
        return
      }

      const { title, content, mood, energy, tags } = req.body

      if (!content || content.trim() === '') {
        res.status(400).json(fail('Content is required'))
        return
      }

      const insertData = {
        user_id: userId,
        title: title || null,
        content: content.trim(),
        mood: mood ?? null,
        energy: energy ?? null,
        tags: tags || null,
        is_private: true
      }

      const { data: entry, error } = await (supabaseServiceClient as any)
        .from('journal_entries')
        .insert(insertData)
        .select()
        .single()

      if (error) throw error

      res.status(201).json(ok(entry, 'Journal entry created'))
    } catch (error: any) {
      console.error('Error creating journal entry:', error.message, error.stack)
      res.status(500).json(fail(error.message || 'Failed to create journal entry'))
    }
  },

  // Update a journal entry
  async updateJournalEntry(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user?.id
      const { id } = req.params

      if (!userId) {
        res.status(401).json(fail('Unauthorized'))
        return
      }

      const { title, content, mood, energy, tags } = req.body

      const updateData: Record<string, any> = {}
      if (title !== undefined) updateData.title = title
      if (content !== undefined) updateData.content = content
      if (mood !== undefined) updateData.mood = mood
      if (energy !== undefined) updateData.energy = energy
      if (tags !== undefined) updateData.tags = tags

      const { data: entry, error } = await (supabaseServiceClient as any)
        .from('journal_entries')
        .update(updateData)
        .eq('id', id)
        .eq('user_id', userId)
        .select()
        .single()

      if (error) {
        if (error.code === 'PGRST116') {
          res.status(404).json(fail('Journal entry not found'))
          return
        }
        throw error
      }

      res.json(ok(entry, 'Journal entry updated'))
    } catch (error: any) {
      console.error('Error updating journal entry:', error.message, error.stack)
      res.status(500).json(fail(error.message || 'Failed to update journal entry'))
    }
  },

  // Delete a journal entry
  async deleteJournalEntry(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user?.id
      const { id } = req.params

      if (!userId) {
        res.status(401).json(fail('Unauthorized'))
        return
      }

      const { error } = await (supabaseServiceClient as any)
        .from('journal_entries')
        .delete()
        .eq('id', id)
        .eq('user_id', userId)

      if (error) throw error

      res.json(ok(null, 'Journal entry deleted'))
    } catch (error: any) {
      console.error('Error deleting journal entry:', error.message, error.stack)
      res.status(500).json(fail(error.message || 'Failed to delete journal entry'))
    }
  }
}
