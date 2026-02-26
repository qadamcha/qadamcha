/**
 * Monitoring Plugin
 * Kengaytirilgan health check va metrics
 */

const { logger } = require('../config/logger');

// Request metrics — in-memory counters
const metrics = {
    totalRequests: 0,
    totalErrors: 0,
    statusCodes: {},
    avgResponseTime: 0,
    _responseTimes: [],
    startedAt: new Date().toISOString(),
};

async function monitoringPlugin(fastify) {
    // Request tracking middleware
    fastify.addHook('onRequest', async (request) => {
        request._startTime = process.hrtime.bigint();
        metrics.totalRequests++;
    });

    fastify.addHook('onResponse', async (request, reply) => {
        const duration = Number(process.hrtime.bigint() - request._startTime) / 1e6; // ms
        const code = reply.statusCode.toString();

        // Status code counter
        metrics.statusCodes[code] = (metrics.statusCodes[code] || 0) + 1;

        // Error counter
        if (reply.statusCode >= 400) metrics.totalErrors++;

        // Rolling average response time (last 1000)
        metrics._responseTimes.push(duration);
        if (metrics._responseTimes.length > 1000) metrics._responseTimes.shift();
        metrics.avgResponseTime = Math.round(
            metrics._responseTimes.reduce((a, b) => a + b, 0) / metrics._responseTimes.length
        );
    });

    // GET /health — Kengaytirilgan health check
    fastify.get('/health', async () => {
        const startTime = Date.now();

        // MongoDB holati
        let mongoStatus = 'unknown';
        let mongoLatency = null;
        try {
            const mongoose = require('mongoose');
            if (mongoose.connection.readyState === 1) {
                const pingStart = Date.now();
                await mongoose.connection.db.admin().ping();
                mongoLatency = Date.now() - pingStart;
                mongoStatus = 'connected';
            } else {
                mongoStatus = 'disconnected';
            }
        } catch { mongoStatus = 'error'; }

        // Redis holati
        let redisStatus = 'unknown';
        let redisLatency = null;
        try {
            if (fastify.redis) {
                const pingStart = Date.now();
                await fastify.redis.ping();
                redisLatency = Date.now() - pingStart;
                redisStatus = 'connected';
            }
        } catch { redisStatus = 'error'; }

        // AI holati
        let aiStatus = 'unknown';
        try {
            const aiService = require('../services/ai.service');
            aiStatus = aiService.isConfigured ? 'configured' : 'not_configured';
        } catch { aiStatus = 'error'; }

        const responseTime = Date.now() - startTime;
        const mem = process.memoryUsage();

        return {
            success: true,
            status: mongoStatus === 'connected' && redisStatus === 'connected' ? 'healthy' : 'degraded',
            timestamp: new Date().toISOString(),
            version: require('../../package.json').version,
            environment: process.env.NODE_ENV || 'development',
            uptime: `${Math.floor(process.uptime())}s`,
            responseTime: `${responseTime}ms`,
            services: {
                mongodb: { status: mongoStatus, latency: mongoLatency ? `${mongoLatency}ms` : null },
                redis: { status: redisStatus, latency: redisLatency ? `${redisLatency}ms` : null },
                ai: { status: aiStatus },
            },
            memory: {
                heapUsed: `${Math.round(mem.heapUsed / 1024 / 1024)}MB`,
                heapTotal: `${Math.round(mem.heapTotal / 1024 / 1024)}MB`,
                rss: `${Math.round(mem.rss / 1024 / 1024)}MB`,
                external: `${Math.round(mem.external / 1024 / 1024)}MB`,
            },
            node: process.version,
        };
    });

    // GET /metrics — Request metrics
    fastify.get('/metrics', async () => {
        return {
            success: true,
            startedAt: metrics.startedAt,
            uptime: `${Math.floor(process.uptime())}s`,
            requests: {
                total: metrics.totalRequests,
                errors: metrics.totalErrors,
                errorRate: metrics.totalRequests > 0
                    ? `${((metrics.totalErrors / metrics.totalRequests) * 100).toFixed(2)}%`
                    : '0%',
                avgResponseTime: `${metrics.avgResponseTime}ms`,
            },
            statusCodes: metrics.statusCodes,
            memory: {
                heapUsed: `${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)}MB`,
                rss: `${Math.round(process.memoryUsage().rss / 1024 / 1024)}MB`,
            },
        };
    });

    logger.info('Monitoring plugin registered (/health, /metrics)');
}

module.exports = monitoringPlugin;
