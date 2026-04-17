const express = require('express');
const router = express.Router();
const groupController = require('../controllers/group.controller');
const authMiddleware = require('../middleware/auth.middleware');
const { checkRole } = require('../middleware/role.middleware');

router.use(authMiddleware);

router.get('/', checkRole(['admin', 'professor']), groupController.getAllGroups);

router.post('/', checkRole(['admin']), groupController.createGroup);
router.put('/:id', checkRole(['admin']), groupController.updateGroup);
router.delete('/:id', checkRole(['admin']), groupController.deleteGroup);

module.exports = router;
