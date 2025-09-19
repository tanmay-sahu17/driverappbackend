const express = require('express');
const router = express.Router();
const Bus = require('../models/Bus');
const Driver = require('../models/Driver');

// @route   GET /api/bus/list
// @desc    Get list of available buses
// @access  Private
router.get('/list', async (req, res) => {
  try {
    const { operatorId, status = 'all' } = req.query;

    console.log('Bus list request with params:', { operatorId, status });

    let buses;
    
    if (operatorId) {
      buses = await Bus.getByOperator(operatorId);
    } else {
      // Get all buses (not just online ones)
      buses = await Bus.getAllBuses();
    }

    console.log(`Found ${buses.length} buses in database`);

    // Filter by status if specified
    const filteredBuses = buses.filter(bus => {
      if (status === 'all') return true;
      if (status === 'active') return bus.isActive !== false; // Default to true if not specified
      if (status === 'online') return bus.isOnline === true;
      return true;
    });

    console.log(`After filtering: ${filteredBuses.length} buses`);

    res.json({
      success: true,
      data: filteredBuses.map(bus => ({
        id: bus.id,
        busNumber: bus.busNumber,
        busType: bus.busType,
        capacity: bus.capacity,
        isOnline: bus.isOnline,
        currentStatus: bus.currentStatus,
        driverId: bus.driverId,
        routeId: bus.routeId,
        model: bus.model,
        amenities: bus.amenities
      })),
      count: filteredBuses.length
    });

  } catch (error) {
    console.error('Bus list error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch bus list',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// @route   GET /api/bus/:busNumber
// @desc    Get bus details by number
// @access  Private
router.get('/:busNumber', async (req, res) => {
  try {
    const { busNumber } = req.params;

    const bus = await Bus.findByNumber(busNumber);

    if (!bus) {
      return res.status(404).json({
        success: false,
        message: 'Bus not found'
      });
    }

    res.json({
      success: true,
      data: bus.toJSON()
    });

  } catch (error) {
    console.error('Bus details error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch bus details'
    });
  }
});

// @route   POST /api/bus/assign
// @desc    Assign driver to bus
// @access  Private
router.post('/assign', async (req, res) => {
  try {
    const { busNumber, driverId } = req.body;

    if (!busNumber || !driverId) {
      return res.status(400).json({
        success: false,
        message: 'Bus number and driver ID are required'
      });
    }

    // Find bus and driver
    const bus = await Bus.findByNumber(busNumber);
    const driver = await Driver.findById(driverId);

    if (!bus) {
      return res.status(404).json({
        success: false,
        message: 'Bus not found'
      });
    }

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    // Check if bus is already assigned
    if (bus.driverId && bus.driverId !== driverId) {
      return res.status(400).json({
        success: false,
        message: 'Bus is already assigned to another driver'
      });
    }

    // Assign driver to bus
    await bus.assignDriver(driverId);
    await driver.assignToBus(bus.id);

    res.json({
      success: true,
      message: 'Driver assigned to bus successfully',
      data: {
        busNumber: bus.busNumber,
        driverId: driver.id,
        driverName: driver.driverName,
        assignedAt: new Date()
      }
    });

  } catch (error) {
    console.error('Bus assignment error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to assign driver to bus'
    });
  }
});

// @route   POST /api/bus/unassign
// @desc    Unassign driver from bus
// @access  Private
router.post('/unassign', async (req, res) => {
  try {
    const { busNumber, driverId } = req.body;

    if (!busNumber || !driverId) {
      return res.status(400).json({
        success: false,
        message: 'Bus number and driver ID are required'
      });
    }

    const bus = await Bus.findByNumber(busNumber);
    const driver = await Driver.findById(driverId);

    if (!bus || !driver) {
      return res.status(404).json({
        success: false,
        message: 'Bus or driver not found'
      });
    }

    // Unassign driver from bus
    await bus.unassignDriver();
    await driver.unassignFromBus();

    res.json({
      success: true,
      message: 'Driver unassigned from bus successfully',
      data: {
        busNumber: bus.busNumber,
        driverId: driver.id,
        unassignedAt: new Date()
      }
    });

  } catch (error) {
    console.error('Bus unassignment error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to unassign driver from bus'
    });
  }
});

// @route   GET /api/bus/available
// @desc    Get available buses (not assigned to any driver)
// @access  Private
router.get('/available', async (req, res) => {
  try {
    const availableBuses = await Bus.getAvailableBuses();

    res.json({
      success: true,
      data: availableBuses.map(bus => ({
        id: bus.id,
        busNumber: bus.busNumber,
        busType: bus.busType,
        capacity: bus.capacity,
        currentStatus: bus.currentStatus
      })),
      count: availableBuses.length
    });

  } catch (error) {
    console.error('Available buses error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch available buses'
    });
  }
});

module.exports = router;