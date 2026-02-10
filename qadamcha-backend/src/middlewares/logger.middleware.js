/**
 * Logger Middleware
 * Request/Response logging uchun middleware
 */

/**
 * Request logger hook
 * Har bir so'rovni log qiladi
 */
function requestLogger(fastify) {
    fastify.addHook('onRequest', async (request, reply) => {
        request.startTime = Date.now();

        // Request ID qo'shish
        request.requestId = request.headers['x-request-id'] || generateRequestId();

        // Log request
        request.log.info({
            requestId: request.requestId,
            method: request.method,
            url: request.url,
            ip: request.ip,
            userAgent: request.headers['user-agent']
        }, 'Incoming request');
    });
}

/**
 * Response logger hook
 * Javoblarni log qiladi
 */
function responseLogger(fastify) {
    fastify.addHook('onResponse', async (request, reply) => {
        const duration = Date.now() - (request.startTime || Date.now());

        request.log.info({
            requestId: request.requestId,
            method: request.method,
            url: request.url,
            statusCode: reply.statusCode,
            duration: `${duration}ms`
        }, 'Request completed');
    });
}

/**
 * Unique request ID generator
 */
function generateRequestId() {
    return `req-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
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
            stack: error.stack
        }, 'Request error');
    });
}

/**
 * Register all logging hooks
 */
function registerLogger(fastify) {
    requestLogger(fastify);
    responseLogger(fastify);
    errorLogger(fastify);

    fastify.log.info('📝 Logger middleware initialized');
}

module.exports = {
    registerLogger,
    requestLogger,
    responseLogger,
    errorLogger,
    generateRequestId
};
