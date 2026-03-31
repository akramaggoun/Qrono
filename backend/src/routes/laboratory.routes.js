const express = require('express');
const router = express.Router();
const labController = require('../controllers/laboratory.controller');
const authMiddleware = require('../middleware/auth.middleware');
const { checkRole } = require('../middleware/role.middleware');

router.use(authMiddleware);

router.get('/', checkRole(['admin', 'professor']), labController.getAllLaboratories);

router.post('/', checkRole(['admin']), labController.createLaboratory);
router.put('/:id', checkRole(['admin']), labController.updateLaboratory);
router.delete('/:id', checkRole(['admin']), labController.deleteLaboratory);

module.exports = router;
