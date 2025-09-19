const rateLimit = require('express-rate-limit');
const config = require('../config');

// General rate limiting
const generalLimiter = rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.rateLimit.max,
  message: {
    success: false,
    message: 'Too many requests from this IP, please try again later',
    retryAfter: Math.ceil(config.rateLimit.windowMs / 1000) // seconds
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Strict rate limiting for authentication endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // Max 10 requests per window
  message: {
    success: false,
    message: 'Too many authentication attempts, please try again later',
    retryAfter: 900 // 15 minutes in seconds
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Rate limiting for SOS alerts (prevent spam)
const sosLimiter = rateLimit({
  windowMs: 5 * 60 * 1000, // 5 minutes
  max: 5, // Max 5 SOS alerts per 5 minutes
  message: {
    success: false,
    message: 'Too many SOS alerts sent, please wait before sending another alert',
    retryAfter: 300 // 5 minutes in seconds
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Rate limiting for location updates (prevent excessive updates)
const locationLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 60, // Max 60 location updates per minute (1 per second)
  message: {
    success: false,
    message: 'Too many location updates, please reduce update frequency',
    retryAfter: 60
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Rate limiting for ETA calculations (more lenient)
const etaLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 20, // Max 20 ETA requests per minute
  message: {
    success: false,
    message: 'Too many ETA requests, please wait before requesting again',
    retryAfter: 60
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Custom rate limiter based on user ID
const createUserBasedLimiter = (windowMs, maxRequests) => {
  return rateLimit({
    windowMs,
    max: maxRequests,
    keyGenerator: (req) => {
      // Use user ID if authenticated, otherwise fall back to IP
      return req.user?.uid || req.ip;
    },
    message: {
      success: false,
      message: 'Rate limit exceeded for this user',
      retryAfter: Math.ceil(windowMs / 1000)
    },
    standardHeaders: true,
    legacyHeaders: false,
  });
};

module.exports = {
  generalLimiter,
  authLimiter,
  sosLimiter,
  locationLimiter,
  etaLimiter,
  createUserBasedLimiter
};