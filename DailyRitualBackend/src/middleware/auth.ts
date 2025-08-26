// Authentication middleware
import { Request, Response, NextFunction } from 'express'
import { getUserFromToken } from '../services/supabase.js'

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

    if (!token) {
      return res.status(401).json({
        success: false,
        error: { error: 'Unauthorized', message: 'Access token required' }
      })
    }

    const user = await getUserFromToken(token)
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
