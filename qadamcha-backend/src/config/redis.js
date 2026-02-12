const Redis = require('ioredis');
const config = require('./env');

let redis = null;
let isMocked = false;

const fallbackToMock = (reason) => {
    if (isMocked) return;

    // Production da mock ruxsat etilmaydi — crash qilsin
    if (config.NODE_ENV === 'production') {
        console.error(`❌ CRITICAL: ${reason}. Production da Redis MAJBURIY!`);
        process.exit(1);
    }

    console.warn(`⚠️ ${reason}. Mock Redis ishga tushmoqda...`);
    const RedisMock = require('ioredis-mock');
    redis = new RedisMock();
    isMocked = true;
};

const connectRedis = () => {
    try {
        console.log('🔄 Connecting to Redis...');
        redis = new Redis(config.REDIS_URL, {
            maxRetriesPerRequest: 3,
            lazyConnect: true,
            connectTimeout: 15000,
            retryStrategy: (times) => {
                if (times > 5) {
                    fallbackToMock('Redis ulanishda xatolik (5 urinishdan keyin)');
                    return null;
                }
                return Math.min(times * 200, 3000);
            }
        });

        redis.on('connect', () => {
            console.log('✅ Redis connected successfully');
        });

        redis.on('error', (err) => {
            console.warn('⚠️ Redis error:', err.message);
            if (err.message.includes('ECONNREFUSED') || err.message.includes('ENOTFOUND')) {
                fallbackToMock('Redis local topilmadi');
            }
        });

        // Ulanishni sinab ko'rish
        redis.connect().catch(() => {
            fallbackToMock('Redis connect() muvaffaqiyatsiz');
        });

        return redis;
    } catch (error) {
        console.warn('⚠️ Redis connection failed, using Mock:', error.message);
        fallbackToMock('Redis yaratishda xato');
        return redis;
    }
};

const getRedis = () => {
    if (!redis) {
        redis = connectRedis();
    }
    return redis;
};

module.exports = { connectRedis, getRedis };
