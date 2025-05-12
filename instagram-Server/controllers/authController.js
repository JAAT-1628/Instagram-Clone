const jwt = require("jsonwebtoken");
const { signupValidator, signinValidator, verificatonCodeValidator, changePasswordValidator, forgotPasswordValidator } = require("../middlewares/validator");
const User = require('../models/usersModel');
const { doHash, doHashValidation, hmacProcess } = require("../utils/hashing");
const transport = require("../middlewares/sendMail");

exports.signup = async (req, res) => {
    const { username, email, password } = req.body

    try {
        const { error, value } = signupValidator.validate({ username, email, password })
        if (error) {
            return res.status(401).json({ message: error.details[0].message, success: false })
        }

        const existingUser = await User.findOne({ email })
        if (existingUser) {
            return res.status(401).json({ message: 'User with this email already exists', success: false })
        }

        const hashedPassword = await doHash(password, 12)

        const newUser = new User({ username, email, password: hashedPassword })
        const result = await newUser.save()
        result.password = undefined

        res.status(201).json({ message: 'Account created successfully', success: true, result })

    } catch (error) {
        return res.status(500).json({ message: 'An error occurred while signup', success: false });
    }
}

exports.signin = async (req, res) => {
    const { email, password } = req.body

    try {
        const { error, value } = signinValidator.validate({ email, password })
        if (error) {
            return res.status(401).json({ message: error.details[0].message, success: false })
        }

        const existingUser = await User.findOne({ email }).select('+password')
        if (!existingUser) {
            return res.status(401).json({ message: 'User does not exists!', success: false })
        }

        const result = await doHashValidation(password, existingUser.password)
        if (!result) {
            return res.status(401).json({ message: 'Invalid password!', success: false })
        }

        const token = jwt.sign({
            userId: existingUser._id,
            email: existingUser.email,
            verified: existingUser.verified,
        }, process.env.TOKEN_SECRET, { expiresIn: '8h' })

        res
            .cookie('Authorization', 'Bearer ' + token, {
                expires: new Date(Date.now() + 8 * 3600000),
                httpOnly: process.env.NODE_ENV === 'production',
                secure: process.env.NODE_ENV === 'production',
            })
            .json({
                success: true,
                token,
                message: 'logged in successfully',
                userId: existingUser._id
            });
    } catch (error) {
        return res.status(500).json({ message: 'An error occurred while signin', success: false });
    }
}

exports.signout = async (req, res) => {
    res.clearCookie('Authorization').status(200).json({ message: 'Logged out', success: true })
}

exports.sendVerificationCode = async (req, res) => {
    const { email } = req.body
    try {
        const existingUser = await User.findOne({ email })
        if (!existingUser) {
            return res.status(404).json({ message: 'User not found!', success: false })
        }

        if (existingUser.verified) {
            return res.status(400).json({ message: 'You are already verified', success: false })
        }

        const codeValue = Math.floor(Math.random() * 1000000).toString()
        let info = await transport.sendMail({
            from: process.env.NODE_CODE_SENDING_EMAIL_ADDRESS,
            to: existingUser.email,
            subject: 'verification code',
            html: '<h1>' + codeValue + '</h1>'
        })

        if (info.accepted[0] === existingUser.email) {
            const hashedCodeValue = hmacProcess(codeValue, process.env.HMAC_VERIFICATION_CODE_SECRET)
            existingUser.verificationCode = hashedCodeValue
            existingUser.verificationCodeValidation = Date.now()
            await existingUser.save()
            return res.status(200).json({ message: 'Code sent', success: true })
        }

        res.status(400).json({ message: 'Failed to sent code', success: false })

    } catch (error) {
        return res.status(500).json({ message: 'An error occurred while sendingVerificationCode', success: false });
    }
}

exports.verifyVerificationCode = async (req, res) => {
    const { email, providedCode } = req.body
    try {
        const { error, value } = verificatonCodeValidator.validate({ email, providedCode })
        if (error) {
            return res.status(401).json({ message: error.details[0].message, success: false })
        }

        const codeValue = providedCode.toString()
        const existingUser = await User.findOne({ email }).select('+verificationCode +verificationCodeValidation')
        if (!existingUser) {
            return res.status(401).json({ message: 'User does not exists!', success: false })
        }

        if (existingUser.verified) {
            return res.status(400).json({ message: 'You are already verified', success: false })
        }

        if (!existingUser.verificationCode || !existingUser.verificationCodeValidation) {
            return res.status(400).json({ message: 'something went wrong with the code', success: false })
        }

        if (Date.now() - existingUser.verificationCodeValidation > 5 * 60 * 1000) {
            return res.status(400).json({ message: 'code has been expired', success: false })
        }

        const hashedCodeValue = hmacProcess(codeValue, process.env.HMAC_VERIFICATION_CODE_SECRET)

        if (hashedCodeValue === existingUser.verificationCode) {
            existingUser.verified = true
            existingUser.verificationCode = undefined
            existingUser.verificationCodeValidation = undefined
            await existingUser.save()
            return res.status(200).json({ message: 'Verification completed', success: true })
        }

        return res.status(400).json({ message: 'unknown exception', success: false })

    } catch (error) {
        return res.status(500).json({ message: 'An error occurred while verifyVerificationCode', success: false });
    }
}

exports.changePassword = async (req, res) => {
    const { userId, verified } = req.user;
    const { oldPassword, newPassword } = req.body

    try {
        const { error, value } = changePasswordValidator.validate({ oldPassword, newPassword })
        if (error) {
            return res.status(401).json({ message: error.details[0].message, success: false })
        }
        if (!verified) {
            return res.status(401).json({ message: 'You are not verified', success: false })
        }

        const existingUser = await User.findOne({ _id: userId }).select('+password')
        if (!existingUser) {
            return res.status(401).json({ message: 'User does not exists!', success: false })
        }

        const result = await doHashValidation(oldPassword, existingUser.password);
		if (!result) {
			return res.status(401).json({ success: false, message: 'Invalid password!' });
		}
		const hashedPassword = await doHash(newPassword, 12);
        existingUser.password = hashedPassword
        await existingUser.save()

        return res.status(200).json({ message: 'Password updated', success: true })

    } catch (error) {
        return res.status(500).json({ message: 'An error occurred while changingPassword', success: false });
    }
}

exports.sendForgotPasswordVerificationCode = async (req, res) => {
    const { email } = req.body
    try {
        const existingUser = await User.findOne({ email })
        if (!existingUser) {
            return res.status(404).json({ message: 'User not found!', success: false })
        }

        const codeValue = Math.floor(Math.random() * 1000000).toString()
        let info = await transport.sendMail({
            from: process.env.NODE_CODE_SENDING_EMAIL_ADDRESS,
            to: existingUser.email,
            subject: 'Code for Forgot Password',
            html: '<h1>' + codeValue + '</h1>'
        })

        if (info.accepted[0] === existingUser.email) {
            const hashedCodeValue = hmacProcess(codeValue, process.env.HMAC_VERIFICATION_CODE_SECRET)
            existingUser.forgotPasswordCode = hashedCodeValue
            existingUser.forgotPasswordCodeValidation = Date.now()
            await existingUser.save()
            return res.status(200).json({ message: 'Code sent', success: true })
        }

        res.status(400).json({ message: 'Failed to sent code', success: false })

    } catch (error) {
        return res.status(500).json({ message: 'An error occurred while sendForgotPasswordVerificationCode', success: false });
    }
}

exports.verifyForgotPasswordVerificationCode = async (req, res) => {
    const { email, providedCode, newPassword } = req.body
    try {
        const { error, value } = forgotPasswordValidator.validate({ email, providedCode, newPassword })
        if (error) {
            return res.status(401).json({ message: error.details[0].message, success: false })
        }

        const codeValue = providedCode.toString()
        const existingUser = await User.findOne({ email }).select('+forgotPasswordCode +forgotPasswordCodeValidation')
        if (!existingUser) {
            return res.status(401).json({ message: 'User does not exists!', success: false })
        }

        if (!existingUser.forgotPasswordCode || !existingUser.forgotPasswordCodeValidation) {
            return res.status(400).json({ message: 'something went wrong with the code', success: false })
        }

        if (Date.now() - existingUser.forgotPasswordCodeValidation > 5 * 60 * 1000) {
            return res.status(400).json({ message: 'code has been expired', success: false })
        }

        const hashedCodeValue = hmacProcess(codeValue, process.env.HMAC_VERIFICATION_CODE_SECRET)

        if (hashedCodeValue === existingUser.forgotPasswordCode) {
            const hashedPassword = await doHash(newPassword, 12)
            existingUser.password = hashedPassword
            existingUser.forgotPasswordCode = undefined
            existingUser.forgotPasswordCodeValidation = undefined
            await existingUser.save()
            return res.status(200).json({ message: 'password changed successfully', success: true })
        }

        return res.status(400).json({ message: 'unknown exception', success: false })

    } catch (error) {
        return res.status(500).json({ message: 'An error occurred while verifyForgotPasswordVerificationCode', success: false });
    }
}