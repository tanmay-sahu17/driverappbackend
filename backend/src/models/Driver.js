const { db } = require('../config/firebase');
const { v4: uuidv4 } = require('uuid');

class Driver {
  constructor(data) {
    this.driverId = data.driverId || uuidv4();
    this.name = data.name;
    this.licenseNumber = data.licenseNumber;
    this.contactNumber = data.contactNumber;
    this.dob = data.dob;
    this.emergencyContactNumber = data.emergencyContactNumber;
    this.password = data.password;
    this.aadharCardNumber = data.aadharCardNumber;
    this.joiningDate = data.joiningDate || new Date();
    this.experience = data.experience;
    this.address = data.address;
    this.city = data.city;
    this.state = data.state;
    this.assignedBusId = data.assignedBusId || null;
    this.status = data.status || 'available'; // 'available', 'on-duty', 'off-duty'
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  // Save driver to database
  async save() {
    try {
      const driverData = this.toJSON();
      await db.collection('drivers').doc(this.driverId).set(driverData);
      console.log(`✅ Driver ${this.name} saved successfully`);
    } catch (error) {
      console.error('Error saving driver:', error);
      throw error;
    }
  }

  // Find driver by ID
  static async findById(driverId) {
    try {
      const doc = await db.collection('drivers').doc(driverId).get();
      if (!doc.exists) {
        return null;
      }
      return new Driver({ driverId: doc.id, ...doc.data() });
    } catch (error) {
      console.error('Error finding driver by ID:', error);
      throw error;
    }
  }

  // Find driver by contact number
  static async findByContactNumber(contactNumber) {
    try {
      // Clean contact number and try different formats
      const cleanPhone = contactNumber.replace(/\D/g, '');
      
      // For numbers longer than 10 digits, get last 10 (for +91 numbers)
      const normalizedPhone = cleanPhone.length > 10 ? 
        cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;
      
      const phoneFormats = [
        cleanPhone,           // Original clean number
        normalizedPhone,      // Last 10 digits
        `+91${normalizedPhone}`, // With +91 prefix
        `+91-${normalizedPhone}`, // With +91- prefix  
        `91${normalizedPhone}`,   // With 91 prefix
        contactNumber          // Original format
      ];

      console.log(`🔍 Searching for driver with contact number formats:`, phoneFormats);

      for (const format of phoneFormats) {
        const snapshot = await db.collection('drivers')
          .where('contactNumber', '==', format)
          .get();
        
        if (!snapshot.empty) {
          const doc = snapshot.docs[0];
          const driver = new Driver({ driverId: doc.id, ...doc.data() });
          console.log(`✅ Found driver: ${driver.name} with contact: ${format}`);
          return driver;
        }
      }
      
      console.log(`❌ No driver found with contact number: ${contactNumber}`);
      return null;
    } catch (error) {
      console.error('Error finding driver by contact number:', error);
      throw error;
    }
  }

  // Find driver by license number
  static async findByLicense(licenseNumber) {
    try {
      const snapshot = await db.collection('drivers')
        .where('licenseNumber', '==', licenseNumber)
        .get();
      
      if (snapshot.empty) {
        return null;
      }
      
      const doc = snapshot.docs[0];
      return new Driver({ driverId: doc.id, ...doc.data() });
    } catch (error) {
      console.error('Error finding driver by license:', error);
      throw error;
    }
  }

  // Find driver by aadhar card number
  static async findByAadhar(aadharCardNumber) {
    try {
      const snapshot = await db.collection('drivers')
        .where('aadharCardNumber', '==', aadharCardNumber)
        .get();
      
      if (snapshot.empty) {
        return null;
      }
      
      const doc = snapshot.docs[0];
      return new Driver({ driverId: doc.id, ...doc.data() });
    } catch (error) {
      console.error('Error finding driver by aadhar:', error);
      throw error;
    }
  }

  // Authenticate driver with contact number and password
  static async authenticate(contactNumber, password) {
    try {
      const driver = await this.findByContactNumber(contactNumber);
      
      if (!driver) {
        console.log(`❌ No driver found with contact number: ${contactNumber}`);
        return null;
      }

      // Check password (in production, use bcrypt)
      if (driver.password !== password) {
        console.log(`❌ Invalid password for driver: ${driver.name}`);
        return null;
      }

      console.log(`✅ Authentication successful for driver: ${driver.name}`);
      return driver;
    } catch (error) {
      console.error('Error authenticating driver:', error);
      throw error;
    }
  }

  // Get available drivers (not assigned to any bus)
  static async getAvailableDrivers() {
    try {
      const snapshot = await db.collection('drivers')
        .where('status', '==', 'available')
        .where('assignedBusId', '==', null)
        .orderBy('name')
        .get();
      
      return snapshot.docs.map(doc => 
        new Driver({ driverId: doc.id, ...doc.data() })
      );
    } catch (error) {
      console.error('Error getting available drivers:', error);
      throw error;
    }
  }

  // Search drivers by name
  static async searchByName(searchTerm) {
    try {
      const snapshot = await db.collection('drivers')
        .where('name', '>=', searchTerm)
        .where('name', '<=', searchTerm + '\uf8ff')
        .orderBy('name')
        .limit(20)
        .get();
      
      return snapshot.docs.map(doc => 
        new Driver({ driverId: doc.id, ...doc.data() })
      );
    } catch (error) {
      console.error('Error searching drivers:', error);
      throw error;
    }
  }

  // Update driver details
  async updateDetails(updates) {
    try {
      // Don't allow updating certain fields
      const allowedUpdates = {
        name: updates.name,
        contactNumber: updates.contactNumber,
        licenseNumber: updates.licenseNumber,
        dob: updates.dob,
        emergencyContactNumber: updates.emergencyContactNumber,
        experience: updates.experience,
        address: updates.address,
        city: updates.city,
        state: updates.state,
        updatedAt: new Date()
      };

      // Remove undefined values
      Object.keys(allowedUpdates).forEach(key => {
        if (allowedUpdates[key] === undefined) {
          delete allowedUpdates[key];
        }
      });

      // Update local instance
      Object.assign(this, allowedUpdates);

      // Update in database
      await db.collection('drivers').doc(this.driverId).update(allowedUpdates);
      console.log(`✅ Driver ${this.name} updated successfully`);
    } catch (error) {
      console.error('Error updating driver:', error);
      throw error;
    }
  }

  // Update driver status
  async updateStatus(newStatus) {
    try {
      const validStatuses = ['available', 'on-duty', 'off-duty'];
      if (!validStatuses.includes(newStatus)) {
        throw new Error(`Invalid status. Must be one of: ${validStatuses.join(', ')}`);
      }

      this.status = newStatus;
      this.updatedAt = new Date();

      await db.collection('drivers').doc(this.driverId).update({
        status: newStatus,
        updatedAt: this.updatedAt
      });

      console.log(`✅ Driver ${this.name} status updated to ${newStatus}`);
    } catch (error) {
      console.error('Error updating driver status:', error);
      throw error;
    }
  }

  // Assign driver to bus
  async assignToBus(busId) {
    try {
      this.assignedBusId = busId;
      this.status = 'on-duty';
      this.updatedAt = new Date();

      await db.collection('drivers').doc(this.driverId).update({
        assignedBusId: busId,
        status: 'on-duty',
        updatedAt: this.updatedAt
      });

      console.log(`✅ Driver ${this.name} assigned to bus ${busId}`);
    } catch (error) {
      console.error('Error assigning driver to bus:', error);
      throw error;
    }
  }

  // Remove driver from bus
  async removeFromBus() {
    try {
      this.assignedBusId = null;
      this.status = 'available';
      this.updatedAt = new Date();

      await db.collection('drivers').doc(this.driverId).update({
        assignedBusId: null,
        status: 'available',
        updatedAt: this.updatedAt
      });

      console.log(`✅ Driver ${this.name} removed from bus assignment`);
    } catch (error) {
      console.error('Error removing driver from bus:', error);
      throw error;
    }
  }

  // Check if driver is available for assignment
  isAvailable() {
    return this.status === 'available' && this.assignedBusId === null;
  }

  // Convert to JSON
  toJSON() {
    return {
      driverId: this.driverId,
      name: this.name,
      licenseNumber: this.licenseNumber,
      contactNumber: this.contactNumber,
      dob: this.dob,
      emergencyContactNumber: this.emergencyContactNumber,
      password: this.password,
      aadharCardNumber: this.aadharCardNumber,
      joiningDate: this.joiningDate,
      experience: this.experience,
      address: this.address,
      city: this.city,
      state: this.state,
      assignedBusId: this.assignedBusId,
      status: this.status,
      isAvailable: this.isAvailable(),
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    };
  }
}

module.exports = Driver;