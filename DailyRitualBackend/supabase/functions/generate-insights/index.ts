// Supabase Edge Function for AI-powered insights generation
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface InsightRequest {
  insight_type: 'morning' | 'evening' | 'weekly' | 'competition_prep' | 'pattern_analysis'
  data_period_start?: string
  data_period_end?: string
  context_data?: Record<string, any>
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get user from JWT token
    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user } } = await supabaseClient.auth.getUser(token)

    if (!user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const requestData: InsightRequest = await req.json()
    const { insight_type, data_period_start, data_period_end } = requestData

    // Set default date range if not provided
    const endDate = data_period_end || new Date().toISOString().split('T')[0]
    const startDate = data_period_start || 
      new Date(Date.now() - (insight_type === 'weekly' ? 7 : 30) * 24 * 60 * 60 * 1000)
        .toISOString().split('T')[0]

    // Gather relevant data based on insight type
    let analysisData: any = {}
    let contextPrompt = ''

    switch (insight_type) {
      case 'morning':
        // Get today's data for morning insight
        const { data: todayEntry } = await supabaseClient
          .from('daily_entries')
          .select('*')
          .eq('user_id', user.id)
          .eq('date', endDate)
          .single()

        const { data: recentEntries } = await supabaseClient
          .from('daily_entries')
          .select('goals, overall_mood, morning_completed_at')
          .eq('user_id', user.id)
          .gte('date', startDate)
          .lt('date', endDate)
          .order('date', { ascending: false })
          .limit(7)

        analysisData = { todayEntry, recentEntries }
        
        contextPrompt = `Provide a brief morning insight for an athlete based on their recent patterns and today's goals.

Today's goals: ${todayEntry?.goals?.join(', ') || 'None set yet'}
Recent mood average: ${recentEntries?.reduce((sum, e) => sum + (e.overall_mood || 0), 0) / (recentEntries?.length || 1)}
Consistency: ${recentEntries?.filter(e => e.morning_completed_at).length}/${recentEntries?.length || 0} mornings completed

Provide a supportive, actionable insight (20-30 words) that helps them approach today with the right mindset.`
        break

      case 'evening':
        // Get recent daily entries and workout reflections
        const { data: dailyEntries } = await supabaseClient
          .from('daily_entries')
          .select('*')
          .eq('user_id', user.id)
          .gte('date', startDate)
          .lte('date', endDate)
          .order('date', { ascending: false })

        const { data: workoutReflections } = await supabaseClient
          .from('workout_reflections')
          .select('*')
          .eq('user_id', user.id)
          .gte('date', startDate)
          .lte('date', endDate)
          .order('date', { ascending: false })

        analysisData = { dailyEntries, workoutReflections }

        const completedGoals = dailyEntries?.reduce((sum, e) => sum + (e.goals?.length || 0), 0)
        const avgMood = dailyEntries?.reduce((sum, e) => sum + (e.overall_mood || 0), 0) / (dailyEntries?.length || 1)
        const avgTrainingFeeling = workoutReflections?.reduce((sum, w) => sum + (w.training_feeling || 0), 0) / (workoutReflections?.length || 1)

        contextPrompt = `Provide an encouraging evening insight for an athlete based on their recent week.

Goals completed: ${completedGoals || 0}
Average mood: ${avgMood.toFixed(1)}/5
Average training satisfaction: ${avgTrainingFeeling.toFixed(1)}/5
Days with complete entries: ${dailyEntries?.filter(e => e.morning_completed_at && e.evening_completed_at).length}/${dailyEntries?.length || 0}

Provide a reflective insight (25-35 words) that acknowledges progress and suggests one area for tomorrow.`
        break

      case 'weekly':
        // Get comprehensive week data
        const { data: weeklyDailyEntries } = await supabaseClient
          .from('daily_entries')
          .select('*')
          .eq('user_id', user.id)
          .gte('date', startDate)
          .lte('date', endDate)
          .order('date', { ascending: false })

        const { data: weeklyWorkouts } = await supabaseClient
          .from('workout_reflections')
          .select('*')
          .eq('user_id', user.id)
          .gte('date', startDate)
          .lte('date', endDate)
          .order('date', { ascending: false })

        const { data: streaks } = await supabaseClient
          .from('user_streaks')
          .select('*')
          .eq('user_id', user.id)

        analysisData = { weeklyDailyEntries, weeklyWorkouts, streaks }

        const goalCompletionRate = weeklyDailyEntries?.length > 0 ? 
          (weeklyDailyEntries.filter(e => e.goals?.length > 0).length / weeklyDailyEntries.length) * 100 : 0
        const avgWeeklyMood = weeklyDailyEntries?.reduce((sum, e) => sum + (e.overall_mood || 0), 0) / (weeklyDailyEntries?.length || 1)
        const morningStreak = streaks?.find(s => s.streak_type === 'morning_ritual')?.current_streak || 0

        contextPrompt = `Provide a comprehensive weekly insight for an athlete based on their performance patterns.

Goal completion rate: ${goalCompletionRate.toFixed(0)}%
Average mood: ${avgWeeklyMood.toFixed(1)}/5
Morning ritual streak: ${morningStreak} days
Workouts reflected on: ${weeklyWorkouts?.length || 0}

Identify 2-3 key patterns and provide 1-2 actionable recommendations for next week (50-70 words).`
        break

      case 'competition_prep':
        // Get competition prep data
        const competitionId = requestData.context_data?.competition_id
        if (!competitionId) {
          throw new Error('Competition ID required for competition prep insights')
        }

        const { data: competition } = await supabaseClient
          .from('competitions')
          .select('*')
          .eq('id', competitionId)
          .single()

        const { data: prepEntries } = await supabaseClient
          .from('competition_prep_entries')
          .select('*')
          .eq('user_id', user.id)
          .eq('competition_id', competitionId)
          .order('date', { ascending: false })

        analysisData = { competition, prepEntries }

        const daysUntil = Math.ceil((new Date(competition.competition_date).getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24))
        const avgConfidence = prepEntries?.reduce((sum, p) => sum + (p.confidence_level || 0), 0) / (prepEntries?.length || 1)
        const avgAnxiety = prepEntries?.reduce((sum, p) => sum + (p.anxiety_level || 0), 0) / (prepEntries?.length || 1)

        contextPrompt = `Provide competition preparation insight for an athlete.

Competition: ${competition.name}
Days until competition: ${daysUntil}
Average confidence: ${avgConfidence.toFixed(1)}/5
Average anxiety: ${avgAnxiety.toFixed(1)}/5
Prep entries: ${prepEntries?.length || 0}

Provide mental preparation guidance (30-50 words) focusing on confidence optimization and anxiety management.`
        break

      default:
        throw new Error(`Unsupported insight type: ${insight_type}`)
    }

    // Call Claude API for insight generation
    const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY')
    
    if (!anthropicApiKey) {
      throw new Error('ANTHROPIC_API_KEY not configured')
    }

    const claudeResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': anthropicApiKey,
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify({
        model: 'claude-3-haiku-20240307',
        max_tokens: 200,
        temperature: 0.6,
        messages: [{
          role: 'user',
          content: contextPrompt
        }]
      })
    })

    if (!claudeResponse.ok) {
      throw new Error(`Claude API error: ${claudeResponse.status}`)
    }

    const claudeData = await claudeResponse.json()
    const insightContent = claudeData.content[0].text.trim()

    // Store the insight in the database
    const { data: insertedInsight, error: insertError } = await supabaseClient
      .from('ai_insights')
      .insert({
        user_id: user.id,
        insight_type,
        content: insightContent,
        data_period_start: startDate,
        data_period_end: endDate,
        confidence_score: 0.85,
        is_read: false
      })
      .select()
      .single()

    if (insertError) {
      throw insertError
    }

    return new Response(
      JSON.stringify({ 
        success: true,
        insight: insertedInsight,
        analysis_summary: {
          data_points: Object.keys(analysisData).length,
          period: `${startDate} to ${endDate}`,
          insight_type
        }
      }),
      { 
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        } 
      }
    )

  } catch (error) {
    console.error('Error generating insight:', error)
    
    return new Response(
      JSON.stringify({ 
        error: 'Failed to generate insight',
        message: error.message 
      }),
      { 
        status: 500, 
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        } 
      }
    )
  }
})
