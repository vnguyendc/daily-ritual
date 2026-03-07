import { describe, it, expect } from 'vitest'
import request from 'supertest'
import app from '../index.js'

describe('Health endpoint', () => {
  it('GET /api/v1/health returns 200 with status healthy', async () => {
    const res = await request(app).get('/api/v1/health')

    expect(res.status).toBe(200)
    expect(res.body.status).toBe('healthy')
    expect(res.body.version).toBe('1.0.0')
    expect(res.body.timestamp).toBeDefined()
  })
})

describe('Root endpoint', () => {
  it('GET / returns API info', async () => {
    const res = await request(app).get('/')

    expect(res.status).toBe(200)
    expect(res.body.name).toBe('Daily Ritual API')
    expect(res.body.endpoints).toBeDefined()
  })
})

describe('404 handling', () => {
  it('returns 404 for unknown routes', async () => {
    const res = await request(app).get('/api/v1/nonexistent')

    expect(res.status).toBe(404)
    expect(res.body.success).toBe(false)
  })
})
