#!/usr/bin/env node

console.log('🕐 Testing Time-Based Tracking System\n');
console.log('=====================================\n');

// Backend direct test
const DriverAssignment = require('./backend/src/models/DriverAssignment');

async function testTimeValidation() {
  try {
    console.log('1️⃣ Testing assignment time validation...\n');
    
    // Get assignment for our test driver
    const driverId = '7a03bc8e-541d-4c0c-b9f3-5ed030e87a59';
    const assignment = await DriverAssignment.findActiveByDriverId(driverId);
    
    if (!assignment) {
      console.log('❌ No assignment found for test driver');
      return;
    }
    
    console.log('✅ Assignment found:');
    console.log(`   Assignment ID: ${assignment.assignmentId}`);
    console.log(`   Start Time: ${assignment.startTime}`);
    console.log(`   Bus ID: ${assignment.busId}\n`);
    
    // Test time validation
    console.log('2️⃣ Testing time validation...\n');
    const timeValidation = assignment.isTrackingAllowed();
    
    console.log(`📊 Validation Result:`);
    console.log(`   Can Start Tracking: ${timeValidation.allowed ? '✅ YES' : '❌ NO'}`);
    console.log(`   Reason: ${timeValidation.reason}`);
    
    if (timeValidation.timeUntilStart) {
      console.log(`   Time Until Start: ${timeValidation.timeUntilStart}`);
    }
    
    if (timeValidation.timeAfterEnd) {
      console.log(`   Time After End: ${timeValidation.timeAfterEnd}`);
    }
    
    // Show tracking window
    console.log('\n3️⃣ Tracking Window Information...\n');
    const trackingWindow = assignment.getTrackingWindow();
    if (trackingWindow) {
      console.log(`📅 Tracking Window:`);
      console.log(`   Start Time: ${trackingWindow.startTime}`);
      console.log(`   End Time: ${trackingWindow.endTime}`);
      console.log(`   Duration: ${trackingWindow.duration}`);
    }
    
    // Current time
    const now = new Date();
    console.log(`\n🕐 Current Time: ${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`);
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

// Test different time scenarios
async function testTimeScenarios() {
  console.log('\n4️⃣ Testing Different Time Scenarios...\n');
  
  // Create test assignments with different start times
  const testTimes = ['08:00', '12:30', '18:00', '20:00', '23:30'];
  
  for (const startTime of testTimes) {
    console.log(`\n🔍 Testing start time: ${startTime}`);
    
    // Create temporary assignment
    const testAssignment = new DriverAssignment({
      driverId: 'test-driver',
      busId: 'test-bus',
      startTime: startTime,
      status: 'active'
    });
    
    const validation = testAssignment.isTrackingAllowed();
    const window = testAssignment.getTrackingWindow();
    
    console.log(`   Window: ${window.startTime} - ${window.endTime}`);
    console.log(`   Status: ${validation.allowed ? '✅ ALLOWED' : '❌ NOT ALLOWED'}`);
    console.log(`   Reason: ${validation.reason}`);
  }
}

async function main() {
  console.log('🚀 Starting Time Validation Tests...\n');
  
  try {
    await testTimeValidation();
    await testTimeScenarios();
    
    console.log('\n🏁 Time validation system test completed!');
    console.log('\n💡 How it works:');
    console.log('   - Driver can start tracking from startTime to startTime + 1 hour');
    console.log('   - Example: startTime 20:00 → tracking allowed 20:00 to 21:00');
    console.log('   - After 21:00, tracking will be blocked');
    console.log('   - Before 20:00, tracking will show time remaining until start');
    
  } catch (error) {
    console.error('❌ Test suite failed:', error.message);
  } finally {
    process.exit();
  }
}

main();