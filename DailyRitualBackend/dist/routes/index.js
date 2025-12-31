import { Router } from 'express';
import { DailyEntriesController } from '../controllers/dailyEntries.js';
import { TrainingPlansController } from '../controllers/trainingPlans.js';
import { InsightsController } from '../controllers/insights.js';
import { JournalController } from '../controllers/journalEntries.js';
import { authenticateToken } from '../middleware/auth.js';
import { DashboardController } from '../controllers/dashboard.js';
const router = Router();
router.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '1.0.0'
    });
});
router.use(['/profile', '/daily-entries', '/training-plans', '/insights', '/journal'], authenticateToken);
router.get('/profile', DashboardController.getUserProfile);
router.put('/profile', DashboardController.updateUserProfile);
router.get('/daily-entries', DailyEntriesController.getDailyEntries);
router.get('/daily-entries/batch', DailyEntriesController.getBatchDailyEntries);
router.post('/daily-entries/batch', DailyEntriesController.getBatchDailyEntries);
router.get('/daily-entries/batch/with-plans', DailyEntriesController.getBatchDailyEntriesWithPlans);
router.post('/daily-entries/batch/with-plans', DailyEntriesController.getBatchDailyEntriesWithPlans);
router.get('/daily-entries/:date', DailyEntriesController.getDailyEntry);
router.get('/daily-entries/:date/with-plans', DailyEntriesController.getDailyEntryWithPlans);
router.get('/daily-entries/:date/quote', DailyEntriesController.getDailyQuote);
router.post('/daily-entries/:date/morning', DailyEntriesController.completeMorningRitual);
router.post('/daily-entries/:date/evening', DailyEntriesController.completeEveningReflection);
router.delete('/daily-entries/:date', DailyEntriesController.deleteDailyEntry);
router.get('/training-plans', TrainingPlansController.list);
router.get('/training-plans/range', TrainingPlansController.listInRange);
router.get('/training-plans/:id', TrainingPlansController.get);
router.post('/training-plans', TrainingPlansController.create);
router.put('/training-plans/:id', TrainingPlansController.update);
router.delete('/training-plans/:id', TrainingPlansController.remove);
router.get('/insights', InsightsController.getInsights);
router.get('/insights/stats', InsightsController.getInsightsStats);
router.post('/insights/:id/read', InsightsController.markAsRead);
router.get('/journal', JournalController.getJournalEntries);
router.post('/journal', JournalController.createJournalEntry);
router.get('/journal/:id', JournalController.getJournalEntry);
router.put('/journal/:id', JournalController.updateJournalEntry);
router.delete('/journal/:id', JournalController.deleteJournalEntry);
export default router;
//# sourceMappingURL=index.js.map