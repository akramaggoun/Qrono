const express = require('express');
const router = express.Router();
const scheduleController = require('../controllers/schedule.controller');
const authMiddleware = require('../middleware/auth.middleware');
const { checkRole } = require('../middleware/role.middleware');

router.use(authMiddleware);

// Admin only
router.post('/', checkRole(['admin']), scheduleController.createSchedule);
router.get('/', checkRole(['admin', 'professor']), scheduleController.getAllSchedules);
router.get('/:id', checkRole(['admin', 'professor']), scheduleController.getScheduleById);
router.patch('/:id', checkRole(['admin']), scheduleController.updateSchedule);
router.delete('/:id', checkRole(['admin']), scheduleController.deleteSchedule);

// Generating sessions from a schedule
router.post('/:id/generate-sessions', checkRole(['admin']), scheduleController.generateSessionsFromSchedule);

module.exports = router;
