import { Router } from 'express';
import { DailyEntriesController } from '../controllers/dailyEntries.js';
const router = Router();
router.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '1.0.0'
    });
});
router.get('/daily-entries', DailyEntriesController.getDailyEntries);
router.get('/daily-entries/:date', DailyEntriesController.getDailyEntry);
router.post('/daily-entries/:date/morning', DailyEntriesController.completeMorningRitual);
router.post('/daily-entries/:date/evening', DailyEntriesController.completeEveningReflection);
router.delete('/daily-entries/:date', DailyEntriesController.deleteDailyEntry);
export default router;
//# sourceMappingURL=index.js.map