const mongoose = require('mongoose');
const config = require('./env');
const { logger } = require('./logger');

const connectDB = async () => {
    try {
        mongoose.set('strictQuery', false);

        await mongoose.connect(config.MONGODB_URI, {
            maxPoolSize: config.NODE_ENV === 'production' ? 20 : 10, // [FIX MED-4] Atlas M0 = 500 conn limit
            minPoolSize: config.NODE_ENV === 'production' ? 10 : 2,
            serverSelectionTimeoutMS: 5000,
            socketTimeoutMS: 45000,
        });

        logger.info('MongoDB connected successfully');

        // Connection events
        mongoose.connection.on('error', (err) => {
            logger.error({ err }, 'MongoDB connection error');
        });

        mongoose.connection.on('disconnected', () => {
            logger.warn('MongoDB disconnected');
        });

    } catch (error) {
        logger.error({ err: error }, 'MongoDB connection failed');
        process.exit(1);
    }
};

module.exports = connectDB;
