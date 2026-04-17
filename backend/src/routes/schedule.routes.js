const express = require('express');
const router = express.Router();
const scheduleController = require('../controllers/schedule.controller');
const authMiddleware = require('../middleware/auth.middleware');
const { checkRole } = require('../middleware/role.middleware');

router.use(authMiddleware);

router.get('/', checkRole(['admin', 'professor']), scheduleController.getAllSchedules);
router.post('/', checkRole(['admin']), scheduleController.createSchedule);
router.put('/:id', checkRole(['admin']), scheduleController.updateSchedule);
router.delete('/:id', checkRole(['admin']), scheduleController.deleteSchedule);

module.exports = router;
