const { hash, compare } = require("bcryptjs")
const { createHmac } = require('crypto')

exports.doHash = (value, saltValue) => {
    return result = hash(value, saltValue)
}

exports.doHashValidation = (value, hashedValue) => {
    return result = compare(value, hashedValue)
}

exports.hmacProcess = (value, key) => {
    return result = createHmac('sha256', key).update(value).digest('hex')
}