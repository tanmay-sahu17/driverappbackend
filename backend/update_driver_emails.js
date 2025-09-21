const { db } = require('./src/config/firebase');

async function updateDriverEmails() {
  try {
    console.log('🔄 Starting driver email update process...');
    
    // Get all drivers
    const driversSnapshot = await db.collection('drivers').get();
    
    if (driversSnapshot.empty) {
      console.log('❌ No drivers found in database');
      return;
    }

    console.log(`📊 Found ${driversSnapshot.size} drivers to update`);
    
    let updatedCount = 0;
    
    for (const doc of driversSnapshot.docs) {
      const driverData = doc.data();
      const driverId = doc.id;
      
      // Extract phone number and normalize it
      let phoneNumber = driverData.phoneNumber;
      if (phoneNumber) {
        // Clean phone number
        const cleanPhone = phoneNumber.replace(/\D/g, '');
        const normalizedPhone = cleanPhone.length > 10 ? 
          cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;
        
        // Generate new email
        const generatedEmail = `driver_${normalizedPhone}@busdriver.app`;
        
        // Update driver with generated email and normalized phone
        await db.collection('drivers').doc(driverId).update({
          email: generatedEmail,
          phoneNumber: normalizedPhone
        });
        
        console.log(`✅ Updated driver ${driverData.driverName}: phone=${normalizedPhone}, email=${generatedEmail}`);
        updatedCount++;
      } else {
        console.log(`⚠️ Driver ${driverData.driverName} has no phone number, skipping...`);
      }
    }
    
    console.log(`🎉 Successfully updated ${updatedCount} drivers with generated emails`);
    
  } catch (error) {
    console.error('❌ Error updating driver emails:', error);
  }
}

// Run the update
updateDriverEmails().then(() => {
  console.log('✅ Driver email update process completed');
  process.exit(0);
}).catch((error) => {
  console.error('❌ Failed to update driver emails:', error);
  process.exit(1);
});