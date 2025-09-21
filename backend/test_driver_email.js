const { db, auth } = require('./src/config/firebase');
const Driver = require('./src/models/Driver');

async function testDriverCreation() {
  console.log('🧪 Testing driver creation with email field...');
  
  try {
    // Test data
    const testDriverData = {
      id: 'test-driver-' + Date.now(),
      driverName: 'Test Driver Email',
      email: 'testdriver@email.com',
      phoneNumber: '9999999999',
      licenseNumber: 'TEST123456',
      licenseType: 'commercial',
      status: 'active'
    };

    console.log('📝 Creating driver with data:', testDriverData);

    // Create driver instance
    const driver = new Driver(testDriverData);
    
    // Test toJSON method
    const jsonData = driver.toJSON();
    console.log('📄 Driver toJSON output:', jsonData);
    
    // Check if email is included
    if (jsonData.email) {
      console.log('✅ Email field is included in toJSON:', jsonData.email);
    } else {
      console.log('❌ Email field is missing in toJSON');
    }
    
    // Save to database
    await driver.save();
    console.log('💾 Driver saved to database');
    
    // Verify in database
    const savedDriver = await Driver.findById(testDriverData.id);
    if (savedDriver && savedDriver.email) {
      console.log('✅ Email field saved to database:', savedDriver.email);
    } else {
      console.log('❌ Email field not found in database');
    }
    
    // Clean up - delete test driver
    await db.collection('drivers').doc(testDriverData.id).delete();
    console.log('🗑️ Test driver cleaned up');
    
    console.log('🎉 Test completed successfully!');
    
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

// Run the test
testDriverCreation()
  .then(() => {
    console.log('✅ Driver email field test completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Test failed:', error);
    process.exit(1);
  });