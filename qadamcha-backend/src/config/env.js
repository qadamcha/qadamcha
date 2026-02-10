require('dotenv').config();

module.exports = {
    // Server
    PORT: process.env.PORT || 3000,
    NODE_ENV: process.env.NODE_ENV || 'development',

    // Database
    MONGODB_URI: process.env.MONGODB_URI || 'mongodb://localhost:27017/qadamcha',
    REDIS_URL: process.env.REDIS_URL || 'redis://localhost:6379',

    // JWT
    JWT_SECRET: process.env.JWT_SECRET || 'dev-only-secret-do-not-use-in-production',
    JWT_ACCESS_EXPIRES: '15m',
    JWT_REFRESH_EXPIRES: '30d',

    // Security: Ensure strong JWT secret in production
    validateSecurity() {
        if (this.NODE_ENV === 'production') {
            if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) {
                throw new Error('Production JWT_SECRET must be at least 32 characters!');
            }
        }
    },

    // Eskiz SMS
    ESKIZ_EMAIL: process.env.ESKIZ_EMAIL,
    ESKIZ_PASSWORD: process.env.ESKIZ_PASSWORD,
    ESKIZ_BASE_URL: 'https://notify.eskiz.uz/api',

    // Bunny.net
    BUNNY_LIBRARY_ID: process.env.BUNNY_STREAM_LIBRARY_ID,
    BUNNY_API_KEY: process.env.BUNNY_STREAM_API_KEY,
    BUNNY_CDN_HOST: process.env.BUNNY_CDN_HOSTNAME,

    // Gemini AI
    GEMINI_API_KEY: process.env.GEMINI_API_KEY,

    // App Settings
    OTP_EXPIRES: 5 * 60, // 5 daqiqa (sekundlarda)
    MAX_DEVICES: 3,      // Maksimal qurilma soni

    // Subscription Plans (UZS)
    PLANS: {
        monthly: { price: 49000, days: 30, name: 'Oylik' },
        yearly: { price: 399000, days: 365, name: 'Yillik' },
        lifetime: { price: 990000, days: 36500, name: 'Umrbod' }
    }
};
