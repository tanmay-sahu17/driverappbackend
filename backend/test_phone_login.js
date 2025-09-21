const { db } = require('./src/config/firebase');
const Driver = require('./src/models/Driver');

async function testPhoneLogin() {
  console.log('🧪 Testing phone-based login functionality...');
  
  try {
    // Test phone number
    const testPhone = '9876543210';
    
    console.log(`📞 Testing phone number: ${testPhone}`);
    
    // Find driver by phone
    const driver = await Driver.findByPhone(testPhone);
    
    if (driver) {
      console.log('✅ Driver found:');
      console.log(`   Name: ${driver.driverName}`);
      console.log(`   Email: ${driver.email}`);
      console.log(`   Phone: ${driver.phoneNumber}`);
      console.log(`   ID: ${driver.id}`);
      
      if (driver.email) {
        console.log('✅ Email is available for Firebase Auth login');
      } else {
        console.log('❌ No email found - phone login will fail');
      }
    } else {
      console.log('❌ No driver found with this phone number');
      
      // List all drivers to see what phone numbers exist
      console.log('\n📋 Available drivers in database:');
      const allDrivers = await db.collection('drivers').get();
      allDrivers.docs.forEach(doc => {
        const data = doc.data();
        console.log(`   ${data.driverName}: ${data.phoneNumber} -> ${data.email || 'No email'}`);
      });
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

// Run the test
testPhoneLogin()
  .then(() => {
    console.log('🎉 Phone login test completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Test failed:', error);
    process.exit(1);
  });
