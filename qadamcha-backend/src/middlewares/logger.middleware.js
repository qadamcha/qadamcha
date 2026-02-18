/**
 * Logger Middleware
 * Request/Response logging with body sanitization, log levels, response time
 */

const SENSITIVE_KEYS = ['pin', 'password', 'token', 'refreshToken', 'code', 'secret', 'cardNumber', 'expire'];

/**
 * Body dan sensitive data larni tozalash (rekursiv — nested objectlar uchun ham)
 */
function sanitizeBody(body) {
    if (!body || typeof body !== 'object') return body;
    if (Array.isArray(body)) return body.map(item => sanitizeBody(item));
    const sanitized = { ...body };
    for (const key of Object.keys(sanitized)) {
        if (SENSITIVE_KEYS.includes(key)) {
            sanitized[key] = '***';
        } else if (typeof sanitized[key] === 'object' && sanitized[key] !== null) {
            sanitized[key] = sanitizeBody(sanitized[key]);
        }
    }
    return sanitized;
}

/**
 * Status code ga qarab log level tanlash
 */
function getLogLevel(statusCode) {
    if (statusCode >= 500) return 'error';
    if (statusCode >= 400) return 'warn';
    return 'info';
}

/**
 * Unique request ID generator
 */
function generateRequestId() {
    return `req-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
}

/**
 * Request logger hook
 */
function requestLogger(fastify) {
    fastify.addHook('onRequest', async (request, reply) => {
        request.startTime = Date.now();

        // Correlation ID — client yoki server tomonidan
        request.requestId = request.headers['x-request-id'] || generateRequestId();
        reply.header('x-request-id', request.requestId);

        request.log.info({
            requestId: request.requestId,
            method: request.method,
            url: request.url,
            ip: request.ip,
            userAgent: request.headers['user-agent'],
        }, 'Incoming request');
    });
}

/**
 * Body logging hook (onRequest dan keyin, body parse bo'lgandan keyin)
 */
function bodyLogger(fastify) {
    fastify.addHook('preHandler', async (request) => {
        if (request.body && Object.keys(request.body).length > 0) {
            request.log.debug({
                requestId: request.requestId,
                body: sanitizeBody(request.body),
            }, 'Request body');
        }
    });
}

/**
 * Response logger hook — log level va slow query alert bilan
 */
function responseLogger(fastify) {
    fastify.addHook('onResponse', async (request, reply) => {
        const duration = Date.now() - (request.startTime || Date.now());
        const statusCode = reply.statusCode;
        const level = getLogLevel(statusCode);

        const logData = {
            requestId: request.requestId,
            method: request.method,
            url: request.url,
            statusCode,
            duration: `${duration}ms`,
            userId: request.user?.userId || null,
        };

        // Slow query alert (>1s)
        if (duration > 1000) {
            logData.slow = true;
            request.log.warn(logData, `SLOW REQUEST: ${duration}ms`);
        } else {
            request.log[level](logData, 'Request completed');
        }
    });
}

/**
 * Error logger hook
 */
function errorLogger(fastify) {
    fastify.addHook('onError', async (request, reply, error) => {
        request.log.error({
            requestId: request.requestId,
            method: request.method,
            url: request.url,
            error: error.message,
            stack: error.stack,
            userId: request.user?.userId || null,
        }, 'Request error');
    });
}

/**
 * Register all logging hooks
 */
function registerLogger(fastify) {
    requestLogger(fastify);
    bodyLogger(fastify);
    responseLogger(fastify);
    errorLogger(fastify);

    fastify.log.info('Logger middleware initialized');
}

module.exports = {
    registerLogger,
    requestLogger,
    responseLogger,
    errorLogger,
    generateRequestId,
    sanitizeBody,
};
