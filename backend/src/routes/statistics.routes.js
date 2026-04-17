const express = require('express');
const router = express.Router();
const statsController = require('../controllers/statistics.controller');
const authMiddleware = require('../middleware/auth.middleware');
const { checkRole } = require('../middleware/role.middleware');

router.use(authMiddleware);
router.use(checkRole(['admin'])); // All stats routes are admin-only

router.get('/', statsController.getStatistics);
router.get('/student/:id', statsController.getStudentStats);
router.get('/professor/:id', statsController.getProfessorStats);
router.get('/group/:id', statsController.getGroupStats);
router.get('/lab/:id', statsController.getLabStats);

module.exports = router;
