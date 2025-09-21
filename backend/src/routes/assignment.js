const express = require('express');
const router = express.Router();
const Assignment = require('../models/Assignment');
const DriverAssignment = require('../models/DriverAssignment');
const Driver = require('../models/Driver');
const Bus = require('../models/Bus');

// @route   GET /api/assignment/driver/:driverId
// @desc    Get active assignment for a driver
// @access  Public (should be protected in production)
router.get('/driver/:driverId', async (req, res) => {
  try {
    const { driverId } = req.params;

    console.log(`🔍 Fetching assignment for driver: ${driverId}`);

    const assignment = await Assignment.findActiveByDriverId(driverId);
    
    if (!assignment) {
      return res.status(404).json({
        success: false,
        message: 'No active assignment found for driver'
      });
    }

    // Get bus details
    const bus = await assignment.getBusDetails();

    res.json({
      success: true,
      assignment: assignment.toJSON(),
      assignedBus: bus ? bus.toJSON() : null
    });

  } catch (error) {
    console.error('Error fetching driver assignment:', error);
    res.status(500).json({
      success: false,
      message: 'Server error fetching assignment'
    });
  }
});

// @route   GET /api/assignment/bus/:busId
// @desc    Get assignments for a specific bus
// @access  Public (should be protected in production)
router.get('/bus/:busId', async (req, res) => {
  try {
    const { busId } = req.params;

    console.log(`🔍 Fetching assignments for bus: ${busId}`);

    const assignments = await DriverAssignment.findByBusId(busId);
    
    // Get driver details for each assignment
    const assignmentsWithDrivers = await Promise.all(
      assignments.map(async (assignment) => {
        try {
          const driver = await assignment.getDriverDetails();
          return {
            ...assignment.toJSON(),
            driver: driver ? driver.toJSON() : null
          };
        } catch (error) {
          console.error('Error fetching driver details:', error);
          return assignment.toJSON();
        }
      })
    );

    res.json({
      success: true,
      assignments: assignmentsWithDrivers
    });

  } catch (error) {
    console.error('Error fetching bus assignments:', error);
    res.status(500).json({
      success: false,
      message: 'Server error fetching assignments'
    });
  }
});

// @route   POST /api/assignment/create
// @desc    Create a new driver assignment
// @access  Public (should be protected in production)
router.post('/create', async (req, res) => {
  try {
    const { driverId, busId, routeId, startTime } = req.body;

    if (!driverId || !busId) {
      return res.status(400).json({
        success: false,
        message: 'Driver ID and Bus ID are required'
      });
    }

    // Check if driver exists
    const driver = await Driver.findById(driverId);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    // Check if bus exists
    const bus = await Bus.findById(busId);
    if (!bus) {
      return res.status(404).json({
        success: false,
        message: 'Bus not found'
      });
    }

    // Check if driver already has an active assignment
    const existingAssignment = await Assignment.findActiveByDriverId(driverId);
    if (existingAssignment) {
      return res.status(400).json({
        success: false,
        message: 'Driver already has an active assignment'
      });
    }

    // Create new assignment
    const assignment = new DriverAssignment({
      driverId,
      busId,
      routeId,
      startTime
    });

    await assignment.save();

    console.log(`✅ Assignment created: Driver ${driverId} -> Bus ${busId}`);

    res.status(201).json({
      success: true,
      message: 'Assignment created successfully',
      assignment: assignment.toJSON()
    });

  } catch (error) {
    console.error('Error creating assignment:', error);
    res.status(500).json({
      success: false,
      message: 'Server error creating assignment'
    });
  }
});

// @route   PUT /api/assignment/:assignmentId/status
// @desc    Update assignment status
// @access  Public (should be protected in production)
router.put('/:assignmentId/status', async (req, res) => {
  try {
    const { assignmentId } = req.params;
    const { status } = req.body;

    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'Status is required'
      });
    }

    const assignment = await DriverAssignment.findById(assignmentId);
    if (!assignment) {
      return res.status(404).json({
        success: false,
        message: 'Assignment not found'
      });
    }

    await assignment.updateStatus(status);

    res.json({
      success: true,
      message: 'Assignment status updated successfully',
      assignment: assignment.toJSON()
    });

  } catch (error) {
    console.error('Error updating assignment status:', error);
    res.status(500).json({
      success: false,
      message: 'Server error updating assignment status'
    });
  }
});

// @route   GET /api/assignment/active
// @desc    Get all active assignments
// @access  Public (should be protected in production)
router.get('/active', async (req, res) => {
  try {
    console.log(`🔍 Fetching all active assignments`);

    const assignments = await DriverAssignment.getActiveAssignments();
    
    // Get driver and bus details for each assignment
    const detailedAssignments = await Promise.all(
      assignments.map(async (assignment) => {
        try {
          const [driver, bus] = await Promise.all([
            assignment.getDriverDetails(),
            assignment.getBusDetails()
          ]);
          
          return {
            ...assignment.toJSON(),
            driver: driver ? driver.toJSON() : null,
            bus: bus ? bus.toJSON() : null
          };
        } catch (error) {
          console.error('Error fetching assignment details:', error);
          return assignment.toJSON();
        }
      })
    );

    res.json({
      success: true,
      assignments: detailedAssignments
    });

  } catch (error) {
    console.error('Error fetching active assignments:', error);
    res.status(500).json({
      success: false,
      message: 'Server error fetching assignments'
    });
  }
});

module.exports = router;