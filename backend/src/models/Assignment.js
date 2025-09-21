const { db } = require('../config/firebase');

class Assignment {
  constructor(data) {
    this.id = data.id;
    this.driverId = data.driverId;
    this.busNumber = data.busNumber;
    this.driverName = data.driverName;
    this.routeId = data.routeId;
    this.routeName = data.routeName;
    this.startTime = data.startTime;
    this.estimatedDuration = data.estimatedDuration;
    this.status = data.status || 'active';
    this.totalDistance = data.totalDistance;
    this.totalStops = data.totalStops;
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }

  // Find assignment by driver ID from assignments collection
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
      const assignment = new Assignment({ id: doc.id, ...doc.data() });
      console.log(`✅ Found active assignment for driver ${driverId}: Bus ${assignment.busNumber}, Start Time: ${assignment.startTime}`);
      return assignment;
    } catch (error) {
      console.error('Error finding active assignment by driver ID:', error);
      throw error;
    }
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

      console.log(`🕐 Time validation for assignment:`);
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

  // Get bus details by busNumber
  async getBusDetails() {
    try {
      const Bus = require('./Bus');
      return await Bus.findByNumber(this.busNumber);
    } catch (error) {
      console.error('Error getting bus details:', error);
      throw error;
    }
  }

  // Convert to JSON
  toJSON() {
    return {
      id: this.id,
      driverId: this.driverId,
      busNumber: this.busNumber,
      driverName: this.driverName,
      routeId: this.routeId,
      routeName: this.routeName,
      startTime: this.startTime,
      estimatedDuration: this.estimatedDuration,
      status: this.status,
      totalDistance: this.totalDistance,
      totalStops: this.totalStops,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    };
  }
}

module.exports = Assignment;