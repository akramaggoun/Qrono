const express = require('express');
const router = express.Router();
const presenceController = require('../controllers/presence.controller');
const authMiddleware = require('../middleware/auth.middleware');
const { checkRole } = require('../middleware/role.middleware');

router.use(authMiddleware);

router.post('/scan', checkRole(['student']), presenceController.scanQR);

router.get('/my-attendances', checkRole(['student']), presenceController.getMyAttendances);

module.exports = router;
