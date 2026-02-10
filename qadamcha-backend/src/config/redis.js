const Redis = require('ioredis');
const config = require('./env');

let redis = null;

const connectRedis = () => {
    try {
        console.log('🔄 Connecting to Redis...');
        redis = new Redis(config.REDIS_URL, {
            maxRetriesPerRequest: 3,
            retryStrategy: (times) => {
                if (times > 3) {
                    console.warn('⚠️ Redis ulanishda xatolik. Mock Redis ishlatilmoqda.');
                    return null; // Stop retrying
                }
                return Math.min(times * 50, 2000);
            }
        });

        redis.on('connect', () => {
            console.log('✅ Redis connected successfully');
        });

        redis.on('error', (err) => {
            console.warn('⚠️ Redis error:', err.message);
            // Fallback to mock if not already mocked
            if (err.message.includes('ECONNREFUSED') && !(redis instanceof require('ioredis-mock'))) {
                console.warn('⚠️ Redis local topilmadi. Mock Redis ishga tushmoqda...');
                const RedisMock = require('ioredis-mock');
                redis = new RedisMock();
            }
        });

        return redis;
    } catch (error) {
        console.warn('⚠️ Redis connection failed, using Mock:', error.message);
        const RedisMock = require('ioredis-mock');
        redis = new RedisMock();
        return redis;
    }
};

const getRedis = () => {
    if (!redis) {
        redis = connectRedis();
    }
    return redis;
};

module.exports = { connectRedis, getRedis, instance: getRedis() };
