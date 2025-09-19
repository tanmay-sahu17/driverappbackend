const { db, rtdb } = require('../config/firebase');
const { v4: uuidv4 } = require('uuid');
const admin = require('firebase-admin');

class SosAlert {
  constructor(data) {
    this.id = data.id || uuidv4();
    this.driverId = data.driverId;
    this.busNumber = data.busNumber;
    this.latitude = data.latitude;
    this.longitude = data.longitude;
    this.emergencyMessage = data.emergencyMessage || '';
    this.timestamp = data.timestamp || new Date();
    this.status = data.status || 'active'; // 'active', 'resolved'
    
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  // Create and send SOS alert
  async createAlert() {
    try {
      this.status = 'active';
      this.timestamp = new Date();
      this.createdAt = new Date();
      this.updatedAt = new Date();
      
      // Prepare data for Firestore (use server timestamps for better consistency)
      const alertData = {
        driverId: this.driverId,
        busNumber: this.busNumber,
        latitude: this.latitude,
        longitude: this.longitude,
        emergencyMessage: this.emergencyMessage,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        status: this.status,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };
      
      // Save to Firestore first
      console.log(`Creating SOS Alert: ${this.id} for driver ${this.driverId}`);
      await db.collection('sosAlerts').doc(this.id).set(alertData);
      
      // Send to real-time database for immediate notifications
      await rtdb.ref(`activeSosAlerts/${this.id}`).set({
        id: this.id,
        driverId: this.driverId,
        busNumber: this.busNumber,
        latitude: this.latitude,
        longitude: this.longitude,
        emergencyMessage: this.emergencyMessage,
        timestamp: admin.database.ServerValue.TIMESTAMP,
        status: this.status
      });
      
      console.log(`🚨 SOS Alert created successfully: ${this.id} for driver ${this.driverId}`);
      return this;
    } catch (error) {
      console.error('Error creating SOS alert:', error.message);
      console.error('Full error:', error);
      throw error;
    }
  }

  // Resolve alert
  async resolve() {
    try {
      this.status = 'resolved';
      this.updatedAt = new Date();
      
      await db.collection('sosAlerts').doc(this.id).update({
        status: this.status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // Remove from active alerts
      await rtdb.ref(`activeSosAlerts/${this.id}`).remove();
      
      console.log(`✅ SOS Alert ${this.id} resolved`);
      return this;
    } catch (error) {
      console.error('Error resolving SOS alert:', error);
      throw error;
    }
  }

  // Get active alerts for driver
  static async getActiveAlerts(driverId) {
    try {
      console.log(`Getting active alerts for driver: ${driverId}`);
      
      // First try without ordering to avoid index issues
      const snapshot = await db.collection('sosAlerts')
        .where('driverId', '==', driverId)
        .where('status', '==', 'active')
        .get();
      
      console.log(`Found ${snapshot.docs.length} active alerts for driver ${driverId}`);
      
      const alerts = snapshot.docs.map(doc => {
        const data = doc.data();
        console.log(`Alert data:`, data);
        
        // Convert Firestore timestamps to Date objects
        if (data.timestamp && data.timestamp.toDate) {
          data.timestamp = data.timestamp.toDate();
        }
        if (data.createdAt && data.createdAt.toDate) {
          data.createdAt = data.createdAt.toDate();
        }
        if (data.updatedAt && data.updatedAt.toDate) {
          data.updatedAt = data.updatedAt.toDate();
        }
        return new SosAlert({ id: doc.id, ...data });
      });
      
      // Sort in memory by timestamp
      alerts.sort((a, b) => {
        const timeA = a.timestamp || a.createdAt || new Date(0);
        const timeB = b.timestamp || b.createdAt || new Date(0);
        return timeB - timeA; // Descending order (newest first)
      });
      
      return alerts;
    } catch (error) {
      console.error('Error getting active alerts:', error.message);
      console.error('Full error:', error);
      throw error;
    }
  }

  // Find alert by ID
  static async findById(alertId) {
    try {
      const doc = await db.collection('sosAlerts').doc(alertId).get();
      
      if (!doc.exists) {
        return null;
      }
      
      const data = doc.data();
      // Convert Firestore timestamps to Date objects
      if (data.timestamp && data.timestamp.toDate) {
        data.timestamp = data.timestamp.toDate();
      }
      if (data.createdAt && data.createdAt.toDate) {
        data.createdAt = data.createdAt.toDate();
      }
      if (data.updatedAt && data.updatedAt.toDate) {
        data.updatedAt = data.updatedAt.toDate();
      }
      
      return new SosAlert({ id: doc.id, ...data });
    } catch (error) {
      console.error('Error finding alert by ID:', error.message);
      console.error('Full error:', error);
      throw error;
    }
  }

  // Get all active alerts (for control room)
  static async getAllActiveAlerts() {
    try {
      console.log('Getting all active alerts');
      
      const snapshot = await db.collection('sosAlerts')
        .where('status', '==', 'active')
        .get();
      
      console.log(`Found ${snapshot.docs.length} total active alerts`);
      
      const alerts = snapshot.docs.map(doc => {
        const data = doc.data();
        // Convert Firestore timestamps to Date objects
        if (data.timestamp && data.timestamp.toDate) {
          data.timestamp = data.timestamp.toDate();
        }
        if (data.createdAt && data.createdAt.toDate) {
          data.createdAt = data.createdAt.toDate();
        }
        if (data.updatedAt && data.updatedAt.toDate) {
          data.updatedAt = data.updatedAt.toDate();
        }
        return new SosAlert({ id: doc.id, ...data });
      });
      
      // Sort in memory by timestamp
      alerts.sort((a, b) => {
        const timeA = a.timestamp || a.createdAt || new Date(0);
        const timeB = b.timestamp || b.createdAt || new Date(0);
        return timeB - timeA; // Descending order (newest first)
      });
      
      return alerts;
    } catch (error) {
      console.error('Error getting all active alerts:', error.message);
      console.error('Full error:', error);
      throw error;
    }
  }

  // Get alert history
  static async getAlertHistory(driverId = null, limit = 20) {
    try {
      let query = db.collection('sosAlerts');
      
      if (driverId) {
        query = query.where('driverId', '==', driverId);
      }
      
      query = query.orderBy('createdAt', 'desc').limit(limit);
      
      const snapshot = await query.get();
      
      return snapshot.docs.map(doc => {
        const data = doc.data();
        // Convert Firestore timestamps to Date objects
        if (data.timestamp && data.timestamp.toDate) {
          data.timestamp = data.timestamp.toDate();
        }
        if (data.createdAt && data.createdAt.toDate) {
          data.createdAt = data.createdAt.toDate();
        }
        if (data.updatedAt && data.updatedAt.toDate) {
          data.updatedAt = data.updatedAt.toDate();
        }
        return new SosAlert({ id: doc.id, ...data });
      });
    } catch (error) {
      console.error('Error getting alert history:', error.message);
      console.error('Full error:', error);
      throw error;
    }
  }

  // Convert to JSON
  toJSON() {
    return {
      driverId: this.driverId,
      busNumber: this.busNumber,
      latitude: this.latitude,
      longitude: this.longitude,
      emergencyMessage: this.emergencyMessage,
      timestamp: this.timestamp instanceof Date ? this.timestamp.toISOString() : this.timestamp,
      status: this.status,
      createdAt: this.createdAt instanceof Date ? this.createdAt.toISOString() : this.createdAt,
      updatedAt: this.updatedAt instanceof Date ? this.updatedAt.toISOString() : this.updatedAt
    };
  }
}

module.exports = SosAlert;