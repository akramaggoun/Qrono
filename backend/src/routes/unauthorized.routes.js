const express = require('express');
const router = express.Router();
const unauthorizedController = require('../controllers/unauthorized.controller');
const authMiddleware = require('../middleware/auth.middleware');
const { checkRole } = require('../middleware/role.middleware');

router.use(authMiddleware);

router.get('/', checkRole(['admin']), unauthorizedController.getLogs);

module.exports = router;
