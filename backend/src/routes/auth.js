const express = require('express');
const router = express.Router();
const Driver = require('../models/Driver');
const Assignment = require('../models/Assignment');
const DriverAssignment = require('../models/DriverAssignment');
const Bus = require('../models/Bus');
const { auth } = require('../config/firebase');

// @route   POST /api/auth/login
// @desc    Login with contact number and password
// @access  Public
router.post('/login', async (req, res) => {
  try {
    const { contactNumber, password } = req.body;

    if (!contactNumber || !password) {
      return res.status(400).json({
        success: false,
        message: 'Contact number and password are required'
      });
    }

    console.log(`🔐 Login attempt for contact number: ${contactNumber}`);

    // Authenticate driver
    const driver = await Driver.authenticate(contactNumber, password);
    
    if (!driver) {
      return res.status(401).json({
        success: false,
        message: 'Invalid contact number or password'
      });
    }

    console.log(`✅ Login successful for driver: ${driver.name}`);

    // Check for active assignment
    const assignment = await Assignment.findActiveByDriverId(driver.driverId);
    let assignedBus = null;
    
    if (assignment) {
      try {
        assignedBus = await assignment.getBusDetails();
        console.log(`✅ Found assigned bus: ${assignedBus?.busNumber || 'Unknown'}`);
      } catch (error) {
        console.error('Error fetching assigned bus details:', error);
      }
    } else {
      console.log(`❌ No active assignment found for driver: ${driver.driverId}`);
    }

    // Return driver data without password
    const driverData = driver.toJSON();
    delete driverData.password;

    res.json({
      success: true,
      message: 'Login successful',
      driver: driverData,
      assignment: assignment ? assignment.toJSON() : null,
      assignedBus: assignedBus ? assignedBus.toJSON() : null
    });

  } catch (error) {
    console.error('Error during login:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during login'
    });
  }
});

// @route   POST /api/auth/get-email-by-phone
// @desc    Get email by phone number for login (legacy)
// @access  Public
router.post('/get-email-by-phone', async (req, res) => {
  try {
    const { contactNumber } = req.body;

    if (!contactNumber) {
      return res.status(400).json({
        success: false,
        message: 'Contact number is required'
      });
    }

    // Find driver by contact number
    const driver = await Driver.findByContactNumber(contactNumber);
    
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'No account found with this contact number'
      });
    }

    // Clean contact number for email generation
    const cleanPhone = contactNumber.replace(/\D/g, '');
    const normalizedPhone = cleanPhone.length > 10 ? 
      cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;

    // Generate the same email pattern that was used during registration
    const generatedEmail = `driver_${normalizedPhone}@busdriver.app`;

    res.json({
      success: true,
      email: generatedEmail,
      message: 'Account found for contact number'
    });

  } catch (error) {
    console.error('Error getting email by contact number:', error);
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