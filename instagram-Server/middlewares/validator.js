const Joi = require('joi')

exports.signupValidator = Joi.object({
    username: Joi.string().min(3).max(30).required(),
    email: Joi.string().min(10).max(60).required().email({ tlds: { allow: ['com', 'net'] } }),
    password: Joi.string().required().pattern(new RegExp('^.{8,}$'))
})

exports.signinValidator = Joi.object({
    email: Joi.string().min(10).max(60).required().email({ tlds: { allow: ['com', 'net'] } }),
    password: Joi.string().required().pattern(new RegExp('^.{8,}$'))
})

exports.verificatonCodeValidator = Joi.object({
    email: Joi.string().min(10).max(60).required().email({ tlds: { allow: ['com', 'net'] } }),
    providedCode: Joi.number().required()
})

exports.changePasswordValidator = Joi.object({
    newPassword: Joi.string().required().pattern(new RegExp('^.{8,}$')),
    oldPassword: Joi.string().required().pattern(new RegExp('^.{8,}$'))

})

exports.forgotPasswordValidator = Joi.object({
    email: Joi.string().min(10).max(60).required().email({ tlds: { allow: ['com', 'net'] } }),
    providedCode: Joi.number().required(),
    newPassword: Joi.string().required().pattern(new RegExp('^.{8,}$'))
})

exports.createPostValidator = Joi.object({
    description: Joi.string().min(3).max(300).required(),
    userId: Joi.string().required()
})