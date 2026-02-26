/**
 * Global Logger Configuration
 * Pino asosida structured logging
 * 
 * Development: pino-pretty (raqamli, rangli)
 * Production: JSON format (log parsing uchun)
 */

const pino = require('pino');
const config = require('./env');

// Sensitive fieldlarni avtomatik maskirovka qilish
const redactPaths = [
    'req.headers.authorization',
    'req.headers.cookie',
    'phone',
    'pin',
    'password',
    'token',
    'refreshToken',
    'cardNumber',
    'code',
    'verifiedToken',
    'fcmToken',
    'familyCode',
    'newPin'
];

const loggerConfig = {
    level: config.NODE_ENV === 'production' ? 'info' : 'debug',
    redact: {
        paths: redactPaths,
        censor: '[FILTERED]'
    },
    serializers: {
        req(request) {
            return {
                method: request.method,
                url: request.url,
                hostname: request.hostname,
                remoteAddress: request.ip,
            };
        },
        res(reply) {
            return {
                statusCode: reply.statusCode,
            };
        }
    },
};

// Development da pino-pretty ishlatish
if (config.NODE_ENV !== 'production') {
    loggerConfig.transport = {
        target: 'pino-pretty',
        options: {
            colorize: true,
            translateTime: 'HH:MM:ss',
            ignore: 'pid,hostname',
        }
    };
}

// Standalone logger — servicelarda ishlatish uchun
const logger = pino(loggerConfig);

module.exports = { loggerConfig, logger };
