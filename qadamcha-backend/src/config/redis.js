const Redis = require('ioredis');
const config = require('./env');
const { logger } = require('./logger');

let redis = null;
let isMocked = false;

const fallbackToMock = (reason) => {
    if (isMocked) return;

    // Production da mock bilan davom etish (crash qilmaslik — healthcheck ishlashi kerak)
    if (config.NODE_ENV === 'production') {
        logger.error(`CRITICAL: ${reason}. Redis ishlamayapti, mock ishlatilmoqda!`);
    }

    logger.warn(`${reason}. Mock Redis ishga tushmoqda...`);
    try {
        const RedisMock = require('ioredis-mock');
        redis = new RedisMock();
    } catch {
        // ioredis-mock production da yo'q — oddiy mock yaratamiz
        const noOp = () => Promise.resolve(null);
        redis = {
            get: noOp, set: noOp, del: noOp, setex: noOp,
            incr: () => Promise.resolve(1), expire: noOp,
            ping: () => Promise.resolve('PONG'),
            on: () => { }, quit: noOp,
        };
    }
    isMocked = true;
};

const connectRedis = async () => {
    try {
        logger.info('Connecting to Redis...');
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

        redis.on('error', (err) => {
            logger.warn(`Redis error: ${err.message}`);
            if (err.message.includes('ECONNREFUSED') || err.message.includes('ENOTFOUND')) {
                fallbackToMock('Redis local topilmadi');
            }
        });

        // Ulanishni kutish (race condition oldini olish)
        try {
            await redis.connect();
            logger.info('Redis connected successfully');
        } catch (err) {
            fallbackToMock('Redis connect() muvaffaqiyatsiz');
        }

        return redis;
    } catch (error) {
        logger.warn(`Redis connection failed, using Mock: ${error.message}`);
        fallbackToMock('Redis yaratishda xato');
        return redis;
    }
};

const getRedis = () => {
    return redis;
};

const disconnectRedis = async () => {
    if (redis && !isMocked) {
        try {
            await redis.quit();
            logger.info('Redis disconnected');
        } catch {
            // Ignore disconnect errors
        }
    }
};

module.exports = { connectRedis, getRedis, disconnectRedis };
