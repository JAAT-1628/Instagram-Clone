const jwt = require('jsonwebtoken');
const { StatusCodes } = require('http-status-codes');
const User = require('../models/usersModel');

const authMiddleware = async (req, res, next) => {
  // Get token from header
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(StatusCodes.UNAUTHORIZED).json({
      success: false,
      message: 'Authentication invalid'
    });
  }
  
  const token = authHeader.split(' ')[1];
  
  try {
    // Verify token
    const decoded = jwt.verify(token, process.env.TOKEN_SECRET);
    
    // Add user to request object with both id and _id for compatibility
    req.user = { 
      id: decoded.userId,
      _id: decoded.userId,
      username: decoded.username 
    };
    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    return res.status(StatusCodes.UNAUTHORIZED).json({
      success: false,
      message: 'Authentication invalid'
    });
  }
};

module.exports = authMiddleware;