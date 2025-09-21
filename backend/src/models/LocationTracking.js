const { db, rtdb } = require('../config/firebase');
const { v4: uuidv4 } = require('uuid');

class LocationTracking {
  constructor(data) {
    this.id = data.id || uuidv4();
    this.driverId = data.driverId;
    this.busNumber = data.busNumber;
    this.assignmentId = data.assignmentId; // New field for assignment ID
    
    // Location data
    this.latitude = data.latitude;
    this.longitude = data.longitude;
    this.accuracy = data.accuracy || 0;
    this.speed = data.speed || 0; // km/h
    this.timestamp = data.timestamp || new Date();
    
    this.createdAt = data.createdAt || new Date();
  }

  // Save location update
  async save() {
    try {
      const locationData = this.toJSON();
      
      // Check if document already exists for this driver
      const existingQuery = await db.collection('locationTracking')
        .where('driverId', '==', this.driverId)
        .where('busNumber', '==', this.busNumber)
        .limit(1)
        .get();
      
      if (!existingQuery.empty) {
        // Update existing document
        const docRef = existingQuery.docs[0].ref;
        await docRef.update({
          latitude: this.latitude,
          longitude: this.longitude,
          accuracy: this.accuracy,
          speed: this.speed,
          timestamp: this.timestamp,
          assignmentId: this.assignmentId, // Add assignment ID to updates
          lastUpdate: new Date()
        });
        console.log(`📍 Location updated (existing doc) for driver ${this.driverId} at ${this.latitude}, ${this.longitude}`);
      } else {
        // Create new document only if none exists
        await db.collection('locationTracking').add(locationData);
        console.log(`📍 New location document created for driver ${this.driverId} at ${this.latitude}, ${this.longitude}`);
      }
      
      // Update real-time location in RTDB
      await rtdb.ref(`liveLocations/${this.driverId}`).set({
        driverId: this.driverId,
        busNumber: this.busNumber,
        latitude: this.latitude,
        longitude: this.longitude,
        accuracy: this.accuracy,
        speed: this.speed,
        timestamp: this.timestamp.toISOString(),
        lastUpdate: new Date().toISOString()
      });
      
      return this;
    } catch (error) {
      console.error('Error saving location tracking:', error);
      throw error;
    }
  }

  // Get location history for driver
  static async getLocationHistory(driverId, limit = 50) {
    try {
      const snapshot = await db.collection('locationTracking')
        .where('driverId', '==', driverId)
        .orderBy('timestamp', 'desc')
        .limit(limit)
        .get();
      
      return snapshot.docs.map(doc => 
        new LocationTracking({ id: doc.id, ...doc.data() })
      );
    } catch (error) {
      console.error('Error getting location history:', error);
      throw error;
    }
  }

  // Get current live location for driver
  static async getDriverLiveLocation(driverId) {
    try {
      const snapshot = await rtdb.ref(`liveLocations/${driverId}`).once('value');
      return snapshot.val();
    } catch (error) {
      console.error('Error getting driver live location:', error);
      throw error;
    }
  }

  // Convert to JSON
  toJSON() {
    return {
      driverId: this.driverId,
      busNumber: this.busNumber,
      assignmentId: this.assignmentId, // Include assignment ID in JSON
      latitude: this.latitude,
      longitude: this.longitude,
      accuracy: this.accuracy,
      speed: this.speed,
      timestamp: this.timestamp,
      createdAt: this.createdAt,
      lastUpdate: new Date()
    };
  }
}

module.exports = LocationTracking;