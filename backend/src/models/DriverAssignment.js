const { db } = require('../config/firebase');
const { v4: uuidv4 } = require('uuid');

class DriverAssignment {
  constructor(data) {
    this.assignmentId = data.assignmentId || uuidv4();
    this.driverId = data.driverId;
    
    // Support both busId and busNumber for different collections
    this.busId = data.busId;
    this.busNumber = data.busNumber;
    
    this.routeId = data.routeId;
    this.routeName = data.routeName;
    this.driverName = data.driverName;
    this.assignedDate = data.assignedDate || new Date();
    this.startTime = data.startTime;
    this.estimatedDuration = data.estimatedDuration;
    this.status = data.status || 'active'; // 'active', 'inactive', 'completed'
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  // Save assignment to database
  async save() {
    try {
      const assignmentData = this.toJSON();
      await db.collection('assignments').doc(this.assignmentId).set(assignmentData);
      console.log(`✅ Driver assignment ${this.assignmentId} saved successfully`);
    } catch (error) {
      console.error('Error saving driver assignment:', error);
      throw error;
    }
  }

  // Find assignment by ID
  static async findById(assignmentId) {
    try {
      const doc = await db.collection('assignments').doc(assignmentId).get();
      if (!doc.exists) {
        return null;
      }
      return new DriverAssignment({ assignmentId: doc.id, ...doc.data() });
    } catch (error) {
      console.error('Error finding assignment by ID:', error);
      throw error;
    }
  }

  // Find active assignment by driver ID
  static async findActiveByDriverId(driverId) {
    try {
      const snapshot = await db.collection('assignments')
        .where('driverId', '==', driverId)
        .where('status', '==', 'active')
        .get();
      
      if (snapshot.empty) {
        console.log(`❌ No active assignment found for driver: ${driverId}`);
        return null;
      }
      
      const doc = snapshot.docs[0];
      const assignment = new DriverAssignment({ assignmentId: doc.id, ...doc.data() });
      console.log(`✅ Found active assignment for driver ${driverId}: Bus ${assignment.busNumber || assignment.busId}`);
      return assignment;
    } catch (error) {
      console.error('Error finding active assignment by driver ID:', error);
      throw error;
    }
  }

  // Find assignments by bus ID
  static async findByBusId(busId) {
    try {
      const snapshot = await db.collection('assignments')
        .where('busId', '==', busId)
        .orderBy('assignedDate', 'desc')
        .get();
      
      return snapshot.docs.map(doc => 
        new DriverAssignment({ assignmentId: doc.id, ...doc.data() })
      );
    } catch (error) {
      console.error('Error finding assignments by bus ID:', error);
      throw error;
    }
  }

  // Get all active assignments
  static async getActiveAssignments() {
    try {
      const snapshot = await db.collection('assignments')
        .where('status', '==', 'active')
        .orderBy('assignedDate', 'desc')
        .get();
      
      return snapshot.docs.map(doc => 
        new DriverAssignment({ assignmentId: doc.id, ...doc.data() })
      );
    } catch (error) {
      console.error('Error getting active assignments:', error);
      throw error;
    }
  }

  // Update assignment status
  async updateStatus(newStatus) {
    try {
      const validStatuses = ['active', 'inactive', 'completed'];
      if (!validStatuses.includes(newStatus)) {
        throw new Error(`Invalid status. Must be one of: ${validStatuses.join(', ')}`);
      }

      this.status = newStatus;
      this.updatedAt = new Date();

      await db.collection('assignments').doc(this.assignmentId).update({
        status: newStatus,
        updatedAt: this.updatedAt
      });

      console.log(`✅ Assignment ${this.assignmentId} status updated to ${newStatus}`);
    } catch (error) {
      console.error('Error updating assignment status:', error);
      throw error;
    }
  }

  // Get assigned bus details
  async getBusDetails() {
    try {
      const Bus = require('./Bus');
      
      // Try with busId first (for driverAssigns collection)
      if (this.busId) {
        const bus = await Bus.findById(this.busId);
        if (bus) return bus;
      }
      
      // Try with busNumber (for assignments collection)
      if (this.busNumber) {
        const bus = await Bus.findByNumber(this.busNumber);
        if (bus) return bus;
      }
      
      console.log(`❌ No bus found with busId: ${this.busId} or busNumber: ${this.busNumber}`);
      return null;
    } catch (error) {
      console.error('Error getting bus details:', error);
      throw error;
    }
  }

  // Get assigned driver details
  async getDriverDetails() {
    try {
      const Driver = require('./Driver');
      return await Driver.findById(this.driverId);
    } catch (error) {
      console.error('Error getting driver details:', error);
      throw error;
    }
  }

  // Convert to JSON
  toJSON() {
    return {
      assignmentId: this.assignmentId,
      driverId: this.driverId,
      busId: this.busId,
      busNumber: this.busNumber,
      routeId: this.routeId,
      routeName: this.routeName,
      driverName: this.driverName,
      assignedDate: this.assignedDate,
      startTime: this.startTime,
      estimatedDuration: this.estimatedDuration,
      status: this.status,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    };
  }

  // Check if current time is within tracking window (1 hour from start time)
  isTrackingAllowed() {
    try {
      if (!this.startTime) {
        console.log('❌ No start time defined for assignment');
        return { allowed: false, reason: 'No start time defined' };
      }

      const now = new Date();
      const currentTime = now.getHours() * 60 + now.getMinutes(); // Current time in minutes

      // Parse start time (format: "20:00" or "08:00")
      const [startHour, startMinute] = this.startTime.split(':').map(Number);
      const startTimeMinutes = startHour * 60 + startMinute;
      const endTimeMinutes = startTimeMinutes + 60; // 1 hour window

      console.log(`🕐 Time validation:`);
      console.log(`   Current time: ${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')} (${currentTime} minutes)`);
      console.log(`   Start time: ${this.startTime} (${startTimeMinutes} minutes)`);
      console.log(`   End time: ${Math.floor(endTimeMinutes/60).toString().padStart(2, '0')}:${(endTimeMinutes%60).toString().padStart(2, '0')} (${endTimeMinutes} minutes)`);

      // Handle midnight crossover (e.g., start at 23:00, end at 00:00 next day)
      if (endTimeMinutes >= 24 * 60) {
        const nextDayEndTime = endTimeMinutes - 24 * 60;
        if (currentTime >= startTimeMinutes || currentTime <= nextDayEndTime) {
          console.log('✅ Tracking allowed (midnight crossover case)');
          return { allowed: true, reason: 'Within tracking window' };
        }
      } else {
        // Normal case - same day
        if (currentTime >= startTimeMinutes && currentTime <= endTimeMinutes) {
          console.log('✅ Tracking allowed (normal case)');
          return { allowed: true, reason: 'Within tracking window' };
        }
      }

      // Calculate remaining time
      let timeUntilStart = startTimeMinutes - currentTime;
      let timeAfterEnd = currentTime - endTimeMinutes;

      if (timeUntilStart > 0) {
        const hoursUntil = Math.floor(timeUntilStart / 60);
        const minutesUntil = timeUntilStart % 60;
        console.log(`❌ Tracking not allowed - starts in ${hoursUntil}h ${minutesUntil}m`);
        return { 
          allowed: false, 
          reason: `Tracking starts at ${this.startTime}. Please wait ${hoursUntil}h ${minutesUntil}m`,
          timeUntilStart: `${hoursUntil}h ${minutesUntil}m`
        };
      } else {
        const hoursAfter = Math.floor(timeAfterEnd / 60);
        const minutesAfter = timeAfterEnd % 60;
        console.log(`❌ Tracking not allowed - ended ${hoursAfter}h ${minutesAfter}m ago`);
        return { 
          allowed: false, 
          reason: `Tracking window ended at ${Math.floor(endTimeMinutes/60).toString().padStart(2, '0')}:${(endTimeMinutes%60).toString().padStart(2, '0')}. You missed it by ${hoursAfter}h ${minutesAfter}m`,
          timeAfterEnd: `${hoursAfter}h ${minutesAfter}m`
        };
      }

    } catch (error) {
      console.error('Error validating tracking time:', error);
      return { allowed: false, reason: 'Error validating time' };
    }
  }

  // Get formatted tracking window
  getTrackingWindow() {
    if (!this.startTime) return null;

    try {
      const [startHour, startMinute] = this.startTime.split(':').map(Number);
      const endHour = (startHour + 1) % 24;
      const endTimeStr = `${endHour.toString().padStart(2, '0')}:${startMinute.toString().padStart(2, '0')}`;
      
      return {
        startTime: this.startTime,
        endTime: endTimeStr,
        duration: '1 hour'
      };
    } catch (error) {
      console.error('Error formatting tracking window:', error);
      return null;
    }
  }
}

module.exports = DriverAssignment;