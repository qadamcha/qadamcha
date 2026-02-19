require('dotenv').config();

module.exports = {
    // Server
    PORT: process.env.PORT || 3000,
    NODE_ENV: process.env.NODE_ENV || 'development',

    // Railway (avtomatik beriladi)
    RAILWAY_PUBLIC_DOMAIN: process.env.RAILWAY_PUBLIC_DOMAIN || null,

    // Public URL (Railway yoki custom domain)
    get PUBLIC_URL() {
        if (this.NODE_ENV === 'production' && this.RAILWAY_PUBLIC_DOMAIN) {
            return `https://${this.RAILWAY_PUBLIC_DOMAIN}`;
        }
        return `http://localhost:${this.PORT}`;
    },

    // Database
    MONGODB_URI: process.env.MONGODB_URI || 'mongodb://localhost:27017/qadamcha',
    REDIS_URL: process.env.REDIS_URL || 'redis://localhost:6379',

    // CORS
    ALLOWED_ORIGINS: process.env.ALLOWED_ORIGINS || 'http://localhost:3000',

    // Sentry
    SENTRY_DSN: process.env.SENTRY_DSN || null,

    // Firebase (Push Notifications)
    FIREBASE_SERVICE_ACCOUNT: process.env.FIREBASE_SERVICE_ACCOUNT || null,

    // JWT
    JWT_SECRET: process.env.JWT_SECRET || 'dev-only-secret-do-not-use-in-production',
    JWT_ACCESS_EXPIRES: '15m',
    JWT_REFRESH_EXPIRES: '30d',

    // Security: Validate all critical configs in production
    validateSecurity() {
        if (this.NODE_ENV === 'production') {
            const required = {
                JWT_SECRET: { envKey: 'JWT_SECRET', minLen: 32 },
                MONGODB_URI: { envKey: 'MONGODB_URI', minLen: 10 },
                REDIS_URL: { envKey: 'REDIS_URL', minLen: 10 },
                // ESKIZ — ixtiyoriy (hali ruxsat olinmagan bo'lishi mumkin)
                // ESKIZ_EMAIL: { envKey: 'ESKIZ_EMAIL', minLen: 3 },
                // ESKIZ_PASSWORD: { envKey: 'ESKIZ_PASSWORD', minLen: 3 },
                BUNNY_LIBRARY_ID: { envKey: 'BUNNY_STREAM_LIBRARY_ID', minLen: 1 },
                BUNNY_API_KEY: { envKey: 'BUNNY_STREAM_API_KEY', minLen: 10 },
                ALLOWED_ORIGINS: { envKey: 'ALLOWED_ORIGINS', minLen: 1 },
                PAYME_MERCHANT_ID: { envKey: 'PAYME_MERCHANT_ID', minLen: 10 },
                PAYME_KEY: { envKey: 'PAYME_KEY', minLen: 5 },
            };

            const missing = [];
            for (const [name, { envKey, minLen }] of Object.entries(required)) {
                const val = process.env[envKey];
                if (!val || val.length < minLen) {
                    missing.push(name);
                }
            }

            if (missing.length > 0) {
                throw new Error(`Production da quyidagi env o'zgaruvchilar kerak: ${missing.join(', ')}`);
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

    // Payme
    PAYME_MERCHANT_ID: process.env.PAYME_MERCHANT_ID,
    PAYME_KEY: process.env.PAYME_KEY,
    PAYME_API_URL: process.env.PAYME_API_URL || 'https://checkout.paycom.uz/api',

    // Gemini AI
    GEMINI_API_KEY: process.env.GEMINI_API_KEY,

    // App Settings
    OTP_EXPIRES: 5 * 60, // 5 daqiqa (sekundlarda)
    MAX_DEVICES: 3,      // Maksimal qurilma soni
    TEST_PHONE: process.env.TEST_PHONE || null, // Faqat development uchun

    // Subscription Plans (so'mda — Payme uchun controller da × 100 = tiyin)
    PLANS: {
        monthly: { price: 1000, days: 30, name: 'Oylik' },      // 1,000 so'm (test/demo)
        yearly: { price: 399000, days: 365, name: 'Yillik' },   // 399,000 so'm
        lifetime: { price: 990000, days: 36500, name: 'Umrbod' } // 990,000 so'm
    }
};
