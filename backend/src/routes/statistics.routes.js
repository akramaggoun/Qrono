const express = require('express');
const router = express.Router();
const statsController = require('../controllers/statistics.controller');
const authMiddleware = require('../middleware/auth.middleware');
const { checkRole } = require('../middleware/role.middleware');

router.use(authMiddleware);

router.get('/', checkRole(['admin']), statsController.getStatistics);

module.exports = router;
