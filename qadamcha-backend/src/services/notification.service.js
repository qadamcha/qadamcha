const config = require('../config/env');
const { Device } = require('../models');
const { logger } = require('../config/logger');

let admin = null;
let initialized = false;

/**
 * Firebase Admin SDK ni ishga tushirish
 */
const init = () => {
    if (initialized) return;
    if (!config.FIREBASE_SERVICE_ACCOUNT) {
        logger.warn('FIREBASE_SERVICE_ACCOUNT not set — push notifications disabled');
        return;
    }
    try {
        const firebaseAdmin = require('firebase-admin');
        const serviceAccount = JSON.parse(
            Buffer.from(config.FIREBASE_SERVICE_ACCOUNT, 'base64').toString('utf-8')
        );
        firebaseAdmin.initializeApp({
            credential: firebaseAdmin.credential.cert(serviceAccount),
        });
        admin = firebaseAdmin;
        initialized = true;
        logger.info('Firebase Admin initialized');
    } catch (err) {
        logger.warn({ err }, 'Firebase init failed');
    }
};

/**
 * Bitta qurilmaga notification yuborish
 */
const sendToDevice = async (fcmToken, title, body, data = {}) => {
    if (!admin || !fcmToken) return null;
    try {
        return await admin.messaging().send({
            token: fcmToken,
            notification: { title, body },
            data,
        });
    } catch (err) {
        // Token yaroqsiz bo'lsa — tozalash
        if (err.code === 'messaging/registration-token-not-registered') {
            await Device.updateOne({ fcmToken }, { $unset: { fcmToken: '' } });
        }
        return null;
    }
};

/**
 * User ning barcha qurilmalariga notification yuborish
 */
const sendToUser = async (userId, title, body, data = {}) => {
    if (!admin) return;
    const devices = await Device.find({
        userId,
        isActive: true,
        fcmToken: { $exists: true, $ne: null },
    });

    const results = await Promise.allSettled(
        devices.map(d => sendToDevice(d.fcmToken, title, body, data))
    );
    return results;
};

/**
 * Vaqt limiti 80% ga yetganda ogohlantirish
 */
const notifyTimeLimitApproaching = async (userId, childName, percentUsed) => {
    await sendToUser(
        userId,
        'Vaqt limiti tugayapti',
        `${childName} bugungi vaqtning ${percentUsed}% ini ishlatdi`,
        { type: 'time_limit', percentUsed: String(percentUsed) }
    );
};

/**
 * Yangi kontent haqida xabar
 */
const notifyNewContent = async (userId, contentTitle) => {
    await sendToUser(
        userId,
        'Yangi kontent!',
        `"${contentTitle}" qo'shildi`,
        { type: 'new_content' }
    );
};

module.exports = {
    init,
    sendToDevice,
    sendToUser,
    notifyTimeLimitApproaching,
    notifyNewContent,
};
