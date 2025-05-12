const express = require('express')
const userController = require('../controllers/userController')
const { identifier } = require('../middlewares/identification')
const upload = require('../middlewares/multer')

const router = express.Router()

router.put('/upload-profile-image', identifier, upload.single('profileImage'), userController.updateUserInfo)
router.get('/', identifier, userController.loadUserInfo)
router.get('/get-all-user', identifier, userController.loadAllUsers)
router.post('/follow', identifier, userController.followUser);
router.get('/:id/follow-info', userController.getUserWithFollowInfo);
router.get('/:id', userController.findUserById);

module.exports = router