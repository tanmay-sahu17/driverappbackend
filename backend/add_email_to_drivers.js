const { db, auth } = require('./src/config/firebase');

async function addEmailToDrivers() {
  try {
    console.log('🔧 Starting to add email field to existing drivers...');
    
    // Get all drivers
    const driversSnapshot = await db.collection('drivers').get();
    
    if (driversSnapshot.empty) {
      console.log('❌ No drivers found in the database');
      return;
    }

    console.log(`📊 Found ${driversSnapshot.size} drivers to update`);

    const batch = db.batch();
    let updateCount = 0;

    for (const doc of driversSnapshot.docs) {
      const driverData = doc.data();
      const driverId = doc.id;

      try {
        // Check if email field already exists
        if (driverData.email) {
          console.log(`✅ Driver ${driverData.driverName} already has email: ${driverData.email}`);
          continue;
        }

        // Try to get email from Firebase Auth using the driver ID
        let email = null;
        try {
          const userRecord = await auth.getUser(driverId);
          email = userRecord.email;
          console.log(`📧 Found email for ${driverData.driverName}: ${email}`);
        } catch (authError) {
          // If Firebase user not found, create a default email
          const phoneNumber = driverData.phoneNumber?.replace(/\D/g, '') || '0000000000';
          email = `driver${phoneNumber}@driverapp.com`;
          console.log(`⚠️ Firebase user not found for ${driverData.driverName}, using default email: ${email}`);
        }

        // Update the driver document
        const driverRef = db.collection('drivers').doc(driverId);
        batch.update(driverRef, {
          email: email,
          updatedAt: new Date()
        });

        updateCount++;
        console.log(`📝 Queued update for ${driverData.driverName} with email: ${email}`);

      } catch (error) {
        console.error(`❌ Error processing driver ${driverData.driverName}:`, error);
      }
    }

    // Commit the batch update
    if (updateCount > 0) {
      await batch.commit();
      console.log(`✅ Successfully updated ${updateCount} drivers with email field`);
    } else {
      console.log('✅ All drivers already have email field');
    }

  } catch (error) {
    console.error('❌ Error adding email to drivers:', error);
  }
}

// Run the script
addEmailToDrivers()
  .then(() => {
    console.log('🎉 Email field addition completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Script failed:', error);
    process.exit(1);
  });