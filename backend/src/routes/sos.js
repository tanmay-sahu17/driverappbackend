const express = require('express');
const router = express.Router();
const SosAlert = require('../models/SosAlert');

// @route   POST /api/sos/alert
// @desc    Create SOS emergency alert
// @access  Private
router.post('/alert', async (req, res) => {
  try {
    console.log('SOS Alert Request received:', req.body);
    
    const { 
      driverId, 
      busNumber, 
      latitude, 
      longitude, 
      emergencyMessage 
    } = req.body;

    // Validate required fields
    if (!driverId || !busNumber || !latitude || !longitude) {
      console.log('SOS Alert validation failed - missing fields:', {
        driverId: !!driverId,
        busNumber: !!busNumber,
        latitude: !!latitude,
        longitude: !!longitude
      });
      return res.status(400).json({
        success: false,
        message: 'Driver ID, bus number, and location are required'
      });
    }

    // Validate coordinates
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    
    if (isNaN(lat) || isNaN(lng) || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      console.log('SOS Alert validation failed - invalid coordinates:', { latitude, longitude });
      return res.status(400).json({
        success: false,
        message: 'Invalid latitude or longitude coordinates'
      });
    }

    // Create SOS alert
    const sosAlert = new SosAlert({
      driverId,
      busNumber,
      latitude: lat,
      longitude: lng,
      emergencyMessage: emergencyMessage || 'Emergency SOS Alert from Driver',
      timestamp: new Date(),
      status: 'active'
    });

    console.log('Creating SOS Alert:', {
      id: sosAlert.id,
      driverId: sosAlert.driverId,
      busNumber: sosAlert.busNumber,
      coordinates: [sosAlert.latitude, sosAlert.longitude]
    });

    await sosAlert.createAlert();

    // Log the alert creation
    console.log(`🚨 SOS Alert created successfully: ${sosAlert.id} from driver ${driverId}`);

    res.status(201).json({
      success: true,
      message: 'SOS alert sent successfully',
      data: {
        alertId: sosAlert.id,
        timestamp: sosAlert.timestamp,
        status: sosAlert.status,
        location: {
          latitude: sosAlert.latitude,
          longitude: sosAlert.longitude
        }
      }
    });

  } catch (error) {
    console.error('SOS alert creation error:', error.message);
    console.error('Full SOS error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send SOS alert',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// @route   GET /api/sos/alerts/:driverId
// @desc    Get active SOS alerts for driver
// @access  Private
router.get('/alerts/:driverId', async (req, res) => {
  try {
    const { driverId } = req.params;

    const activeAlerts = await SosAlert.getActiveAlerts(driverId);

    res.json({
      success: true,
      data: activeAlerts.map(alert => alert.toJSON()),
      count: activeAlerts.length
    });

  } catch (error) {
    console.error('Get SOS alerts error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch SOS alerts'
    });
  }
});

// @route   PUT /api/sos/resolve/:alertId
// @desc    Resolve SOS alert
// @access  Private
router.put('/resolve/:alertId', async (req, res) => {
  try {
    const { alertId } = req.params;

    // Find alert by ID
    const alert = await SosAlert.findById(alertId);
    
    if (!alert) {
      return res.status(404).json({
        success: false,
        message: 'SOS alert not found'
      });
    }

    if (alert.status !== 'active') {
      return res.status(400).json({
        success: false,
        message: 'Alert is already resolved'
      });
    }

    await alert.resolve();

    res.json({
      success: true,
      message: 'SOS alert resolved successfully',
      data: {
        alertId: alert.id,
        status: alert.status,
        resolvedAt: alert.updatedAt
      }
    });

  } catch (error) {
    console.error('SOS alert resolve error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to resolve SOS alert'
    });
  }
});

// @route   GET /api/sos/all
// @desc    Get all active SOS alerts (for control room)
// @access  Private (Admin only)
router.get('/all', async (req, res) => {
  try {
    const { status = 'active', limit = 50 } = req.query;

    let alerts;
    
    if (status === 'active') {
      alerts = await SosAlert.getAllActiveAlerts();
    } else {
      // Get alerts by status (you'll need to implement this method)
      alerts = await SosAlert.getAlertHistory(null, parseInt(limit));
    }

    res.json({
      success: true,
      data: alerts.map(alert => alert.toJSON()),
      count: alerts.length,
      filter: { status }
    });

  } catch (error) {
    console.error('Get all SOS alerts error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch SOS alerts'
    });
  }
});

// @route   GET /api/sos/history/:driverId
// @desc    Get SOS alert history for driver
// @access  Private
router.get('/history/:driverId', async (req, res) => {
  try {
    const { driverId } = req.params;
    const { limit = 20 } = req.query;

    const alertHistory = await SosAlert.getAlertHistory(driverId, parseInt(limit));

    res.json({
      success: true,
      data: alertHistory.map(alert => alert.toJSON()),
      count: alertHistory.length
    });

  } catch (error) {
    console.error('SOS history error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch SOS alert history'
    });
  }
});

// @route   GET /api/sos/status
// @desc    Get SOS system status and statistics
// @access  Private
router.get('/status', async (req, res) => {
  try {
    // Get basic statistics
    const activeAlerts = await SosAlert.getAllActiveAlerts();
    
    const stats = {
      activeAlerts: activeAlerts.length,
      lastAlert: activeAlerts.length > 0 ? activeAlerts[0].timestamp : null,
      systemStatus: 'operational'
    };

    res.json({
      success: true,
      data: stats
    });

  } catch (error) {
    console.error('SOS status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get SOS status'
    });
  }
});

module.exports = router;