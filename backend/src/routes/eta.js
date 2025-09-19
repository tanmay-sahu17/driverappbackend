const express = require('express');
const router = express.Router();
const ETA = require('../models/ETA');
const { etaLimiter } = require('../middleware/rateLimiter');

// @route   POST /api/eta/calculate
// @desc    Calculate ETA between current location and destination
// @access  Private
router.post('/calculate', etaLimiter, async (req, res) => {
  try {
    const { 
      fromLatitude, 
      fromLongitude, 
      toLatitude, 
      toLongitude,
      averageSpeed = 40 // Default 40 km/h
    } = req.body;

    // Validate required fields
    if (!fromLatitude || !fromLongitude || !toLatitude || !toLongitude) {
      return res.status(400).json({
        success: false,
        message: 'From and to coordinates are required'
      });
    }

    // Calculate distance and ETA
    const distance = ETA.calculateDistance(
      parseFloat(fromLatitude),
      parseFloat(fromLongitude),
      parseFloat(toLatitude),
      parseFloat(toLongitude)
    );

    const eta = ETA.calculateETA(distance, parseFloat(averageSpeed));

    res.json({
      success: true,
      data: {
        distance: {
          meters: Math.round(distance),
          kilometers: Math.round(distance / 1000 * 100) / 100
        },
        eta: {
          minutes: Math.round(eta.minutes),
          seconds: Math.round(eta.seconds),
          formatted: eta.formatted
        },
        averageSpeed: parseFloat(averageSpeed)
      }
    });

  } catch (error) {
    console.error('ETA calculation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to calculate ETA'
    });
  }
});

// @route   POST /api/eta/route
// @desc    Calculate ETA for multiple waypoints (route)
// @access  Private
router.post('/route', async (req, res) => {
  try {
    const { waypoints, averageSpeed = 40 } = req.body;

    if (!waypoints || !Array.isArray(waypoints) || waypoints.length < 2) {
      return res.status(400).json({
        success: false,
        message: 'At least 2 waypoints are required'
      });
    }

    let totalDistance = 0;
    const routeSegments = [];

    // Calculate distance between consecutive waypoints
    for (let i = 0; i < waypoints.length - 1; i++) {
      const from = waypoints[i];
      const to = waypoints[i + 1];

      const segmentDistance = ETA.calculateDistance(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude
      );

      const segmentETA = ETA.calculateETA(segmentDistance, averageSpeed);

      routeSegments.push({
        from: from.name || `Point ${i + 1}`,
        to: to.name || `Point ${i + 2}`,
        distance: {
          meters: Math.round(segmentDistance),
          kilometers: Math.round(segmentDistance / 1000 * 100) / 100
        },
        eta: {
          minutes: Math.round(segmentETA.minutes),
          formatted: segmentETA.formatted
        }
      });

      totalDistance += segmentDistance;
    }

    const totalETA = ETA.calculateETA(totalDistance, averageSpeed);

    res.json({
      success: true,
      data: {
        route: {
          totalDistance: {
            meters: Math.round(totalDistance),
            kilometers: Math.round(totalDistance / 1000 * 100) / 100
          },
          totalETA: {
            minutes: Math.round(totalETA.minutes),
            formatted: totalETA.formatted
          },
          segments: routeSegments
        },
        averageSpeed: parseFloat(averageSpeed)
      }
    });

  } catch (error) {
    console.error('Route ETA calculation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to calculate route ETA'
    });
  }
});

// @route   GET /api/eta/live/:driverId
// @desc    Get live ETA for driver to destination
// @access  Private
router.get('/live/:driverId', async (req, res) => {
  try {
    const { driverId } = req.params;
    const { toLatitude, toLongitude, averageSpeed = 40 } = req.query;

    if (!toLatitude || !toLongitude) {
      return res.status(400).json({
        success: false,
        message: 'Destination coordinates are required'
      });
    }

    // Get driver's current location
    const LocationTracking = require('../models/LocationTracking');
    const currentLocation = await LocationTracking.getDriverLiveLocation(driverId);

    if (!currentLocation) {
      return res.status(404).json({
        success: false,
        message: 'Driver location not found'
      });
    }

    // Calculate ETA from current location
    const distance = ETA.calculateDistance(
      currentLocation.latitude,
      currentLocation.longitude,
      parseFloat(toLatitude),
      parseFloat(toLongitude)
    );

    const eta = ETA.calculateETA(distance, parseFloat(averageSpeed));

    res.json({
      success: true,
      data: {
        driverId,
        currentLocation: {
          latitude: currentLocation.latitude,
          longitude: currentLocation.longitude,
          lastUpdate: currentLocation.lastUpdate
        },
        destination: {
          latitude: parseFloat(toLatitude),
          longitude: parseFloat(toLongitude)
        },
        distance: {
          meters: Math.round(distance),
          kilometers: Math.round(distance / 1000 * 100) / 100
        },
        eta: {
          minutes: Math.round(eta.minutes),
          seconds: Math.round(eta.seconds),
          formatted: eta.formatted
        },
        averageSpeed: parseFloat(averageSpeed)
      }
    });

  } catch (error) {
    console.error('Live ETA calculation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to calculate live ETA'
    });
  }
});

module.exports = router;
