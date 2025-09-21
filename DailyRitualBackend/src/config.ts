import dotenv from 'dotenv'
dotenv.config()

const ENV = process.env

export const config = {
  NODE_ENV: ENV.NODE_ENV || 'development',
  PORT: Number(ENV.PORT) || 3000,
  SUPABASE_URL: ENV.SUPABASE_URL || '',
  SUPABASE_SERVICE_ROLE_KEY: ENV.SUPABASE_SERVICE_ROLE_KEY || '',
  SUPABASE_ANON_KEY: ENV.SUPABASE_ANON_KEY || '',
  DEV_USER_ID: ENV.DEV_USER_ID || undefined,
  ALLOWED_ORIGINS: (ENV.ALLOWED_ORIGINS || '').split(',').filter(Boolean),
  USE_MOCK: (ENV.USE_MOCK === 'true') || ((ENV.NODE_ENV !== 'production') && (!ENV.SUPABASE_URL || !ENV.SUPABASE_SERVICE_ROLE_KEY))
}

export function assertProductionEnv() {
  if (config.NODE_ENV === 'production') {
    const missing: string[] = []
    if (!config.SUPABASE_URL) missing.push('SUPABASE_URL')
    if (!config.SUPABASE_SERVICE_ROLE_KEY) missing.push('SUPABASE_SERVICE_ROLE_KEY')
    if (missing.length) {
      throw new Error(`Missing required env vars in production: ${missing.join(', ')}`)
    }
  }
}


