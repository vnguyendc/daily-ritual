// Authentication middleware
import { Request, Response, NextFunction } from 'express'
import { getUserFromToken, DatabaseService } from '../services/supabase.js'

// Extend Express Request type to include user
declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string
        email?: string
        [key: string]: any
      }
    }
  }
}

// Middleware to verify JWT token and attach user to request
export async function authenticateToken(req: Request, res: Response, next: NextFunction) {
  try {
    const authHeader = req.headers.authorization
    const token = authHeader && authHeader.split(' ')[1] // Bearer TOKEN

    // Dev-friendly fallback: allow mock or DEV_USER_ID without token
    const useMock = process.env.USE_MOCK === 'true'
    const devUserId = process.env.DEV_USER_ID

    let user: any
    if (!token) {
      if (useMock) {
        console.log('🔓 [auth] No token provided, using mock user (dev mode)')
        user = { id: 'mock-user-id', email: null }
      } else if (devUserId) {
        console.log('👤 [auth] Using DEV_USER_ID for development without auth')
        user = { id: devUserId, email: null }
      } else {
        return res.status(401).json({
          success: false,
          error: { error: 'Unauthorized', message: 'Access token required' }
        })
      }
    } else {
      user = await getUserFromToken(token)
    }
    // Ensure profile row exists in public.users
    try { await DatabaseService.ensureUserRecord(user as any) } catch (e) {
      console.warn('ensureUserRecord failed:', e)
    }
    req.user = user
    next()
  } catch (error) {
    console.error('Authentication error:', error)
    return res.status(401).json({
      success: false,
      error: { error: 'Unauthorized', message: 'Invalid or expired token' }
    })
  }
}

// Middleware to check if user has premium subscription
export function requirePremium(req: Request, res: Response, next: NextFunction) {
  // This would typically check the user's subscription status
  // For now, we'll skip this check in development
  if (process.env.NODE_ENV === 'development') {
    return next()
  }

  // TODO: Implement premium subscription check
  // const user = req.user
  // if (user.subscription_status !== 'premium' && user.subscription_status !== 'trial') {
  //   return res.status(403).json({
  //     success: false,
  //     error: { error: 'Premium required', message: 'This feature requires a premium subscription' }
  //   })
  // }

  next()
}

// Middleware to validate user owns the resource
export function validateResourceOwnership(resourceUserIdField: string = 'user_id') {
  return (req: Request, res: Response, next: NextFunction) => {
    const user = req.user
    const resourceUserId = req.body[resourceUserIdField] || req.params.userId

    if (user?.id !== resourceUserId) {
      return res.status(403).json({
        success: false,
        error: { error: 'Forbidden', message: 'You can only access your own resources' }
      })
    }

    next()
  }
}
