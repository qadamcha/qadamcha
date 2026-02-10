const mongoose = require('mongoose');
const config = require('./env');

const connectDB = async () => {
    try {
        mongoose.set('strictQuery', false);

        await mongoose.connect(config.MONGODB_URI, {
            maxPoolSize: 100,
            minPoolSize: 10,
            serverSelectionTimeoutMS: 5000,
            socketTimeoutMS: 45000,
        });

        console.log('✅ MongoDB connected successfully');

        // Connection events
        mongoose.connection.on('error', (err) => {
            console.error('❌ MongoDB connection error:', err);
        });

        mongoose.connection.on('disconnected', () => {
            console.warn('⚠️ MongoDB disconnected');
        });

    } catch (error) {
        console.error('❌ MongoDB connection failed:', error.message);
        process.exit(1);
    }
};

module.exports = connectDB;
