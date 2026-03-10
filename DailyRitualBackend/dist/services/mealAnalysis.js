const ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY;
const MEAL_ANALYSIS_PROMPT = `You are a nutrition analysis expert. Analyze this meal photo and estimate the nutritional content.

Return ONLY valid JSON with no additional text, in this exact format:
{
  "food_description": "Brief description of the food items visible",
  "estimated_calories": 500,
  "estimated_protein_g": 30,
  "estimated_carbs_g": 50,
  "estimated_fat_g": 15,
  "estimated_fiber_g": 5,
  "ai_confidence": 0.8
}

Guidelines:
- food_description: List the main food items you can identify (max 100 chars)
- estimated_calories: Total estimated calories (integer)
- estimated_protein_g, estimated_carbs_g, estimated_fat_g, estimated_fiber_g: Grams as numbers
- ai_confidence: 0.0-1.0 reflecting how confident you are (0.9+ if food is clearly visible, 0.5-0.7 if partially obscured, <0.5 if very unclear)
- Estimate portion sizes based on plate/container size visible in the image
- If you cannot identify the food at all, return ai_confidence of 0.2 and your best guess`;
export async function analyzeMealPhoto(imageBase64, mimeType = 'image/jpeg') {
    if (!ANTHROPIC_API_KEY) {
        throw new Error('ANTHROPIC_API_KEY not configured');
    }
    const mediaType = mimeType === 'image/png' ? 'image/png'
        : mimeType === 'image/heic' || mimeType === 'image/heif' ? 'image/jpeg'
            : 'image/jpeg';
    const response = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'x-api-key': ANTHROPIC_API_KEY,
            'anthropic-version': '2023-06-01'
        },
        body: JSON.stringify({
            model: 'claude-sonnet-4-20250514',
            max_tokens: 300,
            messages: [{
                    role: 'user',
                    content: [
                        {
                            type: 'image',
                            source: {
                                type: 'base64',
                                media_type: mediaType,
                                data: imageBase64
                            }
                        },
                        {
                            type: 'text',
                            text: MEAL_ANALYSIS_PROMPT
                        }
                    ]
                }]
        })
    });
    if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Claude API error ${response.status}: ${errorText}`);
    }
    const data = await response.json();
    const text = data.content[0].text.trim();
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
        throw new Error('Failed to parse meal analysis response');
    }
    const result = JSON.parse(jsonMatch[0]);
    return {
        food_description: result.food_description || 'Unknown food',
        estimated_calories: Math.max(0, Math.round(result.estimated_calories || 0)),
        estimated_protein_g: Math.max(0, Math.round((result.estimated_protein_g || 0) * 10) / 10),
        estimated_carbs_g: Math.max(0, Math.round((result.estimated_carbs_g || 0) * 10) / 10),
        estimated_fat_g: Math.max(0, Math.round((result.estimated_fat_g || 0) * 10) / 10),
        estimated_fiber_g: Math.max(0, Math.round((result.estimated_fiber_g || 0) * 10) / 10),
        ai_confidence: Math.min(1, Math.max(0, result.ai_confidence || 0.5))
    };
}
//# sourceMappingURL=mealAnalysis.js.map