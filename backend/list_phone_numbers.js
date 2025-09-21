const { db } = require('./src/config/firebase');

async function listAllPhoneNumbers() {
  console.log('📱 Listing all phone numbers in database...');
  
  try {
    const driversSnapshot = await db.collection('drivers').get();
    
    if (driversSnapshot.empty) {
      console.log('❌ No drivers found in database');
      return;
    }

    console.log(`📊 Found ${driversSnapshot.size} drivers:`);
    console.log('');
    
    driversSnapshot.docs.forEach((doc, index) => {
      const data = doc.data();
      console.log(`${index + 1}. Name: ${data.driverName || 'Unknown'}`);
      console.log(`   Phone: ${data.phoneNumber || 'No phone'}`);
      console.log(`   Email: ${data.email || 'No email'}`);
      console.log(`   ID: ${doc.id}`);
      console.log('');
    });
    
    console.log('📝 To test login, use any of the above phone numbers');
    
  } catch (error) {
    console.error('❌ Error listing phone numbers:', error);
  }
}

// Run the script
listAllPhoneNumbers()
  .then(() => {
    console.log('✅ Phone number listing completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Script failed:', error);
    process.exit(1);
  });