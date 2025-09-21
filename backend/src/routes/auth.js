const express = require('express');
const router = express.Router();
const Driver = require('../models/Driver');
const { auth } = require('../config/firebase');

// @route   POST /api/auth/get-email-by-phone
// @desc    Get email by phone number for login
// @access  Public
router.post('/get-email-by-phone', async (req, res) => {
  try {
    const { phoneNumber } = req.body;

    if (!phoneNumber) {
      return res.status(400).json({
        success: false,
        message: 'Phone number is required'
      });
    }

    // Clean phone number (remove spaces, dashes, etc.)
    const cleanPhone = phoneNumber.replace(/\D/g, '');
    
    // Find driver by phone number
    const driver = await Driver.findByPhone(cleanPhone);
    
    if (!driver || !driver.email) {
      return res.status(404).json({
        success: false,
        message: 'No account found with this phone number'
      });
    }

    res.json({
      success: true,
      email: driver.email,
      message: 'Email found for phone number'
    });

  } catch (error) {
    console.error('Error getting email by phone:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   POST /api/auth/register
// @desc    Register new driver
// @access  Public
router.post('/register', async (req, res) => {
  try {
    const { email, password, driverName, phoneNumber, licenseNumber, operatorId } = req.body;

    // Validate required fields
    if (!email || !password || !driverName || !phoneNumber || !licenseNumber) {
      return res.status(400).json({
        success: false,
        message: 'All fields are required'
      });
    }

    // Create Firebase user
    const userRecord = await auth.createUser({
      email,
      password,
      displayName: driverName,
      phoneNumber: phoneNumber.startsWith('+') ? phoneNumber : `+91${phoneNumber}`
    });

    // Create driver profile
    const driver = new Driver({
      id: userRecord.uid,
      driverName,
      email,
      phoneNumber,
      licenseNumber,
      licenseType: 'commercial',
      operatorId: operatorId || null,
      status: 'active'
    });

    await driver.save();

    res.status(201).json({
      success: true,
      message: 'Driver registered successfully',
      data: {
        uid: userRecord.uid,
        email: userRecord.email,
        displayName: userRecord.displayName,
        phoneNumber: userRecord.phoneNumber
      }
    });

  } catch (error) {
    console.error('Registration error:', error);
    
    // Handle Firebase Auth errors
    if (error.code) {
      switch (error.code) {
        case 'auth/email-already-exists':
          return res.status(400).json({
            success: false,
            message: 'Email already registered'
          });
        case 'auth/invalid-email':
          return res.status(400).json({
            success: false,
            message: 'Invalid email format'
          });
        case 'auth/weak-password':
          return res.status(400).json({
            success: false,
            message: 'Password should be at least 6 characters'
          });
        default:
          return res.status(500).json({
            success: false,
            message: 'Registration failed'
          });
      }
    }

    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// @route   POST /api/auth/verify
// @desc    Verify Firebase token
// @access  Public
router.post('/verify', async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({
        success: false,
        message: 'ID token is required'
      });
    }

    // Verify Firebase token
    const decodedToken = await auth.verifyIdToken(idToken);
    
    // Get driver profile
    const driver = await Driver.findById(decodedToken.uid);

    res.json({
      success: true,
      data: {
        uid: decodedToken.uid,
        email: decodedToken.email,
        displayName: decodedToken.name,
        phoneNumber: decodedToken.phone_number,
        driver: driver ? driver.toJSON() : null
      }
    });

  } catch (error) {
    console.error('Token verification error:', error);
    
    if (error.code === 'auth/id-token-expired') {
      return res.status(401).json({
        success: false,
        message: 'Token expired'
      });
    }

    res.status(401).json({
      success: false,
      message: 'Invalid token'
    });
  }
});

// @route   GET /api/auth/profile/:uid
// @desc    Get driver profile
// @access  Private
router.get('/profile/:uid', async (req, res) => {
  try {
    const { uid } = req.params;
    
    const driver = await Driver.findById(uid);
    
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver profile not found'
      });
    }

    res.json({
      success: true,
      data: driver.toJSON()
    });

  } catch (error) {
    console.error('Profile fetch error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch profile'
    });
  }
});

// @route   PUT /api/auth/profile/:uid
// @desc    Update driver profile
// @access  Private
router.put('/profile/:uid', async (req, res) => {
  try {
    const { uid } = req.params;
    const updates = req.body;
    
    const driver = await Driver.findById(uid);
    
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found'
      });
    }

    await driver.updateDetails(updates);

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: driver.toJSON()
    });

  } catch (error) {
    console.error('Profile update error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update profile'
    });
  }
});

module.exports = router;