// Global error handler
const errorHandler = (err, req, res, next) => {
  console.error('Error Stack:', err.stack);

  // Default error response
  let error = {
    success: false,
    message: 'Internal server error'
  };

  // Firebase Admin errors
  if (err.code && err.code.startsWith('auth/')) {
    error.message = getFirebaseErrorMessage(err.code);
    return res.status(401).json(error);
  }

  // Firestore errors
  if (err.code && err.code.includes('firestore')) {
    error.message = 'Database operation failed';
    return res.status(500).json(error);
  }

  // Validation errors (Joi)
  if (err.isJoi) {
    error.message = 'Validation error';
    error.errors = err.details.map(detail => ({
      field: detail.path.join('.'),
      message: detail.message
    }));
    return res.status(400).json(error);
  }

  // MongoDB/Database connection errors
  if (err.name === 'MongoError' || err.name === 'MongoNetworkError') {
    error.message = 'Database connection error';
    return res.status(503).json(error);
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    error.message = 'Invalid token';
    return res.status(401).json(error);
  }

  if (err.name === 'TokenExpiredError') {
    error.message = 'Token expired';
    return res.status(401).json(error);
  }

  // Custom application errors
  if (err.statusCode) {
    error.message = err.message;
    return res.status(err.statusCode).json(error);
  }

  // Network errors
  if (err.code === 'ENOTFOUND' || err.code === 'ECONNREFUSED') {
    error.message = 'Service unavailable';
    return res.status(503).json(error);
  }

  // Default 500 error
  if (process.env.NODE_ENV === 'development') {
    error.message = err.message;
    error.stack = err.stack;
  }

  res.status(500).json(error);
};

// Firebase error message mapper
const getFirebaseErrorMessage = (errorCode) => {
  const errorMessages = {
    'auth/id-token-expired': 'Authentication token has expired',
    'auth/id-token-revoked': 'Authentication token has been revoked',
    'auth/invalid-id-token': 'Invalid authentication token',
    'auth/user-not-found': 'User not found',
    'auth/user-disabled': 'User account has been disabled',
    'auth/email-already-exists': 'Email address is already registered',
    'auth/invalid-email': 'Invalid email address',
    'auth/weak-password': 'Password should be at least 6 characters',
    'auth/phone-number-already-exists': 'Phone number is already registered',
    'auth/invalid-phone-number': 'Invalid phone number format'
  };

  return errorMessages[errorCode] || 'Authentication error';
};

// 404 handler for unmatched routes
const notFoundHandler = (req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.method} ${req.originalUrl} not found`,
    availableEndpoints: {
      health: 'GET /api/health',
      docs: 'GET /api/docs',
      auth: 'POST /api/auth/*',
      location: 'POST /api/location/*',
      sos: 'POST /api/sos/*',
      bus: 'GET /api/bus/*'
    }
  });
};

// Async error wrapper
const asyncHandler = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

// Custom error class
class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

module.exports = {
  errorHandler,
  notFoundHandler,
  asyncHandler,
  AppError
};