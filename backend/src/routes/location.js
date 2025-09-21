const express = require('express');
const router = express.Router();
const LocationTracking = require('../models/LocationTracking');
const Assignment = require('../models/Assignment');

// @route   POST /api/location/update
// @desc    Update driver location
// @access  Private
router.post('/update', async (req, res) => {
  try {
    const { driverId, busNumber, latitude, longitude, accuracy, speed } = req.body;

    // Validate required fields
    if (!driverId || !busNumber || !latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Driver ID, bus number, latitude, and longitude are required'
      });
    }

    console.log(`🚗 Location update request from driver: ${driverId}`);

    // Check driver assignment and time validation
    const assignment = await Assignment.findActiveByDriverId(driverId);
    if (!assignment) {
      console.log(`❌ No active assignment found for driver: ${driverId}`);
      return res.status(403).json({
        success: false,
        message: 'No active assignment found. Please contact administrator.',
        code: 'NO_ASSIGNMENT'
      });
    }

    // Validate tracking time window
    const timeValidation = assignment.isTrackingAllowed();
    if (!timeValidation.allowed) {
      console.log(`❌ Tracking not allowed for driver ${driverId}: ${timeValidation.reason}`);
      return res.status(403).json({
        success: false,
        message: timeValidation.reason,
        code: 'TRACKING_NOT_ALLOWED',
        trackingWindow: assignment.getTrackingWindow(),
        timeUntilStart: timeValidation.timeUntilStart,
        timeAfterEnd: timeValidation.timeAfterEnd
      });
    }

    console.log(`✅ Time validation passed for driver: ${driverId}`);

    // Create location tracking entry
    const locationUpdate = new LocationTracking({
      driverId,
      busNumber,
      assignmentId: assignment.id, // Add assignment ID from the found assignment
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
      accuracy: parseFloat(accuracy) || 0,
      speed: parseFloat(speed) || 0,
      timestamp: new Date()
    });

    await locationUpdate.save();

    res.json({
      success: true,
      message: 'Location updated successfully',
      data: {
        id: locationUpdate.id,
        timestamp: locationUpdate.timestamp,
        latitude: locationUpdate.latitude,
        longitude: locationUpdate.longitude
      }
    });

  } catch (error) {
    console.error('Location update error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update location'
    });
  }
});

// @route   GET /api/location/history/:driverId
// @desc    Get location history for driver
// @access  Private
router.get('/history/:driverId', async (req, res) => {
  try {
    const { driverId } = req.params;
    const { limit = 50 } = req.query;

    const locationHistory = await LocationTracking.getLocationHistory(
      driverId, 
      parseInt(limit)
    );

    res.json({
      success: true,
      data: locationHistory.map(location => location.toJSON()),
      count: locationHistory.length
    });

  } catch (error) {
    console.error('Location history error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch location history'
    });
  }
});

// @route   GET /api/location/live/:driverId
// @desc    Get current live location for driver
// @access  Private
router.get('/live/:driverId', async (req, res) => {
  try {
    const { driverId } = req.params;

    const liveLocation = await LocationTracking.getDriverLiveLocation(driverId);

    if (!liveLocation) {
      return res.status(404).json({
        success: false,
        message: 'No live location found for driver'
      });
    }

    res.json({
      success: true,
      data: liveLocation
    });

  } catch (error) {
    console.error('Live location error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch live location'
    });
  }
});

// @route   POST /api/location/batch
// @desc    Batch update multiple location points
// @access  Private
router.post('/batch', async (req, res) => {
  try {
    const { locations } = req.body;

    if (!Array.isArray(locations) || locations.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Locations array is required'
      });
    }

    // Validate each location entry
    const validLocations = locations.filter(loc => 
      loc.driverId && loc.busNumber && loc.latitude && loc.longitude
    );

    if (validLocations.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No valid location entries found'
      });
    }

    await LocationTracking.saveBatch(validLocations);

    res.json({
      success: true,
      message: `Batch updated ${validLocations.length} locations`,
      processed: validLocations.length,
      total: locations.length
    });

  } catch (error) {
    console.error('Batch location update error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to batch update locations'
    });
  }
});

// @route   GET /api/location/nearby
// @desc    Get nearby drivers within radius
// @access  Private
router.get('/nearby', async (req, res) => {
  try {
    const { latitude, longitude, radius = 5 } = req.query; // radius in km

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }

    const liveLocations = await LocationTracking.getLiveLocations();
    const nearbyDrivers = [];

    const centerLat = parseFloat(latitude);
    const centerLng = parseFloat(longitude);
    const maxRadius = parseFloat(radius);

    // Calculate distance for each driver
    liveLocations.forEach(location => {
      const distance = LocationTracking.calculateDistance(
        centerLat, centerLng,
        location.latitude, location.longitude
      );

      if (distance <= maxRadius) {
        nearbyDrivers.push({
          ...location,
          distance: distance.toFixed(2)
        });
      }
    });

    // Sort by distance
    nearbyDrivers.sort((a, b) => parseFloat(a.distance) - parseFloat(b.distance));

    res.json({
      success: true,
      data: nearbyDrivers,
      count: nearbyDrivers.length,
      searchRadius: maxRadius
    });

  } catch (error) {
    console.error('Nearby drivers error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to find nearby drivers'
    });
  }
});

// @route   GET /api/location/tracking-status/:driverId
// @desc    Check if driver can start tracking (time validation)
// @access  Private
router.get('/tracking-status/:driverId', async (req, res) => {
  try {
    const { driverId } = req.params;

    console.log(`🕐 Checking tracking status for driver: ${driverId}`);

    // Get driver assignment
    const assignment = await Assignment.findActiveByDriverId(driverId);
    if (!assignment) {
      return res.status(404).json({
        success: false,
        message: 'No active assignment found',
        code: 'NO_ASSIGNMENT'
      });
    }

    // Check time validation
    const timeValidation = assignment.isTrackingAllowed();
    const trackingWindow = assignment.getTrackingWindow();

    res.json({
      success: true,
      data: {
        canStartTracking: timeValidation.allowed,
        reason: timeValidation.reason,
        trackingWindow: trackingWindow,
        assignment: {
          assignmentId: assignment.assignmentId,
          startTime: assignment.startTime,
          busId: assignment.busId
        },
        timeUntilStart: timeValidation.timeUntilStart,
        timeAfterEnd: timeValidation.timeAfterEnd,
        currentTime: new Date().toLocaleTimeString('en-IN', { hour12: false })
      }
    });

  } catch (error) {
    console.error('Tracking status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to check tracking status'
    });
  }
});

module.exports = router;