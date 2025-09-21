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
    const normalizedPhone = cleanPhone.length > 10 ? 
      cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;
    
    // Find driver by phone number
    const driver = await Driver.findByPhone(normalizedPhone);
    
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'No account found with this phone number'
      });
    }

    // Generate the same email pattern that was used during registration
    const generatedEmail = `driver_${normalizedPhone}@busdriver.app`;

    res.json({
      success: true,
      email: generatedEmail,
      message: 'Account found for phone number'
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
    const { password, driverName, phoneNumber, licenseNumber, operatorId } = req.body;

    // Validate required fields (removed email from validation)
    if (!password || !driverName || !phoneNumber || !licenseNumber) {
      return res.status(400).json({
        success: false,
        message: 'Driver name, phone number, license number and password are required'
      });
    }

    // Clean phone number
    const cleanPhone = phoneNumber.replace(/\D/g, '');
    const normalizedPhone = cleanPhone.length > 10 ? 
      cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;

    // Check if driver already exists with this phone number
    const existingDriver = await Driver.findByPhone(normalizedPhone);
    if (existingDriver) {
      return res.status(400).json({
        success: false,
        message: 'Driver already registered with this phone number'
      });
    }

    // Generate a unique email for Firebase Auth (drivers don't need real email)
    const generatedEmail = `driver_${normalizedPhone}@busdriver.app`;

    // Create Firebase user with generated email
    const userRecord = await auth.createUser({
      email: generatedEmail,
      password,
      displayName: driverName,
      phoneNumber: phoneNumber.startsWith('+') ? phoneNumber : `+91${phoneNumber}`
    });

    // Create driver profile (store generated email internally)
    const driver = new Driver({
      id: userRecord.uid,
      driverName,
      email: generatedEmail, // Store generated email
      phoneNumber: normalizedPhone, // Store normalized phone
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
        displayName: userRecord.displayName,
        phoneNumber: normalizedPhone,
        message: 'You can now login with your phone number and password'
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