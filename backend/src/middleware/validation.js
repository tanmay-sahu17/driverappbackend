const Joi = require('joi');

// Validation schemas
const schemas = {
  // Authentication schemas
  register: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().min(6).required(),
    driverName: Joi.string().min(2).max(50).required(),
    phoneNumber: Joi.string().pattern(/^[+]?[1-9]\d{1,14}$/).required(),
    licenseNumber: Joi.string().min(5).max(20).required(),
    operatorId: Joi.string().optional()
  }),

  verify: Joi.object({
    idToken: Joi.string().required()
  }),

  // Location schemas
  locationUpdate: Joi.object({
    driverId: Joi.string().required(),
    busNumber: Joi.string().required(),
    latitude: Joi.number().min(-90).max(90).required(),
    longitude: Joi.number().min(-180).max(180).required(),
    accuracy: Joi.number().min(0).optional(),
    speed: Joi.number().min(0).optional()
  }),

  batchLocation: Joi.object({
    locations: Joi.array().items(
      Joi.object({
        driverId: Joi.string().required(),
        busNumber: Joi.string().required(),
        latitude: Joi.number().min(-90).max(90).required(),
        longitude: Joi.number().min(-180).max(180).required(),
        accuracy: Joi.number().min(0).optional(),
        speed: Joi.number().min(0).optional(),
        timestamp: Joi.date().optional()
      })
    ).min(1).max(100).required()
  }),

  // SOS schemas
  sosAlert: Joi.object({
    driverId: Joi.string().required(),
    busNumber: Joi.string().required(),
    latitude: Joi.number().min(-90).max(90).required(),
    longitude: Joi.number().min(-180).max(180).required(),
    emergencyMessage: Joi.string().max(500).optional()
  }),

  // Bus schemas
  busAssignment: Joi.object({
    busNumber: Joi.string().required(),
    driverId: Joi.string().required()
  })
};

// Validation middleware factory
const validateRequest = (schema) => {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.body, {
      allowUnknown: false,
      stripUnknown: true
    });

    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: error.details.map(detail => ({
          field: detail.path.join('.'),
          message: detail.message
        }))
      });
    }

    // Replace req.body with validated and sanitized data
    req.body = value;
    next();
  };
};

// Query parameter validation
const validateQuery = (schema) => {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.query, {
      allowUnknown: true,
      stripUnknown: false
    });

    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Query validation error',
        errors: error.details.map(detail => ({
          field: detail.path.join('.'),
          message: detail.message
        }))
      });
    }

    req.query = value;
    next();
  };
};

// Common query schemas
const querySchemas = {
  pagination: Joi.object({
    limit: Joi.number().integer().min(1).max(100).default(50),
    offset: Joi.number().integer().min(0).default(0)
  }),

  locationQuery: Joi.object({
    latitude: Joi.number().min(-90).max(90).required(),
    longitude: Joi.number().min(-180).max(180).required(),
    radius: Joi.number().min(0.1).max(100).default(5)
  })
};

module.exports = {
  schemas,
  validateRequest,
  validateQuery,
  querySchemas
};