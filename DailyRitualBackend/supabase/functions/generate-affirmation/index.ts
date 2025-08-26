// Supabase Edge Function for AI-powered affirmation generation
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface AffirmationRequest {
  sport?: string
  recent_goals: string[]
  next_workout_type?: string
  recent_challenges: string[]
  recovery_data?: {
    recovery_score?: number
    strain_score?: number
    sleep_performance?: number
  }
  upcoming_competition?: {
    name: string
    days_until: number
    importance_level: number
  }
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
    const requestData: AffirmationRequest = await req.json()

    // Get user profile for sport context
    const { data: userProfile } = await supabaseClient
      .from('users')
      .select('primary_sport')
      .eq('id', user.id)
      .single()

    const sport = requestData.sport || userProfile?.primary_sport || 'general athletics'

    // Build context for AI generation
    let contextPrompt = `Generate a powerful, present-tense affirmation for a ${sport} athlete.`

    // Add recent goals context
    if (requestData.recent_goals.length > 0) {
      contextPrompt += `\n\nRecent goals: ${requestData.recent_goals.join(', ')}`
    }

    // Add workout context
    if (requestData.next_workout_type) {
      contextPrompt += `\nUpcoming training: ${requestData.next_workout_type}`
    }

    // Add recovery context
    if (requestData.recovery_data?.recovery_score) {
      const recovery = requestData.recovery_data.recovery_score
      if (recovery >= 80) {
        contextPrompt += `\nRecovery status: Excellent (${recovery}%) - ready for intensity`
      } else if (recovery >= 60) {
        contextPrompt += `\nRecovery status: Good (${recovery}%) - balanced approach`
      } else {
        contextPrompt += `\nRecovery status: Low (${recovery}%) - focus on patience and process`
      }
    }

    // Add competition context
    if (requestData.upcoming_competition) {
      const comp = requestData.upcoming_competition
      if (comp.days_until <= 7) {
        contextPrompt += `\nCompetition prep: ${comp.name} in ${comp.days_until} days - focus on confidence and trust`
      } else if (comp.days_until <= 30) {
        contextPrompt += `\nCompetition prep: ${comp.name} in ${comp.days_until} days - focus on preparation and building`
      }
    }

    // Add challenges context
    if (requestData.recent_challenges.length > 0) {
      contextPrompt += `\nRecent areas for improvement: ${requestData.recent_challenges.join(', ')}`
    }

    contextPrompt += `\n\nRequirements:
- 15-25 words maximum
- Present tense and confident
- Sport-specific language when possible
- Actionable and motivating
- Avoid generic platitudes
- Focus on process over outcome when recovery is low
- Focus on confidence and trust when competition is near

Generate only the affirmation text, no quotes or extra formatting.`

    // Call Claude API (or OpenAI) for generation
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
        max_tokens: 100,
        temperature: 0.7,
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
    const affirmation = claudeData.content[0].text.trim()

    // Store the generated affirmation for potential reuse
    await supabaseClient
      .from('ai_insights')
      .insert({
        user_id: user.id,
        insight_type: 'morning',
        content: `Generated affirmation: "${affirmation}"`,
        confidence_score: 0.8,
        is_read: true
      })

    return new Response(
      JSON.stringify({ 
        success: true,
        affirmation,
        context_used: {
          sport,
          recovery_informed: !!requestData.recovery_data?.recovery_score,
          competition_prep: !!requestData.upcoming_competition
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
    console.error('Error generating affirmation:', error)
    
    return new Response(
      JSON.stringify({ 
        error: 'Failed to generate affirmation',
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
