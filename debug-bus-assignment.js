#!/usr/bin/env node

const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api';

console.log('🔍 Debugging Bus Assignment Issue\n');
console.log('=====================================\n');

async function debugBusAssignment() {
  try {
    // Test 1: Check all buses
    console.log('1️⃣ Getting all buses...');
    const busResponse = await axios.get(`${BASE_URL}/bus`);
    
    if (busResponse.data.success) {
      console.log(`✅ Found ${busResponse.data.buses.length} buses:`);
      busResponse.data.buses.forEach((bus, index) => {
        console.log(`   ${index + 1}. ID: ${bus.id || bus.busId || 'Unknown'} | Number: ${bus.busNumber}`);
      });
    } else {
      console.log('❌ Failed to get buses');
    }

    // Test 2: Check specific driver assignment
    console.log('\n2️⃣ Checking driver assignment...');
    const driverId = 'XcZS7D5l7CKH5l0HNwKn'; // From screenshot
    
    try {
      const assignmentResponse = await axios.get(`${BASE_URL}/assignment/driver/${driverId}`);
      
      if (assignmentResponse.data.success) {
        console.log('✅ Assignment found:');
        console.log(`   Assignment ID: ${assignmentResponse.data.assignment.assignmentId}`);
        console.log(`   Bus ID: ${assignmentResponse.data.assignment.busId}`);
        console.log(`   Assigned Bus: ${assignmentResponse.data.assignedBus ? assignmentResponse.data.assignedBus.busNumber : 'NOT FOUND'}`);
      } else {
        console.log('❌ No assignment found:', assignmentResponse.data.message);
      }
    } catch (error) {
      console.log('❌ Assignment error:', error.response?.data?.message || error.message);
    }

    // Test 3: Try to find the specific bus ID from assignment
    console.log('\n3️⃣ Trying to find bus with ID: 3736zIMtGqT2xi6s6Cyo...');
    try {
      const specificBusResponse = await axios.get(`${BASE_URL}/bus/3736zIMtGqT2xi6s6Cyo`);
      console.log('✅ Bus found:', specificBusResponse.data);
    } catch (error) {
      console.log('❌ Bus not found with this ID');
    }

    // Test 4: Login test to see assignment data
    console.log('\n4️⃣ Testing login to see assignment data...');
    try {
      const loginResponse = await axios.post(`${BASE_URL}/auth/login`, {
        contactNumber: '9876543210', // Test driver
        password: 'testPassword123'
      });

      if (loginResponse.data.success) {
        console.log('✅ Login successful');
        console.log('🎯 Assignment in login:', loginResponse.data.assignment ? 'Yes' : 'No');
        console.log('🚌 Assigned Bus in login:', loginResponse.data.assignedBus ? loginResponse.data.assignedBus.busNumber : 'None');
      }
    } catch (error) {
      console.log('❌ Login error:', error.response?.data?.message || error.message);
    }

  } catch (error) {
    console.error('❌ Debug failed:', error.message);
  }
}

// Check if server is running
async function checkServer() {
  try {
    const response = await axios.get(`${BASE_URL}/health`);
    if (response.data.success) {
      console.log('✅ Server is running\n');
      return true;
    }
  } catch (error) {
    console.log('❌ Server is not running. Please start the backend server first.');
    console.log('   Run: cd backend && npm start\n');
    return false;
  }
}

async function main() {
  const serverRunning = await checkServer();
  if (serverRunning) {
    await debugBusAssignment();
  }
  
  console.log('\n🏁 Debug completed!');
  console.log('\n💡 SOLUTION: Make sure the busId in driverAssigns matches an actual bus document ID in the buses collection.');
}

main().catch(console.error);