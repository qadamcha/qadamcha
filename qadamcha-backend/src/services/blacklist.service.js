const { REDIS_KEYS } = require('../config/constants');

let redis = null;

const setRedis = (redisClient) => {
    redis = redisClient;
};

/**
 * Token JTI ni blacklist ga qo'shish
 * @param {string} jti - JWT Token ID
 * @param {number} ttl - Seconds until token expires naturally
 */
const add = async (jti, ttl) => {
    if (!redis || !jti) return;
    const key = `${REDIS_KEYS.BLACKLIST}${jti}`;
    await redis.setex(key, ttl, '1');
};

/**
 * Token blacklist da bormi tekshirish
 * @param {string} jti - JWT Token ID
 * @returns {boolean}
 */
const isBlacklisted = async (jti) => {
    if (!redis || !jti) return false;
    const key = `${REDIS_KEYS.BLACKLIST}${jti}`;
    const result = await redis.get(key);
    return result !== null;
};

module.exports = { setRedis, add, isBlacklisted };
