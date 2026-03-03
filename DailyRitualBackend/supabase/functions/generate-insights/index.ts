// Supabase Edge Function for AI-powered insights generation
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type InsightType = 'morning' | 'evening' | 'weekly' | 'competition_prep' | 'pattern_analysis'
  | 'post_workout' | 'post_meal' | 'daily_nutrition' | 'weekly_comprehensive'

interface InsightRequest {
  insight_type: InsightType
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

      case 'post_workout': {
        // Get the current workout reflection + recent workouts + streaks
        const workoutId = requestData.context_data?.workout_reflection_id
        let currentReflection: any = null
        if (workoutId) {
          const { data } = await supabaseClient
            .from('workout_reflections')
            .select('*')
            .eq('id', workoutId)
            .single()
          currentReflection = data
        }

        const { data: recentWorkouts } = await supabaseClient
          .from('workout_reflections')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', { ascending: false })
          .limit(5)

        const { data: workoutStreaks } = await supabaseClient
          .from('user_streaks')
          .select('*')
          .eq('user_id', user.id)

        analysisData = { currentReflection, recentWorkouts, workoutStreaks }

        const currentType = currentReflection?.workout_type || 'workout'
        const currentFeeling = currentReflection?.training_feeling || 'N/A'
        const currentIntensity = currentReflection?.workout_intensity || 'N/A'
        const currentDuration = currentReflection?.duration_minutes || 'N/A'
        const wentWell = currentReflection?.what_went_well || ''
        const toImprove = currentReflection?.what_to_improve || ''
        const workoutStreak = workoutStreaks?.find((s: any) => s.streak_type === 'workout_reflection')?.current_streak || 0
        const recentTypes = recentWorkouts?.map((w: any) => w.workout_type).filter(Boolean).join(', ') || 'varied'

        contextPrompt = `Provide a brief post-workout insight for an athlete who just completed a session.

Workout type: ${currentType}
Feeling: ${currentFeeling}/5
Intensity: ${currentIntensity}
Duration: ${currentDuration} min
What went well: ${wentWell}
What to improve: ${toImprove}
Recent workout types: ${recentTypes}
Current workout streak: ${workoutStreak} days

Provide recovery tips, progression observations, or technique advice (30-50 words). Be specific to their workout type and feedback.`
        break
      }

      case 'post_meal': {
        // Get the current meal + daily totals so far
        const mealId = requestData.context_data?.meal_id
        let currentMeal: any = null
        if (mealId) {
          const { data } = await supabaseClient
            .from('meals')
            .select('*')
            .eq('id', mealId)
            .single()
          currentMeal = data
        }

        const mealDate = currentMeal?.date || endDate
        const { data: todayMeals } = await supabaseClient
          .from('meals')
          .select('*')
          .eq('user_id', user.id)
          .eq('date', mealDate)

        const { data: todayWorkouts } = await supabaseClient
          .from('workout_reflections')
          .select('workout_type, workout_intensity, duration_minutes')
          .eq('user_id', user.id)
          .eq('date', mealDate)

        analysisData = { currentMeal, todayMeals, todayWorkouts }

        const totalCalories = todayMeals?.reduce((sum: number, m: any) => sum + (m.user_calories || m.estimated_calories || 0), 0) || 0
        const totalProtein = todayMeals?.reduce((sum: number, m: any) => sum + parseFloat(m.user_protein_g || m.estimated_protein_g || 0), 0) || 0
        const mealCount = todayMeals?.length || 0
        const mealDescription = currentMeal?.food_description || 'meal'
        const hasWorkout = (todayWorkouts?.length || 0) > 0

        contextPrompt = `Provide a brief post-meal nutrition insight for an athlete.

Current meal: ${mealDescription} (${currentMeal?.estimated_calories || 'unknown'} cal)
Meals today so far: ${mealCount}
Daily calories so far: ${totalCalories}
Daily protein so far: ${totalProtein}g
Trained today: ${hasWorkout ? 'Yes' : 'No'}

Provide nutrition balance and timing advice relevant to athletic performance (25-40 words).`
        break
      }

      case 'daily_nutrition': {
        // Get all meals + workout data for the day
        const { data: dayMeals } = await supabaseClient
          .from('meals')
          .select('*')
          .eq('user_id', user.id)
          .eq('date', endDate)
          .order('created_at', { ascending: true })

        const { data: dayWorkouts } = await supabaseClient
          .from('workout_reflections')
          .select('*')
          .eq('user_id', user.id)
          .eq('date', endDate)

        analysisData = { dayMeals, dayWorkouts }

        const dayCalories = dayMeals?.reduce((sum: number, m: any) => sum + (m.user_calories || m.estimated_calories || 0), 0) || 0
        const dayProtein = dayMeals?.reduce((sum: number, m: any) => sum + parseFloat(m.user_protein_g || m.estimated_protein_g || 0), 0) || 0
        const dayCarbs = dayMeals?.reduce((sum: number, m: any) => sum + parseFloat(m.user_carbs_g || m.estimated_carbs_g || 0), 0) || 0
        const dayFat = dayMeals?.reduce((sum: number, m: any) => sum + parseFloat(m.user_fat_g || m.estimated_fat_g || 0), 0) || 0
        const dayMealTypes = dayMeals?.map((m: any) => m.meal_type).join(', ') || 'none'
        const workoutInfo = dayWorkouts?.map((w: any) => `${w.workout_type} (${w.workout_intensity}, ${w.duration_minutes}min)`).join('; ') || 'Rest day'

        contextPrompt = `Provide a daily nutrition assessment for an athlete.

Meals logged: ${dayMeals?.length || 0} (${dayMealTypes})
Total calories: ${dayCalories}
Macros: ${dayProtein}g protein, ${dayCarbs}g carbs, ${dayFat}g fat
Training today: ${workoutInfo}

Assess their daily nutrition balance. Note any gaps (missed meals, low protein, etc.) and provide 1-2 specific recommendations for tomorrow (40-60 words).`
        break
      }

      case 'weekly_comprehensive': {
        // Get all entries, workouts, meals, streaks for the week
        const weekStart = startDate
        const weekEnd = endDate

        const [weekEntries, weekWorkouts, weekMeals, weekStreaks] = await Promise.all([
          supabaseClient.from('daily_entries').select('*').eq('user_id', user.id)
            .gte('date', weekStart).lte('date', weekEnd).order('date', { ascending: false }),
          supabaseClient.from('workout_reflections').select('*').eq('user_id', user.id)
            .gte('date', weekStart).lte('date', weekEnd).order('date', { ascending: false }),
          supabaseClient.from('meals').select('*').eq('user_id', user.id)
            .gte('date', weekStart).lte('date', weekEnd).order('date', { ascending: true }),
          supabaseClient.from('user_streaks').select('*').eq('user_id', user.id)
        ])

        analysisData = {
          entries: weekEntries.data,
          workouts: weekWorkouts.data,
          meals: weekMeals.data,
          streaks: weekStreaks.data
        }

        const entries = weekEntries.data || []
        const workouts = weekWorkouts.data || []
        const meals = weekMeals.data || []

        const ritualCompletion = entries.length > 0
          ? Math.round((entries.filter((e: any) => e.morning_completed_at && e.evening_completed_at).length / entries.length) * 100)
          : 0
        const avgMood = entries.length > 0
          ? (entries.reduce((s: number, e: any) => s + (e.overall_mood || 0), 0) / entries.length).toFixed(1)
          : 'N/A'
        const avgFeeling = workouts.length > 0
          ? (workouts.reduce((s: number, w: any) => s + (w.training_feeling || 0), 0) / workouts.length).toFixed(1)
          : 'N/A'
        const weeklyCalories = meals.reduce((s: number, m: any) => s + (m.user_calories || m.estimated_calories || 0), 0)
        const morningStreak = weekStreaks.data?.find((s: any) => s.streak_type === 'morning_ritual')?.current_streak || 0

        contextPrompt = `Provide a comprehensive weekly review for an athlete covering fitness, nutrition, and mental health.

FITNESS:
- Workouts: ${workouts.length}
- Avg training feeling: ${avgFeeling}/5
- Types: ${[...new Set(workouts.map((w: any) => w.workout_type).filter(Boolean))].join(', ') || 'none'}

NUTRITION:
- Meals logged: ${meals.length}
- Weekly calories: ${weeklyCalories}
- Avg daily calories: ${meals.length > 0 ? Math.round(weeklyCalories / 7) : 'N/A'}

MENTAL HEALTH:
- Ritual completion: ${ritualCompletion}%
- Avg mood: ${avgMood}/5
- Morning streak: ${morningStreak} days
- Journal entries: ${entries.filter((e: any) => e.day_went_well || e.day_improve).length}

Provide a holistic weekly review with 2-3 key observations across all domains and 2-3 specific recommendations for next week (60-80 words).`
        break
      }

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
        max_tokens: insight_type === 'weekly_comprehensive' ? 400 : 200,
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

    // Generate a short summary (first sentence or first 100 chars)
    const summaryText = insightContent.split(/[.!?]/)[0]?.trim() || insightContent.substring(0, 100)

    // Store the insight in the database
    const { data: insertedInsight, error: insertError } = await supabaseClient
      .from('ai_insights')
      .insert({
        user_id: user.id,
        insight_type,
        content: insightContent,
        summary: summaryText,
        trigger_context: requestData.context_data || null,
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
