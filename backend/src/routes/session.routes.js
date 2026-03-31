const express = require('express');
const router = express.Router();
const sessionController = require('../controllers/session.controller');
const authMiddleware = require('../middleware/auth.middleware');
const { checkRole } = require('../middleware/role.middleware');

router.use(authMiddleware);

router.post('/', checkRole(['professor', 'admin']), sessionController.createSession);

router.get('/my-sessions', checkRole(['professor']), sessionController.getMySessions);

router.patch('/:id/close', checkRole(['professor', 'admin']), sessionController.closeSession);

router.get('/:id/attendances', checkRole(['professor', 'admin']), sessionController.getSessionAttendances);

module.exports = router;
