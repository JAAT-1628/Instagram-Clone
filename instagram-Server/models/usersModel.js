const mongoose = require('mongoose')

const userSchema = mongoose.Schema({
    username: {
        type: String,
        required: [true, 'Username is required!'],
        trim: true,
        unique: [true, 'Username already exists'],
        lowercase: true
    },
    email: {
        type: String,
        required: [true, 'Email is required!'],
        trim: true,
        unique: [true, 'Email already exists'],
        minLength: [8, 'Invalid email'],
        lowercase: true
    },
    password: {
        type: String,
        required: [true, 'Password must be provided!'],
        trim: true,
        minLength: [8, 'Password should contains 8 or more letters'],
        select: false
    },
    fullName: {
        type: String,
        trim: true
    },
    bio: {
        type: String,
        maxlength: 200
    },
    profileImage: {
        type: String,
        default: 'default-profile.png'
    },
    posts: [
        {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Post',
        }
    ],
    followers: [
        {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        }
    ],
    following: [
        {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        }
    ],
    chats: [
        {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Chat',
        }
    ],
    verified: {
        type: Boolean,
        default: false
    },
    verificationCode: {
        type: String,
        select: false
    },
    verificationCodeValidation: {
        type: Number,
        select: false
    },
    forgotPasswordCode: {
        type: String,
        select: false
    },
    forgotPasswordCodeValidation: {
        type: Number,
        select: false
    },

}, { timestamps: true })


module.exports = mongoose.model('User', userSchema)