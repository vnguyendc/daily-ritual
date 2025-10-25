import { Router } from 'express';
import { DailyEntriesController } from '../controllers/dailyEntries.js';
import { TrainingPlansController } from '../controllers/trainingPlans.js';
import { InsightsController } from '../controllers/insights.js';
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
router.use(['/profile', '/daily-entries', '/training-plans', '/insights'], authenticateToken);
router.get('/profile', DashboardController.getUserProfile);
router.put('/profile', DashboardController.updateUserProfile);
router.get('/daily-entries', DailyEntriesController.getDailyEntries);
router.get('/daily-entries/:date', DailyEntriesController.getDailyEntry);
router.get('/daily-entries/:date/with-plans', DailyEntriesController.getDailyEntryWithPlans);
router.get('/daily-entries/:date/quote', DailyEntriesController.getDailyQuote);
router.post('/daily-entries/:date/morning', DailyEntriesController.completeMorningRitual);
router.post('/daily-entries/:date/evening', DailyEntriesController.completeEveningReflection);
router.delete('/daily-entries/:date', DailyEntriesController.deleteDailyEntry);
router.get('/training-plans', TrainingPlansController.list);
router.post('/training-plans', TrainingPlansController.create);
router.put('/training-plans/:id', TrainingPlansController.update);
router.delete('/training-plans/:id', TrainingPlansController.remove);
router.get('/insights', InsightsController.getInsights);
router.get('/insights/stats', InsightsController.getInsightsStats);
router.post('/insights/:id/read', InsightsController.markAsRead);
export default router;
//# sourceMappingURL=index.js.map