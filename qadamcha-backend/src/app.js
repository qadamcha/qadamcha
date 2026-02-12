const fastify = require('fastify')({
    trustProxy: true,
    logger: {
        level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
        transport: process.env.NODE_ENV !== 'production' ? {
            target: 'pino-pretty',
            options: { colorize: true }
        } : undefined
    }
});

const config = require('./config/env');
const connectDB = require('./config/database');
const { connectRedis } = require('./config/redis');
const { API_PREFIX } = require('./config/constants');

// Register Plugins
const registerPlugins = async () => {
    // CORS
    await fastify.register(require('@fastify/cors'), {
        origin: config.NODE_ENV === 'production'
            ? (config.ALLOWED_ORIGINS === '*' ? true : (config.ALLOWED_ORIGINS ? config.ALLOWED_ORIGINS.split(',') : false))
            : true,
        credentials: true
    });

    // Security Headers
    await fastify.register(require('@fastify/helmet'), {
        contentSecurityPolicy: false
    });

    // JWT
    await fastify.register(require('@fastify/jwt'), {
        secret: config.JWT_SECRET,
        sign: { expiresIn: config.JWT_ACCESS_EXPIRES }
    });

    // Rate Limiting
    await fastify.register(require('@fastify/rate-limit'), {
        max: 100,
        timeWindow: '1 minute',
        errorResponseBuilder: (req, context) => ({
            success: false,
            message: 'Juda ko\'p so\'rovlar. Keyinroq urinib ko\'ring.',
            retryAfter: context.after
        })
    });
};

// Authentication Decorator
fastify.decorate('authenticate', async (request, reply) => {
    try {
        await request.jwtVerify();
    } catch (err) {
        return reply.status(401).send({
            success: false,
            message: 'Autentifikatsiya talab qilinadi'
        });
    }
});

// Register Routes
const registerRoutes = async () => {
    // Enhanced Health Check
    fastify.get('/health', async (request, reply) => {
        const startTime = Date.now();

        // Check MongoDB
        let mongoStatus = 'unknown';
        try {
            const mongoose = require('mongoose');
            if (mongoose.connection.readyState === 1) {
                mongoStatus = 'connected';
            } else {
                mongoStatus = 'disconnected';
            }
        } catch (e) {
            mongoStatus = 'error';
        }

        // Check Redis
        let redisStatus = 'unknown';
        try {
            if (fastify.redis) {
                await fastify.redis.ping();
                redisStatus = 'connected';
            }
        } catch (e) {
            redisStatus = 'mock'; // Using mock Redis
        }

        // AI Service status
        let aiStatus = 'unknown';
        try {
            const aiService = require('./services/ai.service');
            aiStatus = aiService.isConfigured ? 'configured' : 'not_configured';
        } catch (e) {
            aiStatus = 'error';
        }

        const responseTime = Date.now() - startTime;

        return {
            success: true,
            status: 'ok',
            timestamp: new Date().toISOString(),
            version: require('../package.json').version,
            environment: config.NODE_ENV,
            uptime: process.uptime(),
            responseTime: `${responseTime}ms`,
            services: {
                mongodb: mongoStatus,
                redis: redisStatus,
                ai: aiStatus
            },
            memory: {
                used: `${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)}MB`,
                total: `${Math.round(process.memoryUsage().heapTotal / 1024 / 1024)}MB`
            }
        };
    });

    // API Routes
    fastify.register(require('./routes'), { prefix: API_PREFIX });
};

// Error Handler
// Error Handler
fastify.setErrorHandler((error, request, reply) => {
    fastify.log.error(error);

    // Rate Limit handling
    if (error.statusCode === 429 || error.message?.includes('Juda ko\'p so\'rovlar')) {
        return reply.status(429).send({
            success: false,
            message: 'Juda ko\'p so\'rovlar. Keyinroq urinib ko\'ring.',
            retryAfter: error.retryAfter || 60
        });
    }

    const statusCode = error.statusCode || 500;
    const message = statusCode < 500 ? error.message : 'Ichki server xatosi';

    reply.status(statusCode).send({
        success: false,
        message,
        ...(config.NODE_ENV !== 'production' && { stack: error.stack })
    });
});

// Start Server
const start = async () => {
    try {
        // Validate security in production
        if (typeof config.validateSecurity === 'function') {
            config.validateSecurity();
        }

        // Connect to databases
        await connectDB();

        // Get Redis instance (already connected or mocked)
        const { getRedis } = require('./config/redis');
        const redis = getRedis();

        // Store Redis in app
        fastify.decorate('redis', redis);

        // Configure services with Redis
        const smsService = require('./services/sms.service');
        smsService.setRedis(redis);

        // Register plugins and routes
        await registerPlugins();

        // Register Logger Middleware
        const { registerLogger } = require('./middlewares');
        registerLogger(fastify);

        // Register Swagger (optional)
        try {
            const { registerSwagger } = require('./plugins');
            await registerSwagger(fastify);
        } catch (e) {
            fastify.log.warn('Swagger not registered:', e.message);
        }

        await registerRoutes();

        // Start listening
        await fastify.listen({
            port: config.PORT,
            host: '0.0.0.0'
        });

        const publicUrl = config.PUBLIC_URL;
        console.log(`\n🚀 Qadamcha Backend running on port ${config.PORT}`);
        console.log(`📝 Environment: ${config.NODE_ENV}`);
        console.log(`🔗 Health Check: ${publicUrl}/health`);
        console.log(`📚 API Docs: ${publicUrl}/docs\n`);

    } catch (err) {
        fastify.log.error(err);
        process.exit(1);
    }
};

// Graceful Shutdown
const gracefulShutdown = async (signal) => {
    console.log(`\n${signal} signal received. Shutting down gracefully...`);

    try {
        await fastify.close();
        console.log('✅ Server closed');
        process.exit(0);
    } catch (err) {
        console.error('❌ Error during shutdown:', err);
        process.exit(1);
    }
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Run
start();
