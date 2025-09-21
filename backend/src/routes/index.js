const express = require('express');
const router = express.Router();

// Import route modules
const authRoutes = require('./auth');
const busRoutes = require('./bus');
const locationRoutes = require('./location');
const sosRoutes = require('./sos');
const etaRoutes = require('./eta');
const assignmentRoutes = require('./assignment');

// Health check endpoint
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'API is healthy',
    timestamp: new Date().toISOString()
  });
});

// Route modules
router.use('/auth', authRoutes);
router.use('/bus', busRoutes);
router.use('/location', locationRoutes);
router.use('/sos', sosRoutes);
router.use('/eta', etaRoutes);
router.use('/assignment', assignmentRoutes);

module.exports = router;
