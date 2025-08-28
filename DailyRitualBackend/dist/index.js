import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import routes from './routes/index.js';
dotenv.config();
const app = express();
const PORT = Number(process.env.PORT) || 3000;
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            scriptSrc: ["'self'"],
            imgSrc: ["'self'", "data:", "https:"],
            connectSrc: ["'self'", "https://api.supabase.co", "https://*.supabase.co"]
        }
    },
    crossOriginEmbedderPolicy: false
}));
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000', 'http://localhost:8080'],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'x-client-info', 'apikey']
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use((req, res, next) => {
    const timestamp = new Date().toISOString();
    console.log(`\n🌟 ${timestamp} - ${req.method} ${req.path}`);
    if (req.headers.authorization) {
        console.log(`🔑 Auth: ${req.headers.authorization.substring(0, 20)}...`);
    }
    if ((req.method === 'POST' || req.method === 'PUT') && req.body) {
        console.log(`📦 Request Body:`, JSON.stringify(req.body, null, 2));
    }
    if (Object.keys(req.query).length > 0) {
        console.log(`🔍 Query Params:`, req.query);
    }
    console.log(`─────────────────────────────────────`);
    const originalSend = res.send;
    res.send = function (data) {
        console.log(`📤 Response:`, typeof data === 'string' ? data.substring(0, 500) + (data.length > 500 ? '...' : '') : data);
        console.log(`✅ Status: ${res.statusCode}\n`);
        return originalSend.call(this, data);
    };
    next();
});
app.use('/api/v1', routes);
app.get('/', (req, res) => {
    res.json({
        name: 'Daily Ritual API',
        version: '1.0.0',
        description: 'Backend API for Daily Ritual - Athletic Performance Journaling App',
        endpoints: {
            health: '/api/v1/health',
            dashboard: '/api/v1/dashboard',
            daily_entries: '/api/v1/daily-entries',
            workout_reflections: '/api/v1/workout-reflections',
            profile: '/api/v1/profile',
            insights: '/api/v1/insights'
        },
        documentation: 'https://github.com/your-org/daily-ritual/blob/main/API.md'
    });
});
app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: {
            error: 'Not Found',
            message: `Endpoint ${req.method} ${req.path} not found`
        }
    });
});
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(err.status || 500).json({
        success: false,
        error: {
            error: 'Internal Server Error',
            message: process.env.NODE_ENV === 'production'
                ? 'An unexpected error occurred'
                : err.message,
            ...(process.env.NODE_ENV !== 'production' && { stack: err.stack })
        }
    });
});
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Daily Ritual API server running on port ${PORT}`);
    console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🔗 Health check: http://localhost:${PORT}/api/v1/health`);
    console.log(`📱 Device access: http://172.19.69.110:${PORT}/api/v1/health`);
    console.log(`📚 API docs: http://localhost:${PORT}/`);
});
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    process.exit(0);
});
process.on('SIGINT', () => {
    console.log('SIGINT received, shutting down gracefully');
    process.exit(0);
});
export default app;
//# sourceMappingURL=index.js.map