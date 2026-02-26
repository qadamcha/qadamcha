const config = require('../config/env');
const { logger } = require('../config/logger');

let Sentry = null;

/**
 * Sentry ni ishga tushirish
 */
const initSentry = () => {
    if (!config.SENTRY_DSN) {
        logger.warn('SENTRY_DSN not set — error monitoring disabled');
        return;
    }
    try {
        Sentry = require('@sentry/node');
        Sentry.init({
            dsn: config.SENTRY_DSN,
            environment: config.NODE_ENV,
            tracesSampleRate: config.NODE_ENV === 'production' ? 0.1 : 1.0,
            beforeSend(event) {
                // [FIX SEC-7] Sensitive data tozalash — PII himoyasi
                if (event.request && event.request.data) {
                    const data = event.request.data;
                    if (typeof data === 'object') {
                        const sensitiveKeys = [
                            'pin', 'password', 'token', 'refreshToken', 'code',
                            'phone', 'cardNumber', 'name', 'email', 'fcmToken',
                            'verifiedToken', 'newPin', 'familyCode'
                        ];
                        for (const key of sensitiveKeys) {
                            if (data[key]) data[key] = '[FILTERED]';
                        }
                    }
                }
                // IP va User-Agent dan foydalanuvchini aniqlash oldini olish
                if (event.request) {
                    delete event.request.cookies;
                    if (event.request.headers) {
                        delete event.request.headers['authorization'];
                        delete event.request.headers['cookie'];
                    }
                }
                return event;
            },
        });
        logger.info('Sentry initialized');
    } catch (err) {
        logger.warn({ err }, 'Sentry init failed');
    }
};

/**
 * Xatoni Sentry ga yuborish
 */
const captureException = (error, context = {}) => {
    if (!Sentry) return;
    Sentry.withScope((scope) => {
        for (const [key, value] of Object.entries(context)) {
            scope.setExtra(key, value);
        }
        Sentry.captureException(error);
    });
};

/**
 * Fastify error handler uchun Sentry middleware
 */
const sentryErrorHandler = (error, request) => {
    if (!Sentry) return;
    const statusCode = error.statusCode || 500;
    // Faqat 5xx xatolarni yuborish
    if (statusCode >= 500) {
        captureException(error, {
            method: request.method,
            url: request.url,
            userId: request.user?.userId,
            requestId: request.requestId,
        });
    }
};

module.exports = { initSentry, captureException, sentryErrorHandler };
