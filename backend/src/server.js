const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
require('dotenv').config();

const config = require('./config');
const { testConnection } = require('./config/firebase');
const routes = require('./routes');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');
const { generalLimiter } = require('./middleware/rateLimiter');

// Create Express app
const app = express();

// Trust proxy (for rate limiting behind reverse proxy)
app.set('trust proxy', 1);

// Security middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));

// CORS configuration
app.use(cors(config.cors));

// Compression middleware
app.use(compression());

// Logging middleware
app.use(morgan(config.logging.format));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Rate limiting
app.use(generalLimiter);

// API routes
app.use('/api', routes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Driver App Backend API',
    version: '1.0.0',
    environment: config.env,
    documentation: '/api/docs',
    health: '/api/health'
  });
});

// 404 handler
app.use(notFoundHandler);

// Global error handler
app.use(errorHandler);

// Graceful shutdown
const gracefulShutdown = (signal) => {
  console.log(`\n📥 Received ${signal}. Starting graceful shutdown...`);
  
  server.close(() => {
    console.log('✅ HTTP server closed');
    process.exit(0);
  });

  // Force shutdown after 10 seconds
  setTimeout(() => {
    console.log('⚠️ Forcing shutdown');
    process.exit(1);
  }, 10000);
};

// Start server
const startServer = async () => {
  try {
    // Test Firebase connection
    console.log('🔥 Testing Firebase connection...');
    const firebaseConnected = await testConnection();
    
    if (!firebaseConnected) {
      console.error('❌ Firebase connection failed. Please check your configuration.');
      process.exit(1);
    }

    // Start HTTP server
    const server = app.listen(config.port, () => {
      console.log(`\n🚀 Driver App Backend Server`);
      console.log(`📍 Environment: ${config.env}`);
      console.log(`🌐 Server: http://localhost:${config.port}`);
      console.log(`📚 API Docs: http://localhost:${config.port}/api/docs`);
      console.log(`💓 Health: http://localhost:${config.port}/api/health`);
      console.log(`\n🔥 Firebase: Connected`);
      console.log(`⚡ Express: Ready for requests\n`);
    });

    // Handle graceful shutdown
    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));

    return server;
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error('💥 Uncaught Exception:', err);
  process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  console.error('💥 Unhandled Rejection:', err);
  process.exit(1);
});

// Start the server if this file is run directly
if (require.main === module) {
  startServer();
}

module.exports = app;