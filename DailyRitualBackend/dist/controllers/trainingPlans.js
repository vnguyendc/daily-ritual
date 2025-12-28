import { DatabaseService, getUserFromToken } from '../services/supabase.js';
export class TrainingPlansController {
    static async get(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            const useMock = process.env.USE_MOCK === 'true';
            const devUserId = process.env.DEV_USER_ID;
            let user;
            if (!token) {
                if (useMock) {
                    user = { id: 'mock-user-id' };
                }
                else if (devUserId) {
                    user = { id: devUserId };
                }
                else {
                    return res.status(401).json({ error: 'Authorization token required' });
                }
            }
            else {
                user = await getUserFromToken(token);
            }
            const id = req.params.id;
            if (!id) {
                return res.status(400).json({ error: 'Training plan ID required' });
            }
            const plan = await DatabaseService.getTrainingPlanById(id, user.id);
            if (!plan) {
                return res.status(404).json({ error: 'Training plan not found' });
            }
            const response = { success: true, data: plan };
            res.json(response);
        }
        catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            console.error('Error getting training plan:', error);
            res.status(500).json({ success: false, error: { error: 'Internal server error', message } });
        }
    }
    static async listInRange(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            const useMock = process.env.USE_MOCK === 'true';
            const devUserId = process.env.DEV_USER_ID;
            let user;
            if (!token) {
                if (useMock) {
                    user = { id: 'mock-user-id' };
                }
                else if (devUserId) {
                    user = { id: devUserId };
                }
                else {
                    return res.status(401).json({ error: 'Authorization token required' });
                }
            }
            else {
                user = await getUserFromToken(token);
            }
            const start = req.query.start;
            const end = req.query.end;
            if (!start || !start.match(/^\d{4}-\d{2}-\d{2}$/)) {
                return res.status(400).json({ error: 'start query param (YYYY-MM-DD) required' });
            }
            if (!end || !end.match(/^\d{4}-\d{2}-\d{2}$/)) {
                return res.status(400).json({ error: 'end query param (YYYY-MM-DD) required' });
            }
            const startDate = new Date(start);
            const endDate = new Date(end);
            const diffDays = Math.abs((endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24));
            if (diffDays > 365) {
                return res.status(400).json({ error: 'Date range cannot exceed 365 days' });
            }
            const plans = await DatabaseService.listTrainingPlansInRange(user.id, start, end);
            const response = { success: true, data: plans };
            res.json(response);
        }
        catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            console.error('Error listing training plans in range:', error);
            res.status(500).json({ success: false, error: { error: 'Internal server error', message } });
        }
    }
    static async list(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            const useMock = process.env.USE_MOCK === 'true';
            const devUserId = process.env.DEV_USER_ID;
            let user;
            if (!token) {
                if (useMock) {
                    user = { id: 'mock-user-id' };
                }
                else if (devUserId) {
                    user = { id: devUserId };
                }
                else {
                    return res.status(401).json({ error: 'Authorization token required' });
                }
            }
            else {
                user = await getUserFromToken(token);
            }
            const date = req.query.date;
            if (!date || !date.match(/^\d{4}-\d{2}-\d{2}$/)) {
                return res.status(400).json({ error: 'date query param (YYYY-MM-DD) required' });
            }
            try {
                await DatabaseService.ensureUserRecord({ id: user.id, email: user.email || null });
            }
            catch (e) {
                console.warn('ensureUserRecord failed:', e);
            }
            const plans = await DatabaseService.listTrainingPlans(user.id, date);
            const response = { success: true, data: plans };
            res.json(response);
        }
        catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            console.error('Error listing training plans:', error);
            res.status(500).json({ success: false, error: { error: 'Internal server error', message } });
        }
    }
    static async create(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            const useMock = process.env.USE_MOCK === 'true';
            const devUserId = process.env.DEV_USER_ID;
            let user;
            if (!token) {
                if (useMock) {
                    user = { id: 'mock-user-id' };
                }
                else if (devUserId) {
                    user = { id: devUserId };
                }
                else {
                    return res.status(401).json({ error: 'Authorization token required' });
                }
            }
            else {
                user = await getUserFromToken(token);
            }
            console.log('📝 Creating training plan for user:', user.id);
            console.log('📝 Request body:', JSON.stringify(req.body));
            const { date, sequence, type, start_time, intensity, duration_minutes, notes } = req.body || {};
            if (!date || !date.match(/^\d{4}-\d{2}-\d{2}$/)) {
                return res.status(400).json({ error: 'date (YYYY-MM-DD) required' });
            }
            if (!type) {
                return res.status(400).json({ error: 'type is required' });
            }
            try {
                await DatabaseService.ensureUserRecord({ id: user.id, email: user.email || null });
                console.log('✅ User record ensured');
            }
            catch (e) {
                console.error('❌ ensureUserRecord failed:', e?.message || e);
            }
            const payload = {
                user_id: user.id,
                date,
                sequence: sequence || 1,
                type,
                start_time: start_time || null,
                intensity: intensity || null,
                duration_minutes: duration_minutes || null,
                notes: notes || null
            };
            console.log('📝 Insert payload:', JSON.stringify(payload));
            const created = await DatabaseService.createTrainingPlan(user.id, payload);
            console.log('✅ Training plan created:', created?.id);
            const response = { success: true, data: created };
            res.json(response);
        }
        catch (error) {
            let message = 'Unknown error';
            if (error instanceof Error) {
                message = error.message;
            }
            else if (typeof error === 'object' && error !== null) {
                message = error.message || error.details || JSON.stringify(error);
            }
            else {
                message = String(error);
            }
            console.error('❌ Error creating training plan:', message, error);
            res.status(500).json({ success: false, error: { error: 'Internal server error', message } });
        }
    }
    static async update(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            const useMock = process.env.USE_MOCK === 'true';
            const devUserId = process.env.DEV_USER_ID;
            let user;
            if (!token) {
                if (useMock) {
                    user = { id: 'mock-user-id' };
                }
                else if (devUserId) {
                    user = { id: devUserId };
                }
                else {
                    return res.status(401).json({ error: 'Authorization token required' });
                }
            }
            else {
                user = await getUserFromToken(token);
            }
            const id = req.params.id;
            if (!id) {
                return res.status(400).json({ error: 'Training plan ID required' });
            }
            const updates = { ...req.body };
            const updated = await DatabaseService.updateTrainingPlanById(id, user.id, updates);
            const response = { success: true, data: updated };
            res.json(response);
        }
        catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            console.error('Error updating training plan:', error);
            res.status(500).json({ success: false, error: { error: 'Internal server error', message } });
        }
    }
    static async remove(req, res) {
        try {
            const token = req.headers.authorization?.replace('Bearer ', '');
            const useMock = process.env.USE_MOCK === 'true';
            const devUserId = process.env.DEV_USER_ID;
            let user;
            if (!token) {
                if (useMock) {
                    user = { id: 'mock-user-id' };
                }
                else if (devUserId) {
                    user = { id: devUserId };
                }
                else {
                    return res.status(401).json({ error: 'Authorization token required' });
                }
            }
            else {
                user = await getUserFromToken(token);
            }
            const id = req.params.id;
            if (!id) {
                return res.status(400).json({ error: 'Training plan ID required' });
            }
            await DatabaseService.deleteTrainingPlanById(id, user.id);
            const response = { success: true, message: 'Training plan deleted successfully' };
            res.json(response);
        }
        catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            console.error('Error deleting training plan:', error);
            res.status(500).json({ success: false, error: { error: 'Internal server error', message } });
        }
    }
}
//# sourceMappingURL=trainingPlans.js.map