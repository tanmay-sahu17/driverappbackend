class ETA {
  constructor() {}

  /**
   * Calculate distance between two points using Haversine formula
   * @param {number} lat1 - Latitude of point 1
   * @param {number} lon1 - Longitude of point 1
   * @param {number} lat2 - Latitude of point 2
   * @param {number} lon2 - Longitude of point 2
   * @returns {number} Distance in meters
   */
  static calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371000; // Earth's radius in meters
    const φ1 = lat1 * Math.PI / 180; // φ, λ in radians
    const φ2 = lat2 * Math.PI / 180;
    const Δφ = (lat2 - lat1) * Math.PI / 180;
    const Δλ = (lon2 - lon1) * Math.PI / 180;

    const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
              Math.cos(φ1) * Math.cos(φ2) *
              Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    const distance = R * c; // Distance in meters
    return distance;
  }

  /**
   * Calculate ETA based on distance and average speed
   * @param {number} distanceInMeters - Distance in meters
   * @param {number} averageSpeedKmh - Average speed in km/h
   * @returns {object} ETA in various formats
   */
  static calculateETA(distanceInMeters, averageSpeedKmh = 40) {
    // Convert distance to kilometers
    const distanceInKm = distanceInMeters / 1000;
    
    // Calculate time in hours
    const timeInHours = distanceInKm / averageSpeedKmh;
    
    // Convert to minutes and seconds
    const totalMinutes = timeInHours * 60;
    const minutes = Math.floor(totalMinutes);
    const seconds = Math.round((totalMinutes - minutes) * 60);

    // Format as readable string
    let formatted = '';
    if (minutes > 60) {
      const hours = Math.floor(minutes / 60);
      const remainingMinutes = minutes % 60;
      formatted = `${hours}h ${remainingMinutes}m`;
    } else if (minutes > 0) {
      formatted = `${minutes}m`;
      if (seconds > 0 && minutes < 5) {
        formatted += ` ${seconds}s`;
      }
    } else {
      formatted = `${seconds}s`;
    }

    return {
      hours: timeInHours,
      minutes: totalMinutes,
      seconds: totalMinutes * 60,
      formatted,
      distanceKm: distanceInKm,
      speedKmh: averageSpeedKmh
    };
  }

  /**
   * Calculate ETA with traffic consideration
   * @param {number} distanceInMeters - Distance in meters
   * @param {number} baseSpeedKmh - Base speed in km/h
   * @param {number} trafficFactor - Traffic factor (0.5 = heavy traffic, 1.0 = normal, 1.5 = light traffic)
   * @returns {object} ETA with traffic consideration
   */
  static calculateETAWithTraffic(distanceInMeters, baseSpeedKmh = 40, trafficFactor = 1.0) {
    const adjustedSpeed = baseSpeedKmh * trafficFactor;
    return this.calculateETA(distanceInMeters, adjustedSpeed);
  }

  /**
   * Get traffic factor based on time of day
   * @param {Date} currentTime - Current time
   * @returns {number} Traffic factor
   */
  static getTrafficFactor(currentTime = new Date()) {
    const hour = currentTime.getHours();
    
    // Peak hours: 7-10 AM and 5-8 PM
    if ((hour >= 7 && hour <= 10) || (hour >= 17 && hour <= 20)) {
      return 0.7; // Heavy traffic
    }
    
    // Normal business hours: 10 AM - 5 PM
    if (hour >= 10 && hour <= 17) {
      return 0.9; // Moderate traffic
    }
    
    // Night time: 10 PM - 6 AM
    if (hour >= 22 || hour <= 6) {
      return 1.3; // Light traffic
    }
    
    return 1.0; // Normal traffic
  }

  /**
   * Calculate smart ETA with automatic traffic consideration
   * @param {number} distanceInMeters - Distance in meters
   * @param {number} baseSpeedKmh - Base speed in km/h
   * @param {Date} currentTime - Current time (optional)
   * @returns {object} Smart ETA calculation
   */
  static calculateSmartETA(distanceInMeters, baseSpeedKmh = 40, currentTime = new Date()) {
    const trafficFactor = this.getTrafficFactor(currentTime);
    const eta = this.calculateETAWithTraffic(distanceInMeters, baseSpeedKmh, trafficFactor);
    
    return {
      ...eta,
      trafficFactor,
      trafficCondition: this.getTrafficCondition(trafficFactor),
      calculatedAt: currentTime.toISOString()
    };
  }

  /**
   * Get traffic condition description
   * @param {number} trafficFactor - Traffic factor
   * @returns {string} Traffic condition
   */
  static getTrafficCondition(trafficFactor) {
    if (trafficFactor <= 0.7) return 'Heavy Traffic';
    if (trafficFactor <= 0.9) return 'Moderate Traffic';
    if (trafficFactor >= 1.2) return 'Light Traffic';
    return 'Normal Traffic';
  }

  /**
   * Calculate multiple destination ETAs
   * @param {object} currentLocation - {latitude, longitude}
   * @param {Array} destinations - Array of {latitude, longitude, name}
   * @param {number} averageSpeedKmh - Average speed in km/h
   * @returns {Array} Array of ETA calculations
   */
  static calculateMultipleETAs(currentLocation, destinations, averageSpeedKmh = 40) {
    return destinations.map(destination => {
      const distance = this.calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        destination.latitude,
        destination.longitude
      );

      const eta = this.calculateSmartETA(distance, averageSpeedKmh);

      return {
        destination: destination.name || 'Unknown',
        coordinates: {
          latitude: destination.latitude,
          longitude: destination.longitude
        },
        distance: {
          meters: Math.round(distance),
          kilometers: Math.round(distance / 1000 * 100) / 100
        },
        eta
      };
    });
  }
}

module.exports = ETA;