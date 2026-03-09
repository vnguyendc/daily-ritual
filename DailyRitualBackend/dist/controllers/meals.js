import { z } from 'zod';
import { supabaseServiceClient, getUserFromToken } from '../services/supabase.js';
import { analyzeMealPhoto } from '../services/mealAnalysis.js';
import { SupabaseEdgeFunctions } from '../services/integrations/supabaseEdgeFunctions.js';
const mealUpdateSchema = z.object({
    user_calories: z.number().min(0).max(10000).optional(),
    user_protein_g: z.number().min(0).max(1000).optional(),
    user_carbs_g: z.number().min(0).max(1000).optional(),
    user_fat_g: z.number().min(0).max(1000).optional(),
    user_notes: z.string().max(500).optional()
});
export class MealsController {
    static async createMeal(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            if (!token) {
                return res.status(401).json({ error: 'Authorization token required' });
            }
            const user = await getUserFromToken(token);
            const file = req.file;
            const { meal_type, date } = req.body;
            if (!meal_type || !['breakfast', 'lunch', 'dinner', 'snack'].includes(meal_type)) {
                return res.status(400).json({ error: 'Valid meal_type required (breakfast, lunch, dinner, snack)' });
            }
            const mealDate = date || new Date().toISOString().split('T')[0];
            let photoStoragePath = null;
            let photoUrl = null;
            let analysisResult = null;
            if (file) {
                const timestamp = Date.now();
                const ext = file.mimetype === 'image/png' ? 'png' : 'jpg';
                photoStoragePath = `${user.id}/${mealDate}/${timestamp}.${ext}`;
                const { error: uploadError } = await supabaseServiceClient
                    .storage
                    .from('meal-photos')
                    .upload(photoStoragePath, file.buffer, {
                    contentType: file.mimetype,
                    upsert: false
                });
                if (uploadError) {
                    console.error('Photo upload error:', uploadError);
                }
                else {
                    const { data: urlData } = await supabaseServiceClient
                        .storage
                        .from('meal-photos')
                        .createSignedUrl(photoStoragePath, 60 * 60 * 24 * 7);
                    photoUrl = urlData?.signedUrl || null;
                }
                try {
                    const base64 = file.buffer.toString('base64');
                    analysisResult = await analyzeMealPhoto(base64, file.mimetype);
                }
                catch (err) {
                    console.error('Meal analysis error:', err);
                }
            }
            const { data: meal, error: insertError } = await supabaseServiceClient
                .from('meals')
                .insert({
                user_id: user.id,
                date: mealDate,
                meal_type: meal_type,
                photo_storage_path: photoStoragePath,
                photo_url: photoUrl,
                food_description: analysisResult?.food_description || null,
                estimated_calories: analysisResult?.estimated_calories || null,
                estimated_protein_g: analysisResult?.estimated_protein_g || null,
                estimated_carbs_g: analysisResult?.estimated_carbs_g || null,
                estimated_fat_g: analysisResult?.estimated_fat_g || null,
                estimated_fiber_g: analysisResult?.estimated_fiber_g || null,
                ai_confidence: analysisResult?.ai_confidence || null,
                user_notes: req.body.user_notes || null
            })
                .select()
                .single();
            if (insertError)
                throw insertError;
            SupabaseEdgeFunctions.generateInsight({
                supabaseUrl: process.env.SUPABASE_URL || '',
                authToken: token,
                insight_type: 'post_meal',
                context_data: { meal_id: meal.id },
                data_period_end: mealDate
            }).catch(() => { });
            const response = {
                success: true,
                data: meal,
                message: 'Meal logged successfully'
            };
            res.json(response);
        }
        catch (error) {
            console.error('Error creating meal:', error);
            res.status(500).json({
                success: false,
                error: { error: 'Internal server error', message: error.message }
            });
        }
    }
    static async getMeals(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            if (!token) {
                return res.status(401).json({ error: 'Authorization token required' });
            }
            const user = await getUserFromToken(token);
            const date = req.query.date;
            let query = supabaseServiceClient
                .from('meals')
                .select('*')
                .eq('user_id', user.id)
                .order('created_at', { ascending: true });
            if (date) {
                query = query.eq('date', date);
            }
            const { data, error } = await query;
            if (error)
                throw error;
            res.json({ success: true, data: data || [] });
        }
        catch (error) {
            console.error('Error getting meals:', error);
            res.status(500).json({
                success: false,
                error: { error: 'Internal server error', message: error.message }
            });
        }
    }
    static async getMeal(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            if (!token) {
                return res.status(401).json({ error: 'Authorization token required' });
            }
            const user = await getUserFromToken(token);
            const id = req.params.id;
            const { data, error } = await supabaseServiceClient
                .from('meals')
                .select('*')
                .eq('id', id)
                .eq('user_id', user.id)
                .single();
            if (error) {
                if (error.code === 'PGRST116') {
                    return res.status(404).json({ success: false, error: { error: 'Not found', message: 'Meal not found' } });
                }
                throw error;
            }
            res.json({ success: true, data });
        }
        catch (error) {
            console.error('Error getting meal:', error);
            res.status(500).json({
                success: false,
                error: { error: 'Internal server error', message: error.message }
            });
        }
    }
    static async updateMeal(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            if (!token) {
                return res.status(401).json({ error: 'Authorization token required' });
            }
            const user = await getUserFromToken(token);
            const id = req.params.id;
            const validationResult = mealUpdateSchema.safeParse(req.body);
            if (!validationResult.success) {
                return res.status(400).json({ error: 'Validation failed', details: validationResult.error.errors });
            }
            const { data, error } = await supabaseServiceClient
                .from('meals')
                .update({
                ...validationResult.data,
                updated_at: new Date().toISOString()
            })
                .eq('id', id)
                .eq('user_id', user.id)
                .select()
                .single();
            if (error) {
                if (error.code === 'PGRST116') {
                    return res.status(404).json({ success: false, error: { error: 'Not found', message: 'Meal not found' } });
                }
                throw error;
            }
            res.json({ success: true, data, message: 'Meal updated successfully' });
        }
        catch (error) {
            console.error('Error updating meal:', error);
            res.status(500).json({
                success: false,
                error: { error: 'Internal server error', message: error.message }
            });
        }
    }
    static async deleteMeal(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            if (!token) {
                return res.status(401).json({ error: 'Authorization token required' });
            }
            const user = await getUserFromToken(token);
            const id = req.params.id;
            const { data: meal } = await supabaseServiceClient
                .from('meals')
                .select('photo_storage_path')
                .eq('id', id)
                .eq('user_id', user.id)
                .single();
            if (meal?.photo_storage_path) {
                await supabaseServiceClient
                    .storage
                    .from('meal-photos')
                    .remove([meal.photo_storage_path]);
            }
            const { error } = await supabaseServiceClient
                .from('meals')
                .delete()
                .eq('id', id)
                .eq('user_id', user.id);
            if (error)
                throw error;
            res.json({ success: true, message: 'Meal deleted successfully' });
        }
        catch (error) {
            console.error('Error deleting meal:', error);
            res.status(500).json({
                success: false,
                error: { error: 'Internal server error', message: error.message }
            });
        }
    }
    static async getDailySummary(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            if (!token) {
                return res.status(401).json({ error: 'Authorization token required' });
            }
            const user = await getUserFromToken(token);
            const date = req.query.date || new Date().toISOString().split('T')[0];
            const { data: meals, error } = await supabaseServiceClient
                .from('meals')
                .select('*')
                .eq('user_id', user.id)
                .eq('date', date)
                .order('created_at', { ascending: true });
            if (error)
                throw error;
            const mealList = meals || [];
            const summary = {
                date,
                meal_count: mealList.length,
                total_calories: mealList.reduce((sum, m) => sum + (m.user_calories || m.estimated_calories || 0), 0),
                total_protein_g: mealList.reduce((sum, m) => sum + parseFloat(String(m.user_protein_g || m.estimated_protein_g || 0)), 0),
                total_carbs_g: mealList.reduce((sum, m) => sum + parseFloat(String(m.user_carbs_g || m.estimated_carbs_g || 0)), 0),
                total_fat_g: mealList.reduce((sum, m) => sum + parseFloat(String(m.user_fat_g || m.estimated_fat_g || 0)), 0),
                total_fiber_g: mealList.reduce((sum, m) => sum + parseFloat(String(m.estimated_fiber_g || 0)), 0),
                meals: mealList
            };
            res.json({ success: true, data: summary });
        }
        catch (error) {
            console.error('Error getting daily summary:', error);
            res.status(500).json({
                success: false,
                error: { error: 'Internal server error', message: error.message }
            });
        }
    }
}
//# sourceMappingURL=meals.js.map