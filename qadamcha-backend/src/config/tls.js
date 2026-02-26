/**
 * TLS/HTTPS Konfiguratsiya
 * 
 * HTTPS ni Fastify serverda yoqish uchun.
 * Railway/Render kabi platformalarda HTTPS avtomatik sozlanadi,
 * bu konfiguratsiya faqat VPS/self-hosted deploymentlar uchun.
 */

const fs = require('fs');
const path = require('path');
const config = require('./env');
const { logger } = require('./logger');

/**
 * TLS sertifikatlarni yuklash
 * Agar SSL_CERT_PATH va SSL_KEY_PATH o'rnatilgan bo'lsa
 */
function getTlsOptions() {
    const certPath = process.env.SSL_CERT_PATH;
    const keyPath = process.env.SSL_KEY_PATH;

    if (!certPath || !keyPath) {
        return null;
    }

    try {
        const cert = fs.readFileSync(path.resolve(certPath));
        const key = fs.readFileSync(path.resolve(keyPath));
        logger.info('TLS sertifikatlar yuklandi');
        return { cert, key };
    } catch (err) {
        logger.error({ err }, 'TLS sertifikatlarni yuklashda xato');
        return null;
    }
}

/**
 * Force HTTPS redirect middleware
 * Production da HTTP so'rovlarni HTTPS ga yo'naltirish
 */
function forceHttpsRedirect(fastify) {
    if (config.NODE_ENV !== 'production') return;

    fastify.addHook('onRequest', async (request, reply) => {
        // Platform headerlarni tekshirish (Railway, Heroku, etc.)
        const proto = request.headers['x-forwarded-proto'];
        if (proto && proto !== 'https') {
            const host = request.headers.host || request.hostname;
            const url = `https://${host}${request.url}`;
            return reply.redirect(301, url);
        }
    });

    logger.info('Force HTTPS redirect enabled (production)');
}

module.exports = { getTlsOptions, forceHttpsRedirect };
