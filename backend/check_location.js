const { db } = require('./src/config/firebase');

async function checkLocationUpdates() {
  try {
    console.log('🔍 CHECKING LOCATION UPDATES...');
    console.log('==================================');
    
    const snapshot = await db.collection('locationTracking')
      .orderBy('timestamp', 'desc')
      .limit(5)
      .get();
    
    if (snapshot.empty) {
      console.log('❌ No location tracking data found');
      return;
    }
    
    console.log('📍 LATEST LOCATION UPDATES:');
    snapshot.forEach((doc, index) => {
      const data = doc.data();
      console.log(`${index + 1}. Driver: ${data.driverId}`);
      console.log(`   Bus: ${data.busNumber}`);
      console.log(`   Lat: ${data.latitude}`);
      console.log(`   Lng: ${data.longitude}`);
      console.log(`   Time: ${data.timestamp.toDate()}`);
      console.log(`   Accuracy: ${data.accuracy}m`);
      console.log('   ---');
    });
    
    const latestDoc = snapshot.docs[0];
    const latestTime = latestDoc.data().timestamp.toDate();
    const timeDiff = (new Date() - latestTime) / 1000;
    
    console.log(`⏰ Latest update was ${Math.round(timeDiff)} seconds ago`);
    
    if (timeDiff < 120) {
      console.log('✅ Location updates are ACTIVE and WORKING!');
    } else {
      console.log('⚠️ Location updates seem inactive (>2 min old)');
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
  process.exit(0);
}

checkLocationUpdates();