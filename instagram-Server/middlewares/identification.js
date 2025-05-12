const jwt = require('jsonwebtoken')

exports.identifier = (req, res, next) => {
    let token
    if(req.headers.client === 'not-browser') {
        token = req.headers.authorization
    } else {
        token = req.cookies['Authorization']
    }

    if(!token) {
        return res.status(403).json({ message: 'Unauthorized', success: false })
    }

    try {
        const userToken = token.split(' ')[1]
        const jwtVerified = jwt.verify(userToken, process.env.TOKEN_SECRET)
        if(jwtVerified) {
            req.user = { userId: jwtVerified.userId }; 
            next()
        } else {
            throw new Error('error in the token')
        }
    } catch (error) {
        return res.status(500).json({ message: 'An error occured in identifier', success: false })
    }
}