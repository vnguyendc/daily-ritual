import { getUserFromToken, DatabaseService } from '../services/supabase.js';
export async function authenticateToken(req, res, next) {
    try {
        const authHeader = req.headers.authorization;
        const token = authHeader && authHeader.split(' ')[1];
        const useMock = process.env.USE_MOCK === 'true';
        const devUserId = process.env.DEV_USER_ID;
        let user;
        if (!token) {
            if (useMock) {
                console.log('🔓 [auth] No token provided, using mock user (dev mode)');
                user = { id: 'mock-user-id', email: null };
            }
            else if (devUserId) {
                console.log('👤 [auth] Using DEV_USER_ID for development without auth');
                user = { id: devUserId, email: null };
            }
            else {
                return res.status(401).json({
                    success: false,
                    error: { error: 'Unauthorized', message: 'Access token required' }
                });
            }
        }
        else {
            user = await getUserFromToken(token);
        }
        try {
            await DatabaseService.ensureUserRecord(user);
        }
        catch (e) {
            console.warn('ensureUserRecord failed:', e);
        }
        req.user = user;
        next();
    }
    catch (error) {
        console.error('Authentication error:', error);
        return res.status(401).json({
            success: false,
            error: { error: 'Unauthorized', message: 'Invalid or expired token' }
        });
    }
}
export function requirePremium(req, res, next) {
    if (process.env.NODE_ENV === 'development') {
        return next();
    }
    next();
}
export function validateResourceOwnership(resourceUserIdField = 'user_id') {
    return (req, res, next) => {
        const user = req.user;
        const resourceUserId = req.body[resourceUserIdField] || req.params.userId;
        if (user?.id !== resourceUserId) {
            return res.status(403).json({
                success: false,
                error: { error: 'Forbidden', message: 'You can only access your own resources' }
            });
        }
        next();
    };
}
//# sourceMappingURL=auth.js.map