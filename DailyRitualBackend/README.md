# Daily Ritual Backend

Backend API for Daily Ritual - Athletic Performance Journaling App with AI insights.

## Features

- 🏃‍♂️ **Athletic-focused journaling** - Morning rituals, workout reflections, evening reviews
- 🤖 **AI-powered insights** - Personalized affirmations and pattern analysis using Claude AI
- 📊 **Performance tracking** - Streaks, mood patterns, training satisfaction
- 🏆 **Competition preparation** - Specialized mental prep tracking and insights
- 🔗 **Fitness integrations** - Whoop, Strava, Apple Health support
- 🔒 **Secure & private** - Row-level security with Supabase
- ⚡ **Real-time updates** - WebSocket support for live data

## Tech Stack

- **Runtime**: Node.js + TypeScript
- **Framework**: Express.js
- **Database**: Supabase (PostgreSQL)
- **AI**: Anthropic Claude API
- **Auth**: Supabase Auth (JWT)
- **Integrations**: Whoop API, Strava API, Apple HealthKit
- **Deployment**: Supabase Edge Functions + Express server

## Quick Start

### Prerequisites

- Node.js 18+
- Supabase account and project
- Anthropic API key (for AI features)

### Installation

1. **Clone and install dependencies**
   ```bash
   cd DailyRitualBackend
   npm install
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your Supabase and API keys
   ```

3. **Set up Supabase**
   ```bash
   # Install Supabase CLI
   npm install -g supabase

   # Login to Supabase
   supabase login

   # Link to your project
   supabase link --project-ref your-project-ref

   # Run database migrations
   supabase db push
   ```

4. **Deploy Edge Functions**
   ```bash
   supabase functions deploy generate-affirmation
   supabase functions deploy generate-insights
   ```

5. **Start development server**
   ```bash
   npm run dev
   ```

The API will be available at `http://localhost:3000`

## API Endpoints

### Core Endpoints

- `GET /api/v1/health` - Health check
- `GET /api/v1/dashboard` - Dashboard overview data
- `GET /api/v1/profile` - User profile
- `PUT /api/v1/profile` - Update profile

### Daily Entries

- `GET /api/v1/daily-entries` - List daily entries
- `GET /api/v1/daily-entries/:date` - Get specific date entry
- `POST /api/v1/daily-entries/:date/morning` - Complete morning ritual
- `POST /api/v1/daily-entries/:date/evening` - Complete evening reflection

### Workout Reflections

- `GET /api/v1/workout-reflections` - List workout reflections
- `POST /api/v1/workout-reflections` - Create workout reflection
- `GET /api/v1/workout-reflections/stats` - Get workout statistics

### AI Insights

- `GET /api/v1/insights` - Get AI insights
- `POST /api/v1/insights/weekly` - Generate weekly insights
- `PUT /api/v1/insights/:id/read` - Mark insight as read

## Database Schema

The database includes the following main tables:

- **users** - User profiles and preferences
- **daily_entries** - Morning rituals and evening reflections
- **workout_reflections** - Post-workout feedback and data
- **competitions** - Upcoming competitions and goals
- **competition_prep_entries** - Mental preparation tracking
- **ai_insights** - Generated insights and patterns
- **quotes** - Daily inspirational quotes
- **user_streaks** - Habit tracking and streaks

## AI Features

### Morning Affirmations
Personalized affirmations generated based on:
- Recent goals and challenges
- Recovery data (if Whoop connected)
- Upcoming training type
- Competition proximity

### Insights Engine
Pattern analysis covering:
- Goal completion correlations
- Mood and training performance links
- Optimal training timing
- Competition readiness indicators

## Integrations

### Whoop
- Recovery score
- Strain data
- Sleep performance
- Heart rate variability

### Strava
- Activity data
- Training load
- Performance metrics
- Real-time webhooks

### Apple Health
- Workout data
- Heart rate
- Activity summaries
- Client-side integration

## Development

### Project Structure
```
src/
├── controllers/     # Route handlers
├── middleware/      # Express middleware
├── routes/         # API route definitions  
├── services/       # Business logic & integrations
├── types/          # TypeScript type definitions
└── utils/          # Helper functions

supabase/
├── functions/      # Edge Functions (AI features)
└── migrations/     # Database schema changes
```

### Scripts

- `npm run dev` - Start development server with hot reload
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run db:generate-types` - Generate TypeScript types from DB
- `npm run db:migrate` - Run database migrations
- `npm run functions:serve` - Serve Edge Functions locally
- `npm run functions:deploy` - Deploy Edge Functions

### Environment Variables

Key environment variables (see `.env.example`):

- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key for server operations
- `ANTHROPIC_API_KEY` - Claude AI API key
- `WHOOP_CLIENT_ID` / `WHOOP_CLIENT_SECRET` - Whoop integration
- `STRAVA_CLIENT_ID` / `STRAVA_CLIENT_SECRET` - Strava integration

## Deployment

### Supabase Edge Functions
```bash
supabase functions deploy generate-affirmation --project-ref your-ref
supabase functions deploy generate-insights --project-ref your-ref
```

### Express Server
Deploy to your preferred platform (Railway, Render, Fly.io, etc.)

Ensure environment variables are set in production.

## Security

- Row Level Security (RLS) enabled on all tables
- JWT token authentication via Supabase Auth
- Input validation with Zod schemas
- Rate limiting on AI endpoints
- CORS configuration for allowed origins
- Helmet.js for security headers

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

---

Built with ❤️ for athletes who want to optimize their mental game.
