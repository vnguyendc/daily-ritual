import { z } from 'zod';
import { DatabaseService, getUserFromToken } from '../services/supabase.js';
const workoutReflectionSchema = z.object({
    training_feeling: z.number().min(1).max(5),
    what_went_well: z.string().min(1).max(1000),
    what_to_improve: z.string().min(1).max(1000),
    energy_level: z.number().min(1).max(5).optional(),
    focus_level: z.number().min(1).max(5).optional(),
    workout_type: z.string().max(100).optional(),
    workout_intensity: z.enum(['light', 'moderate', 'hard', 'very_hard']).optional(),
    duration_minutes: z.number().min(1).max(600).optional(),
    calories_burned: z.number().min(1).max(5000).optional(),
    average_hr: z.number().min(40).max(220).optional(),
    max_hr: z.number().min(40).max(220).optional(),
    strava_activity_id: z.string().optional(),
    apple_workout_id: z.string().optional(),
    whoop_activity_id: z.string().optional()
});
export class WorkoutReflectionsController {
    static async createWorkoutReflection(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            if (!token) {
                return res.status(401).json({ error: 'Authorization token required' });
            }
            const user = await getUserFromToken(token);
            const validationResult = workoutReflectionSchema.safeParse(req.body);
            if (!validationResult.success) {
                return res.status(400).json({
                    error: 'Validation failed',
                    details: validationResult.error.errors
                });
            }
            const reflectionData = validationResult.data;
            const today = new Date().toISOString().split('T')[0];
            const { data: existingReflections } = await DatabaseService.supabaseServiceClient
                .from('workout_reflections')
                .select('workout_sequence')
                .eq('user_id', user.id)
                .eq('date', today)
                .order('workout_sequence', { ascending: false })
                .limit(1);
            const nextSequence = existingReflections?.[0]?.workout_sequence ?
                existingReflections[0].workout_sequence + 1 : 1;
            const reflection = await DatabaseService.createWorkoutReflection(user.id, {
                date: today,
                workout_sequence: nextSequence,
                ...reflectionData
            });
            await DatabaseService.updateUserStreak(user.id, 'workout_reflection', today);
            const response = {
                success: true,
                data: reflection,
                message: 'Workout reflection created successfully'
            };
            res.json(response);
        }
        catch (error) {
            console.error('Error creating workout reflection:', error);
            res.status(500).json({
                success: false,
                error: { error: 'Internal server error', message: error.message }
            });
        }
    }
    static async getWorkoutReflections(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            if (!token) {
                return res.status(401).json({ error: 'Authorization token required' });
            }
            const user = await getUserFromToken(token);
            const page = parseInt(req.query.page) || 1;
            const limit = Math.min(parseInt(req.query.limit) || 10, 50);
            const startDate = req.query.start_date;
            const endDate = req.query.end_date;
            const workoutType = req.query.workout_type;
            const minFeeling = req.query.training_feeling_min ? parseInt(req.query.training_feeling_min) : undefined;
            const maxFeeling = req.query.training_feeling_max ? parseInt(req.query.training_feeling_max) : undefined;
            let query = DatabaseService.supabaseServiceClient
                .from('workout_reflections')
                .select('*', { count: 'exact' })
                .eq('user_id', user.id)
                .order('created_at', { ascending: false });
            if (startDate) {
                query = query.gte('date', startDate);
            }
            if (endDate) {
                query = query.lte('date', endDate);
            }
            if (workoutType) {
                query = query.eq('workout_type', workoutType);
            }
            if (minFeeling) {
                query = query.gte('training_feeling', minFeeling);
            }
            if (maxFeeling) {
                query = query.lte('training_feeling', maxFeeling);
            }
            const offset = (page - 1) * limit;
            query = query.range(offset, offset + limit - 1);
            const { data, error, count } = await query;
            if (error)
                throw error;
            const totalPages = Math.ceil((count || 0) / limit);
            const response = {
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
            };
            res.json(response);
        }
        catch (error) {
            console.error('Error getting workout reflections:', error);
            res.status(500).json({
                success: false,
                error: { error: 'Internal server error', message: error.message }
            });
        }
    }
    static async getWorkoutReflection(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            if (!token) {
                return res.status(401).json({ error: 'Authorization token required' });
            }
            const user = await getUserFromToken(token);
            const { id } = req.params;
            const { data, error } = await DatabaseService.supabaseServiceClient
                .from('workout_reflections')
                .select('*')
                .eq('id', id)
                .eq('user_id', user.id)
                .single();
            if (error) {
                if (error.code === 'PGRST116') {
                    return res.status(404).json({
                        success: false,
                        error: { error: 'Not found', message: 'Workout reflection not found' }
                    });
                }
                throw error;
            }
            const response = {
                success: true,
                data
            };
            res.json(response);
        }
        catch (error) {
            console.error('Error getting workout reflection:', error);
            res.status(500).json({
                success: false,
                error: { error: 'Internal server error', message: error.message }
            });
        }
    }
    static async updateWorkoutReflection(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            if (!token) {
                return res.status(401).json({ error: 'Authorization token required' });
            }
            const user = await getUserFromToken(token);
            const { id } = req.params;
            const partialSchema = workoutReflectionSchema.partial();
            const validationResult = partialSchema.safeParse(req.body);
            if (!validationResult.success) {
                return res.status(400).json({
                    error: 'Validation failed',
                    details: validationResult.error.errors
                });
            }
            const updates = validationResult.data;
            const { data, error } = await DatabaseService.supabaseServiceClient
                .from('workout_reflections')
                .update({
                ...updates,
                updated_at: new Date().toISOString()
            })
                .eq('id', id)
                .eq('user_id', user.id)
                .select()
                .single();
            if (error) {
                if (error.code === 'PGRST116') {
                    return res.status(404).json({
                        success: false,
                        error: { error: 'Not found', message: 'Workout reflection not found' }
                    });
                }
                throw error;
            }
            const response = {
                success: true,
                data,
                message: 'Workout reflection updated successfully'
            };
            res.json(response);
        }
        catch (error) {
            console.error('Error updating workout reflection:', error);
            res.status(500).json({
                success: false,
                error: { error: 'Internal server error', message: error.message }
            });
        }
    }
    static async deleteWorkoutReflection(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            if (!token) {
                return res.status(401).json({ error: 'Authorization token required' });
            }
            const user = await getUserFromToken(token);
            const { id } = req.params;
            const { error } = await DatabaseService.supabaseServiceClient
                .from('workout_reflections')
                .delete()
                .eq('id', id)
                .eq('user_id', user.id);
            if (error)
                throw error;
            const response = {
                success: true,
                message: 'Workout reflection deleted successfully'
            };
            res.json(response);
        }
        catch (error) {
            console.error('Error deleting workout reflection:', error);
            res.status(500).json({
                success: false,
                error: { error: 'Internal server error', message: error.message }
            });
        }
    }
    static async getWorkoutStats(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            if (!token) {
                return res.status(401).json({ error: 'Authorization token required' });
            }
            const user = await getUserFromToken(token);
            const days = parseInt(req.query.days) || 30;
            const startDate = new Date();
            startDate.setDate(startDate.getDate() - days);
            const startDateStr = startDate.toISOString().split('T')[0];
            const { data, error } = await DatabaseService.supabaseServiceClient
                .from('workout_reflections')
                .select('training_feeling, workout_type, energy_level, focus_level, duration_minutes')
                .eq('user_id', user.id)
                .gte('date', startDateStr);
            if (error)
                throw error;
            const workouts = data || [];
            const totalWorkouts = workouts.length;
            const avgTrainingFeeling = workouts.length > 0 ?
                workouts.reduce((sum, w) => sum + (w.training_feeling || 0), 0) / workouts.length : 0;
            const avgEnergyLevel = workouts.length > 0 ?
                workouts.reduce((sum, w) => sum + (w.energy_level || 0), 0) / workouts.length : 0;
            const avgFocusLevel = workouts.length > 0 ?
                workouts.reduce((sum, w) => sum + (w.focus_level || 0), 0) / workouts.length : 0;
            const totalMinutes = workouts.reduce((sum, w) => sum + (w.duration_minutes || 0), 0);
            const workoutTypeDistribution = workouts.reduce((acc, w) => {
                const type = w.workout_type || 'unknown';
                acc[type] = (acc[type] || 0) + 1;
                return acc;
            }, {});
            const response = {
                success: true,
                data: {
                    period_days: days,
                    total_workouts: totalWorkouts,
                    avg_training_feeling: Math.round(avgTrainingFeeling * 10) / 10,
                    avg_energy_level: Math.round(avgEnergyLevel * 10) / 10,
                    avg_focus_level: Math.round(avgFocusLevel * 10) / 10,
                    total_minutes: totalMinutes,
                    workout_type_distribution: workoutTypeDistribution,
                    workouts_per_week: Math.round((totalWorkouts / days * 7) * 10) / 10
                }
            };
            res.json(response);
        }
        catch (error) {
            console.error('Error getting workout stats:', error);
            res.status(500).json({
                success: false,
                error: { error: 'Internal server error', message: error.message }
            });
        }
    }
}
//# sourceMappingURL=workoutReflections.js.map