const { REDIS_KEYS } = require('../config/constants');

let redis = null;

const TTL = {
    CONTENT_LIST: 5 * 60,       // 5 min
    FEATURED: 10 * 60,          // 10 min
    CATEGORIES: 30 * 60,        // 30 min
    AI_TIPS: 60 * 60,           // 1 soat
};

const setRedis = (redisClient) => {
    redis = redisClient;
};

/**
 * Cache dan olish
 * @param {string} key
 * @returns {any|null}
 */
const get = async (key) => {
    if (!redis) return null;
    try {
        const data = await redis.get(`${REDIS_KEYS.CACHE}${key}`);
        return data ? JSON.parse(data) : null;
    } catch {
        return null;
    }
};

/**
 * Cache ga yozish
 * @param {string} key
 * @param {any} value
 * @param {number} ttl - sekundlarda
 */
const set = async (key, value, ttl) => {
    if (!redis) return;
    try {
        await redis.setex(`${REDIS_KEYS.CACHE}${key}`, ttl, JSON.stringify(value));
    } catch {
        // Cache yozish xatosi — davom etamiz
    }
};

/**
 * Pattern bo'yicha cache ni tozalash
 * @param {string} pattern - masalan 'content:*'
 */
const invalidate = async (pattern) => {
    if (!redis) return;
    try {
        const keys = await redis.keys(`${REDIS_KEYS.CACHE}${pattern}`);
        if (keys.length > 0) {
            await redis.del(...keys);
        }
    } catch {
        // Cache invalidation xatosi — davom etamiz
    }
};

module.exports = { setRedis, get, set, invalidate, TTL };
