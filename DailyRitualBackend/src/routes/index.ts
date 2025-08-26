// Main routes configuration
import { Router } from 'express'
import { DailyEntriesController } from '../controllers/dailyEntries.js'
import { WorkoutReflectionsController } from '../controllers/workoutReflections.js'
import { DashboardController } from '../controllers/dashboard.js'

const router = Router()

// Health check endpoint
router.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  })
})

// Dashboard routes
router.get('/dashboard', DashboardController.getDashboardData)
router.get('/profile', DashboardController.getUserProfile)
router.put('/profile', DashboardController.updateUserProfile)
router.get('/streaks', DashboardController.getUserStreaks)
router.get('/insights', DashboardController.getAIInsights)
router.put('/insights/:insightId/read', DashboardController.markInsightAsRead)
router.post('/insights/weekly', DashboardController.generateWeeklyInsights)

// Daily entries routes
router.get('/daily-entries', DailyEntriesController.getDailyEntries)
router.get('/daily-entries/:date', DailyEntriesController.getDailyEntry)
router.post('/daily-entries/:date/morning', DailyEntriesController.completeMorningRitual)
router.post('/daily-entries/:date/evening', DailyEntriesController.completeEveningReflection)
router.delete('/daily-entries/:date', DailyEntriesController.deleteDailyEntry)

// Workout reflections routes
router.get('/workout-reflections', WorkoutReflectionsController.getWorkoutReflections)
router.post('/workout-reflections', WorkoutReflectionsController.createWorkoutReflection)
router.get('/workout-reflections/stats', WorkoutReflectionsController.getWorkoutStats)
router.get('/workout-reflections/:id', WorkoutReflectionsController.getWorkoutReflection)
router.put('/workout-reflections/:id', WorkoutReflectionsController.updateWorkoutReflection)
router.delete('/workout-reflections/:id', WorkoutReflectionsController.deleteWorkoutReflection)

// TODO: Add these routes when controllers are implemented
// Competition routes
// router.get('/competitions', CompetitionsController.getCompetitions)
// router.post('/competitions', CompetitionsController.createCompetition)
// router.get('/competitions/:id', CompetitionsController.getCompetition)
// router.put('/competitions/:id', CompetitionsController.updateCompetition)
// router.delete('/competitions/:id', CompetitionsController.deleteCompetition)
// router.post('/competitions/:id/prep', CompetitionsController.createPrepEntry)

// Journal entries routes
// router.get('/journal', JournalController.getJournalEntries)
// router.post('/journal', JournalController.createJournalEntry)
// router.get('/journal/:id', JournalController.getJournalEntry)
// router.put('/journal/:id', JournalController.updateJournalEntry)
// router.delete('/journal/:id', JournalController.deleteJournalEntry)

// Integration routes
// router.get('/integrations', IntegrationsController.getIntegrations)
// router.post('/integrations/whoop/connect', IntegrationsController.connectWhoop)
// router.post('/integrations/strava/connect', IntegrationsController.connectStrava)
// router.post('/integrations/apple-health/sync', IntegrationsController.syncAppleHealth)
// router.post('/integrations/sync', IntegrationsController.syncAllIntegrations)

// Webhook routes
// router.post('/webhooks/whoop', WebhooksController.handleWhoopWebhook)
// router.post('/webhooks/strava', WebhooksController.handleStravaWebhook)

export default router
