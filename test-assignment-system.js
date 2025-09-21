#!/usr/bin/env node

const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api';

console.log('🧪 Testing Driver Assignment System\n');
console.log('=====================================\n');

async function testAssignmentSystem() {
  try {
    // Test 1: Login with test driver
    console.log('1️⃣ Testing Login (should include assignment data)...');
    const loginResponse = await axios.post(`${BASE_URL}/auth/login`, {
      contactNumber: '9876543210',
      password: 'testPassword123'
    });

    if (loginResponse.data.success) {
      console.log('✅ Login successful');
      console.log('👤 Driver:', loginResponse.data.driver.name);
      console.log('🎯 Assignment:', loginResponse.data.assignment ? 'Yes' : 'No');
      console.log('🚌 Assigned Bus:', loginResponse.data.assignedBus ? loginResponse.data.assignedBus.busNumber : 'None');
      
      const driverId = loginResponse.data.driver.driverId;
      
      // Test 2: Get specific driver assignment
      console.log('\n2️⃣ Testing Get Driver Assignment...');
      try {
        const assignmentResponse = await axios.get(`${BASE_URL}/assignment/driver/${driverId}`);
        console.log('✅ Assignment found:', assignmentResponse.data.assignedBus?.busNumber || 'No bus');
      } catch (error) {
        if (error.response?.status === 404) {
          console.log('❌ No assignment found for driver');
        } else {
          console.log('❌ Error fetching assignment:', error.message);
        }
      }
      
      // Test 3: Get all active assignments
      console.log('\n3️⃣ Testing Get All Active Assignments...');
      try {
        const activeResponse = await axios.get(`${BASE_URL}/assignment/active`);
        console.log(`✅ Found ${activeResponse.data.assignments.length} active assignments`);
        activeResponse.data.assignments.forEach((assignment, index) => {
          console.log(`   ${index + 1}. Driver: ${assignment.driver?.name || 'Unknown'} -> Bus: ${assignment.bus?.busNumber || 'Unknown'}`);
        });
      } catch (error) {
        console.log('❌ Error fetching active assignments:', error.message);
      }
      
      // Test 4: Create a test assignment (if none exists)
      if (!loginResponse.data.assignment) {
        console.log('\n4️⃣ Testing Create Assignment...');
        
        // First, let's get a test bus ID
        try {
          const busResponse = await axios.get(`${BASE_URL}/bus`);
          if (busResponse.data.buses && busResponse.data.buses.length > 0) {
            const testBusId = busResponse.data.buses[0].busId;
            
            const createResponse = await axios.post(`${BASE_URL}/assignment/create`, {
              driverId: driverId,
              busId: testBusId,
              routeId: 'test-route-1',
              startTime: '09:00'
            });
            
            console.log('✅ Assignment created:', createResponse.data.message);
            console.log('🆔 Assignment ID:', createResponse.data.assignment.assignmentId);
            
            // Test assignment update
            console.log('\n5️⃣ Testing Assignment Status Update...');
            const updateResponse = await axios.put(`${BASE_URL}/assignment/${createResponse.data.assignment.assignmentId}/status`, {
              status: 'active'
            });
            console.log('✅ Status updated:', updateResponse.data.message);
            
          } else {
            console.log('❌ No buses found to create assignment');
          }
        } catch (error) {
          console.log('❌ Error creating assignment:', error.response?.data?.message || error.message);
        }
      }
      
    } else {
      console.log('❌ Login failed:', loginResponse.data.message);
    }

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data?.message || error.message);
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
    await testAssignmentSystem();
  }
  
  console.log('\n🏁 Assignment system test completed!');
}

main().catch(console.error);