const express = require('express');
const router = express.Router();
const statsController = require('../controllers/statistics.controller');
const authMiddleware = require('../middleware/auth.middleware');
const { checkRole } = require('../middleware/role.middleware');

router.use(authMiddleware);

router.get('/', checkRole(['admin']), statsController.getStatistics);
router.get('/professor', checkRole(['professor']), statsController.getProfessorStats);

router.get('/student/:studentId', checkRole(['admin', 'professor']), statsController.getStudentStats);
router.get('/student/:studentId/absences', checkRole(['admin', 'professor', 'student']), statsController.getDetailedAbsences);

router.get('/check-exclusion', checkRole(['admin', 'professor']), statsController.checkExclusion);

router.post('/exclude', checkRole(['admin', 'professor']), statsController.toggleExclusion);

module.exports = router;
