# Driver App Backend

Node.js Express backend for the Driver App - Real-time Bus Tracking System.

## Features

- 🔐 **Firebase Authentication** - Secure driver authentication
- 📍 **Location Tracking** - Real-time GPS location updates
- 🚨 **SOS Alerts** - Emergency alert system
- 🚌 **Bus Management** - Bus assignment and tracking
- 🛡️ **Security** - Rate limiting, CORS, validation
- 📊 **Real-time Data** - Firebase Realtime Database integration

## Tech Stack

- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: Firebase Firestore + Realtime Database
- **Authentication**: Firebase Admin SDK
- **Validation**: Joi
- **Security**: Helmet, CORS, Rate Limiting

## Project Structure

```
backend/
├── src/
│   ├── config/
│   │   ├── firebase.js      # Firebase configuration
│   │   └── index.js         # App configuration
│   ├── controllers/         # Route controllers
│   ├── middleware/
│   │   ├── auth.js          # Authentication middleware
│   │   ├── validation.js    # Request validation
│   │   ├── errorHandler.js  # Error handling
│   │   └── rateLimiter.js   # Rate limiting
│   ├── models/
│   │   ├── Bus.js           # Bus model
│   │   ├── Driver.js        # Driver model
│   │   ├── LocationTracking.js
│   │   └── SosAlert.js      # SOS alert model
│   ├── routes/
│   │   ├── auth.js          # Authentication routes
│   │   ├── location.js      # Location tracking routes
│   │   ├── sos.js           # SOS alert routes
│   │   ├── bus.js           # Bus management routes
│   │   └── index.js         # Route aggregator
│   └── server.js            # Main server file
├── .env.example             # Environment variables template
├── .gitignore
├── package.json
└── README.md
```

## Installation

1. **Clone the repository**:
   ```bash
   cd backend
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Environment setup**:
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` file with your Firebase configuration:
   ```env
   PORT=3000
   NODE_ENV=development
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_PRIVATE_KEY="your-private-key"
   FIREBASE_CLIENT_EMAIL=your-client-email
   FIREBASE_DATABASE_URL=https://your-project-default-rtdb.firebaseio.com/
   ```

4. **Start the server**:
   ```bash
   # Development mode
   npm run dev
   
   # Production mode
   npm start
   ```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new driver
- `POST /api/auth/verify` - Verify Firebase token
- `GET /api/auth/profile/:uid` - Get driver profile
- `PUT /api/auth/profile/:uid` - Update driver profile

### Location Tracking
- `POST /api/location/update` - Update driver location
- `GET /api/location/history/:driverId` - Get location history
- `GET /api/location/live/:driverId` - Get live location
- `POST /api/location/batch` - Batch update locations
- `GET /api/location/nearby` - Find nearby drivers

### SOS Alerts
- `POST /api/sos/alert` - Create SOS alert
- `GET /api/sos/alerts/:driverId` - Get active alerts
- `PUT /api/sos/resolve/:alertId` - Resolve SOS alert
- `GET /api/sos/all` - Get all active alerts
- `GET /api/sos/history/:driverId` - Get alert history

### Bus Management
- `GET /api/bus/list` - Get bus list
- `GET /api/bus/:busNumber` - Get bus details
- `POST /api/bus/assign` - Assign driver to bus
- `POST /api/bus/unassign` - Unassign driver from bus

### System
- `GET /api/health` - Health check
- `GET /api/docs` - API documentation

## Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)

2. Enable Authentication and Firestore Database

3. Generate a service account key:
   - Go to Project Settings > Service Accounts
   - Generate new private key
   - Save as JSON and extract values for `.env`

4. Enable these Firebase services:
   - **Authentication** (Email/Password)
   - **Firestore Database**
   - **Realtime Database**

## Usage Examples

### Register Driver
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "driver@example.com",
    "password": "password123",
    "driverName": "John Doe",
    "phoneNumber": "+919876543210",
    "licenseNumber": "DL1234567890"
  }'
```

### Update Location
```bash
curl -X POST http://localhost:3000/api/location/update \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
  -d '{
    "driverId": "driver_uid",
    "busNumber": "BUS001",
    "latitude": 28.6139,
    "longitude": 77.2090,
    "accuracy": 10,
    "speed": 40
  }'
```

### Send SOS Alert
```bash
curl -X POST http://localhost:3000/api/sos/alert \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
  -d '{
    "driverId": "driver_uid",
    "busNumber": "BUS001",
    "latitude": 28.6139,
    "longitude": 77.2090,
    "emergencyMessage": "Need immediate assistance"
  }'
```

## Security Features

- **Rate Limiting**: Prevents API abuse
- **CORS**: Configured for specific origins
- **Input Validation**: Joi schema validation
- **Authentication**: Firebase token verification
- **Error Handling**: Structured error responses
- **Security Headers**: Helmet.js implementation

## Development

1. **Run in development mode**:
   ```bash
   npm run dev
   ```

2. **Test API endpoints**:
   - Use Postman or curl
   - Check `/api/docs` for endpoint documentation
   - Monitor `/api/health` for service status

## Production Deployment

1. **Environment Variables**:
   - Set `NODE_ENV=production`
   - Configure production Firebase project
   - Set secure JWT secrets

2. **Process Management**:
   ```bash
   # Using PM2
   npm install -g pm2
   pm2 start src/server.js --name "driverapp-backend"
   ```

3. **Reverse Proxy**:
   - Configure Nginx for load balancing
   - Set up SSL certificates
   - Enable proper logging

## Monitoring

- **Logs**: Morgan HTTP request logging
- **Health Check**: `/api/health` endpoint
- **Error Tracking**: Structured error responses
- **Firebase Monitoring**: Built-in Firebase metrics

## Contributing

1. Follow Node.js best practices
2. Add proper error handling
3. Include input validation
4. Update API documentation
5. Test all endpoints

## License

MIT License - Built for Smart India Hackathon