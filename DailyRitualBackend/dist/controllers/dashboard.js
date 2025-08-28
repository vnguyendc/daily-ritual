import { DatabaseService, getUserFromToken } from '../services/supabase.js';
export class DashboardController {
    static async getDashboardData(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            if (!token) {
                return res.status(401).json({ error: 'Authorization token required' });
            }
            const user = await getUserFromToken(token);
            const [streaks, recentEntries, upcomingCompetitions, recentInsights, weeklyStats] = await Promise.all([
                DatabaseService.getUserStreaks(user.id),
                DatabaseService.getRecentEntries(user.id, 5),
                DatabaseService.getUpcomingCompetitions(user.id),
                DatabaseService.getRecentInsights(user.id, 3),
                DashboardController.getWeeklyStats(user.id)
            ]);
            const currentStreaks = streaks?.reduce((acc, streak) => {
                acc[streak.streak_type] = streak.current_streak;
                return acc;
            }, {}) || {};
            const dashboardData = {
                current_streak: {
                    morning_ritual: currentStreaks.morning_ritual || 0,
                    workout_reflection: currentStreaks.workout_reflection || 0,
                    evening_reflection: currentStreaks.evening_reflection || 0,
                    daily_complete: currentStreaks.daily_complete || 0
                },
                recent_entries: recentEntries,
                upcoming_competitions: upcomingCompetitions,
                recent_insights: recentInsights,
                weekly_stats: weeklyStats
            };
            const response = {
                success: true,
                data: dashboardData
            };
            res.json(response);
        }
        catch (error) {
            console.error('Error getting dashboard data:', error);
            res.status(500).json({
                success: false,
                error: { error: 'Internal server error', message: error.message }
            });
        }
    }
    static async getWeeklyStats(userId) {
        const oneWeekAgo = new Date();
        oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
        const startDate = oneWeekAgo.toISOString().split('T')[0];
        const endDate = new Date().toISOString().split('T')[0];
        const { data: weeklyEntries, error: entriesError } = await DatabaseService.supabaseServiceClient
            .from('daily_entries')
            .select('goals, overall_mood')
            .eq('user_id', userId)
            .gte('date', startDate)
            .lte('date', endDate);
        if (entriesError)
            throw entriesError;
        const { data: weeklyWorkouts, error: workoutsError } = await DatabaseService.supabaseServiceClient
            .from('workout_reflections')
            .select('training_feeling')
            .eq('user_id', userId)
            .gte('date', startDate)
            .lte('date', endDate);
        if (workoutsError)
            throw workoutsError;
        const entries = weeklyEntries || [];
        const workouts = weeklyWorkouts || [];
        const totalGoals = entries.reduce((sum, entry) => sum + (entry.goals?.length || 0), 0);
        const goalsCompleted = totalGoals;
        const avgMood = entries.length > 0 ?
            entries.reduce((sum, entry) => sum + (entry.overall_mood || 0), 0) / entries.length : 0;
        const avgTrainingFeeling = workouts.length > 0 ?
            workouts.reduce((sum, workout) => sum + (workout.training_feeling || 0), 0) / workouts.length : 0;
        return {
            goals_completed: goalsCompleted,
            total_goals: totalGoals,
            avg_mood: Math.round(avgMood * 10) / 10,
            workout_count: workouts.length,
            avg_training_feeling: Math.round(avgTrainingFeeling * 10) / 10
        };
    }
    static async getUserProfile(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            if (!token) {
                return res.status(401).json({ error: 'Authorization token required' });
            }
            const user = await getUserFromToken(token);
            const profile = await DatabaseService.getUserProfile(user.id);
            const response = {
                success: true,
                data: profile
            };
            res.json(response);
        }
        catch (error) {
            console.error('Error getting user profile:', error);
            res.status(500).json({
                success: false,
                error: { error: 'Internal server error', message: error.message }
            });
        }
    }
    static async updateUserProfile(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            if (!token) {
                return res.status(401).json({ error: 'Authorization token required' });
            }
            const user = await getUserFromToken(token);
            const allowedFields = [
                'name',
                'primary_sport',
                'morning_reminder_time',
                'timezone',
                'fitness_connected',
                'whoop_connected',
                'strava_connected',
                'apple_health_connected'
            ];
            const updates = Object.keys(req.body)
                .filter(key => allowedFields.includes(key))
                .reduce((obj, key) => {
                obj[key] = req.body[key];
                return obj;
            }, {});
            if (Object.keys(updates).length === 0) {
                return res.status(400).json({
                    success: false,
                    error: { error: 'No valid fields to update', message: 'Provide at least one valid field to update' }
                });
            }
            const updatedProfile = await DatabaseService.updateUserProfile(user.id, updates);
            const response = {
                success: true,
                data: updatedProfile,
                message: 'Profile updated successfully'
            };
            res.json(response);
        }
        catch (error) {
            console.error('Error updating user profile:', error);
            res.status(500).json({
                success: false,
                error: { error: 'Internal server error', message: error.message }
            });
        }
    }
    static async getUserStreaks(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            if (!token) {
                return res.status(401).json({ error: 'Authorization token required' });
            }
            const user = await getUserFromToken(token);
            const streaks = await DatabaseService.getUserStreaks(user.id);
            const response = {
                success: true,
                data: streaks || []
            };
            res.json(response);
        }
        catch (error) {
            console.error('Error getting user streaks:', error);
            res.status(500).json({
                success: false,
                error: { error: 'Internal server error', message: error.message }
            });
        }
    }
    static async getAIInsights(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            if (!token) {
                return res.status(401).json({ error: 'Authorization token required' });
            }
            const user = await getUserFromToken(token);
            const limit = Math.min(parseInt(req.query.limit) || 10, 50);
            const insightType = req.query.insight_type;
            const unreadOnly = req.query.unread_only === 'true';
            let query = DatabaseService.supabaseServiceClient
                .from('ai_insights')
                .select('*')
                .eq('user_id', user.id)
                .order('created_at', { ascending: false })
                .limit(limit);
            if (insightType) {
                query = query.eq('insight_type', insightType);
            }
            if (unreadOnly) {
                query = query.eq('is_read', false);
            }
            const { data, error } = await query;
            if (error)
                throw error;
            const response = {
                success: true,
                data: data || []
            };
            res.json(response);
        }
        catch (error) {
            console.error('Error getting AI insights:', error);
            res.status(500).json({
                success: false,
                error: { error: 'Internal server error', message: error.message }
            });
        }
    }
    static async markInsightAsRead(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            if (!token) {
                return res.status(401).json({ error: 'Authorization token required' });
            }
            const user = await getUserFromToken(token);
            const { insightId } = req.params;
            await DatabaseService.markInsightAsRead(insightId, user.id);
            const response = {
                success: true,
                message: 'Insight marked as read'
            };
            res.json(response);
        }
        catch (error) {
            console.error('Error marking insight as read:', error);
            res.status(500).json({
                success: false,
                error: { error: 'Internal server error', message: error.message }
            });
        }
    }
    static async generateWeeklyInsights(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            if (!token) {
                return res.status(401).json({ error: 'Authorization token required' });
            }
            const user = await getUserFromToken(token);
            const insightResponse = await fetch(`${process.env.SUPABASE_URL}/functions/v1/generate-insights`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    insight_type: 'weekly'
                })
            });
            if (!insightResponse.ok) {
                throw new Error(`Insight generation failed: ${insightResponse.status}`);
            }
            const insightData = await insightResponse.json();
            const response = {
                success: true,
                data: insightData.insight,
                message: 'Weekly insights generated successfully'
            };
            res.json(response);
        }
        catch (error) {
            console.error('Error generating weekly insights:', error);
            res.status(500).json({
                success: false,
                error: { error: 'Internal server error', message: error.message }
            });
        }
    }
}
//# sourceMappingURL=dashboard.js.map