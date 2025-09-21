const { db, rtdb } = require('../config/firebase');
const { v4: uuidv4 } = require('uuid');

// Indian Vehicle Number Formats by State
const VEHICLE_NUMBER_PATTERNS = {
  'Punjab': /^PB\d{2}[A-Z]{1,2}\d{4}$/,
  'Delhi': /^DL\d{2}[A-Z]{1,2}\d{4}$/,
  'Maharashtra': /^MH\d{2}[A-Z]{1,2}\d{4}$/,
  'Karnataka': /^KA\d{2}[A-Z]{1,2}\d{4}$/,
  'Tamil Nadu': /^TN\d{2}[A-Z]{1,2}\d{4}$/,
  'Gujarat': /^GJ\d{2}[A-Z]{1,2}\d{4}$/,
  'Rajasthan': /^RJ\d{2}[A-Z]{1,2}\d{4}$/,
  'Uttar Pradesh': /^UP\d{2}[A-Z]{1,2}\d{4}$/,
  'West Bengal': /^WB\d{2}[A-Z]{1,2}\d{4}$/,
  'Haryana': /^HR\d{2}[A-Z]{1,2}\d{4}$/
};

class Bus {
  constructor(data) {
    this.id = data.id || uuidv4();
    
    // Match exact database structure from screenshots
    this.busId = data.busId; // "BUS001", "BUS002" etc
    this.busName = data.busName; // "City bus", "City Express" etc
    this.licensePlate = data.licensePlate; // "CG04HC1212", "CG-12-AB-3456" etc
    this.rcNumber = data.rcNumber; // "1212121212", "RC123456" etc
    this.capacity = data.capacity; // 45
    this.busType = data.busType; // "ac", "City Bus" etc
    this.busModel = data.busModel; // "TATA ULTRA M5", "Tata Starbus" etc
    this.routeId = data.routeId;
    this.driverId = data.driverId || []; // Array of driver IDs
    this.status = data.status || 'inactive'; // "active", "inactive"
    
    // For backward compatibility with other structures
    this.busNumber = data.busNumber || data.busId || data.vehicleNumber || null;
    this.operatorId = data.operatorId;
    this.amenities = data.amenities || [];
    this.registrationNumber = data.registrationNumber || data.licensePlate;
    this.model = data.model || data.busModel || null;
    this.year = data.year || data.manufacturingYear || null;
    this.isActive = data.isActive !== undefined ? data.isActive : (data.status === 'active');
    this.isOnline = data.isOnline !== undefined ? data.isOnline : false;
    this.currentStatus = data.currentStatus || data.status || 'parked';
    
    this.createdAt = data.createdAt || new Date().toISOString();
    this.updatedAt = data.updatedAt || new Date().toISOString();
    this.updatedAt = new Date().toISOString();
  }

  // Validate Indian vehicle number format
  static validateVehicleNumber(busNumber, state) {
    const pattern = VEHICLE_NUMBER_PATTERNS[state];
    return pattern ? pattern.test(busNumber.replace(/[-\s]/g, '')) : true;
  }

  // Format vehicle number for display (PB-03-BC-1234)
  static formatVehicleNumber(busNumber) {
    const cleaned = busNumber.replace(/[-\s]/g, '');
    if (cleaned.length === 10) {
      return `${cleaned.substring(0, 2)}-${cleaned.substring(2, 4)}-${cleaned.substring(4, 6)}-${cleaned.substring(6, 10)}`;
    }
    return busNumber;
  }

  // Save bus to Firestore
  async save() {
    try {
      await db.collection('buses').doc(this.id).set(this.toJSON());
      console.log(`✅ Bus created: ${this.busNumber}`);
      return this;
    } catch (error) {
      throw new Error(`Error saving bus: ${error.message}`);
    }
  }

  // Find bus by ID
  static async findById(id) {
    try {
      const doc = await db.collection('buses').doc(id).get();
      return doc.exists ? new Bus({ id: doc.id, ...doc.data() }) : null;
    } catch (error) {
      throw new Error(`Error finding bus: ${error.message}`);
    }
  }

  // Find bus by number (search both busNumber and busId fields)
  static async findByNumber(busNumber) {
    try {
      // First try to find by busNumber field
      let snapshot = await db.collection('buses')
        .where('busNumber', '==', busNumber)
        .limit(1)
        .get();
      
      // If not found, try to find by busId field
      if (snapshot.empty) {
        snapshot = await db.collection('buses')
          .where('busId', '==', busNumber)
          .limit(1)
          .get();
      }
      
      if (snapshot.empty) return null;
      
      const doc = snapshot.docs[0];
      return new Bus({ id: doc.id, ...doc.data() });
    } catch (error) {
      throw new Error(`Error finding bus by number: ${error.message}`);
    }
  }

  // Get buses by operator
  static async getByOperator(operatorId) {
    try {
      const snapshot = await db.collection('buses')
        .where('operatorId', '==', operatorId)
        .where('isActive', '==', true)
        .orderBy('busNumber')
        .get();
      
      return snapshot.docs.map(doc => new Bus({ id: doc.id, ...doc.data() }));
    } catch (error) {
      throw new Error(`Error getting buses by operator: ${error.message}`);
    }
  }

  // Get buses by route
  static async getByRoute(routeId) {
    try {
      const snapshot = await db.collection('buses')
        .where('routeId', '==', routeId)
        .where('isActive', '==', true)
        .orderBy('busNumber')
        .get();
      
      return snapshot.docs.map(doc => new Bus({ id: doc.id, ...doc.data() }));
    } catch (error) {
      throw new Error(`Error getting buses by route: ${error.message}`);
    }
  }

  // Get online buses (for tracking)
  static async getOnlineBuses() {
    try {
      const snapshot = await db.collection('buses')
        .where('isOnline', '==', true)
        .where('isActive', '==', true)
        .get();
      
      return snapshot.docs.map(doc => new Bus({ id: doc.id, ...doc.data() }));
    } catch (error) {
      throw new Error(`Error getting online buses: ${error.message}`);
    }
  }

  // Get all buses (for bus selection)
  static async getAllBuses() {
    try {
      console.log('Fetching all buses from Firestore...');
      const snapshot = await db.collection('buses').get();
      
      console.log(`Found ${snapshot.docs.length} bus documents`);
      
      const buses = snapshot.docs.map(doc => {
        const data = doc.data();
        console.log(`Bus ${doc.id}:`, data);
        return new Bus({ id: doc.id, ...data });
      });
      
      return buses;
    } catch (error) {
      console.error('Error getting all buses:', error);
      throw new Error(`Error getting all buses: ${error.message}`);
    }
  }

  // Assign route to bus
  async assignRoute(routeId) {
    try {
      this.routeId = routeId;
      this.updatedAt = new Date().toISOString();
      await this.save();
    } catch (error) {
      throw new Error(`Error assigning route: ${error.message}`);
    }
  }

  // Driver selects this bus from driver app
  async assignDriver(driverId) {
    try {
      this.driverId = driverId;
      this.isOnline = true;
      this.currentStatus = 'running';
      this.updatedAt = new Date().toISOString();
      await this.save();
      
      // Update real-time status
      await this.updateRealtimeStatus();
    } catch (error) {
      throw new Error(`Error assigning driver: ${error.message}`);
    }
  }

  // Update bus status
  async updateStatus(status) {
    try {
      const validStatuses = ['running', 'parked', 'maintenance', 'breakdown'];
      if (!validStatuses.includes(status)) {
        throw new Error('Invalid status');
      }

      this.currentStatus = status;
      this.isOnline = status === 'running';
      this.lastUpdated = new Date().toISOString();
      this.updatedAt = new Date().toISOString();
      
      await this.save();
      await this.updateRealtimeStatus();
    } catch (error) {
      throw new Error(`Error updating status: ${error.message}`);
    }
  }

  // Update real-time location from driver app
  async updateRealtimeLocation(locationData) {
    try {
      const { latitude, longitude, accuracy, timestamp } = locationData;
      
      // Get previous location for speed/heading calculation
      const prevLocation = await this.getCurrentLocation();
      
      let speed = 0;
      let heading = 0;
      
      if (prevLocation && prevLocation.latitude && prevLocation.longitude) {
        // Calculate speed (km/h)
        const distance = this.calculateDistance(
          prevLocation.latitude, prevLocation.longitude,
          latitude, longitude
        );
        const timeDiff = (timestamp - prevLocation.timestamp) / 1000; // seconds
        speed = timeDiff > 0 ? (distance / timeDiff) * 3.6 : 0; // km/h
        
        // Calculate heading (bearing)
        heading = this.calculateBearing(
          prevLocation.latitude, prevLocation.longitude,
          latitude, longitude
        );
      }

      const locationUpdateData = {
        busId: this.id,
        busNumber: this.busNumber,
        operatorId: this.operatorId,
        routeId: this.routeId,
        driverId: this.driverId,
        latitude,
        longitude,
        accuracy,
        speed: Math.round(speed * 100) / 100, // Round to 2 decimal places
        heading: Math.round(heading),
        status: this.currentStatus,
        isOnline: this.isOnline,
        timestamp,
        lastUpdate: new Date().toISOString()
      };

      // Save to Realtime Database for live tracking
      await rtdb.ref(`busLocations/${this.id}`).set(locationUpdateData);
      
      this.lastUpdated = new Date().toISOString();
      await this.save();
    } catch (error) {
      throw new Error(`Error updating realtime location: ${error.message}`);
    }
  }

  // Calculate distance between two coordinates (Haversine formula)
  calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371000; // Earth's radius in meters
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
              Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
              Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c; // Distance in meters
  }

  // Calculate bearing (heading) between two coordinates
  calculateBearing(lat1, lon1, lat2, lon2) {
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const lat1Rad = lat1 * Math.PI / 180;
    const lat2Rad = lat2 * Math.PI / 180;
    
    const y = Math.sin(dLon) * Math.cos(lat2Rad);
    const x = Math.cos(lat1Rad) * Math.sin(lat2Rad) - 
              Math.sin(lat1Rad) * Math.cos(lat2Rad) * Math.cos(dLon);
    
    let bearing = Math.atan2(y, x) * 180 / Math.PI;
    return (bearing + 360) % 360; // Normalize to 0-360
  }

  // Update real-time status only
  async updateRealtimeStatus() {
    try {
      const statusData = {
        status: this.currentStatus,
        isOnline: this.isOnline,
        timestamp: Date.now(),
        lastUpdate: new Date().toISOString()
      };

      await rtdb.ref(`busLocations/${this.id}`).update(statusData);
    } catch (error) {
      throw new Error(`Error updating realtime status: ${error.message}`);
    }
  }

  // Get current location from realtime database
  async getCurrentLocation() {
    try {
      const snapshot = await rtdb.ref(`busLocations/${this.id}`).once('value');
      return snapshot.val();
    } catch (error) {
      throw new Error(`Error getting current location: ${error.message}`);
    }
  }

  // Convert to JSON - match database structure
  toJSON() {
    return {
      id: this.id,
      busId: this.busId,
      busName: this.busName,
      licensePlate: this.licensePlate,
      rcNumber: this.rcNumber,
      capacity: this.capacity,
      busType: this.busType,
      busModel: this.busModel,
      routeId: this.routeId,
      driverId: this.driverId,
      status: this.status,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      
      // Additional fields for compatibility
      busNumber: this.busNumber,
      operatorId: this.operatorId,
      amenities: this.amenities,
      registrationNumber: this.registrationNumber,
      model: this.model,
      year: this.year,
      isActive: this.isActive,
      isOnline: this.isOnline,
      currentStatus: this.currentStatus
    };
  }
}

module.exports = Bus;