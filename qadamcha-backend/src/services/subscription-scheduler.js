/**
 * Subscription Scheduler Service
 * [FIX HIGH-7] Eskirgan obunalarni avtomatik expired ga o'tkazish
 * 
 * Har 1 soatda ishga tushadi va endDate o'tgan active obunalarni expired qiladi.
 */

const { Subscription } = require('../models');
const { logger } = require('../config/logger');

let intervalId = null;
const CHECK_INTERVAL_MS = 60 * 60 * 1000; // 1 soat

/**
 * Eskirgan obunalarni expired ga o'tkazish
 */
async function expireSubscriptions() {
    try {
        const result = await Subscription.updateMany(
            {
                status: 'active',
                endDate: { $lt: new Date() }
            },
            {
                $set: { status: 'expired' }
            }
        );

        if (result.modifiedCount > 0) {
            logger.info(`📋 ${result.modifiedCount} ta obuna expired qilindi`);
        }
    } catch (err) {
        logger.error('❌ Subscription expiry check xatosi:', err.message);
    }
}

/**
 * Scheduler ni ishga tushirish
 */
function start() {
    // Darhol bir marta tekshirish
    expireSubscriptions();

    // Har soatda tekshirish
    intervalId = setInterval(expireSubscriptions, CHECK_INTERVAL_MS);
    logger.info('Subscription expiry scheduler started (every 1 hour)');
}

/**
 * Scheduler ni to'xtatish (graceful shutdown uchun)
 */
function stop() {
    if (intervalId) {
        clearInterval(intervalId);
        intervalId = null;
    }
}

module.exports = { start, stop, expireSubscriptions };
