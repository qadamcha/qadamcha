const config = require('../config/env');

let Sentry = null;

/**
 * Sentry ni ishga tushirish
 */
const initSentry = () => {
    if (!config.SENTRY_DSN) {
        console.warn('⚠️ SENTRY_DSN not set — error monitoring disabled');
        return;
    }
    try {
        Sentry = require('@sentry/node');
        Sentry.init({
            dsn: config.SENTRY_DSN,
            environment: config.NODE_ENV,
            tracesSampleRate: config.NODE_ENV === 'production' ? 0.1 : 1.0,
            beforeSend(event) {
                // Sensitive data tozalash
                if (event.request && event.request.data) {
                    const data = event.request.data;
                    if (typeof data === 'object') {
                        for (const key of ['pin', 'password', 'token', 'refreshToken', 'code']) {
                            if (data[key]) data[key] = '***';
                        }
                    }
                }
                return event;
            },
        });
        console.log('✅ Sentry initialized');
    } catch (err) {
        console.warn('⚠️ Sentry init failed:', err.message);
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
