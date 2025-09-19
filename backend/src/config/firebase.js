const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');
const { getDatabase } = require('firebase-admin/database');
const path = require('path');
require('dotenv').config();

// Initialize Firebase Admin
if (!admin.apps.length) {
  try {
    // Load service account key directly
    const serviceAccount = require('./serviceAccountKey.json');
    
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      databaseURL: 'https://trackmyride123-default-rtdb.asia-southeast1.firebasedatabase.app/'
    });
    
    console.log('✅ Firebase Admin initialized successfully');
    console.log('🔥 Project ID:', serviceAccount.project_id);
    console.log('📧 Client Email:', serviceAccount.client_email);
    
  } catch (error) {
    console.error('❌ Firebase Admin initialization error:', error.message);
    console.error('Full error:', error);
    process.exit(1);
  }
} else {
  console.log('🔥 Firebase Admin already initialized');
}

// Get database instances
const db = getFirestore();
const rtdb = getDatabase();
const auth = admin.auth();

// Test Firebase connection
const testConnection = async () => {
  try {
    // Test Firestore connection
    await db.collection('health').doc('test').set({
      status: 'connected',
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Test Realtime Database connection
    await rtdb.ref('health/test').set({
      status: 'connected',
      timestamp: admin.database.ServerValue.TIMESTAMP
    });
    
    console.log('✅ Firebase connected successfully');
    return true;
  } catch (error) {
    console.error('❌ Firebase connection failed:', error.message);
    return false;
  }
};

module.exports = {
  admin,
  db,
  rtdb,
  auth,
  testConnection
};