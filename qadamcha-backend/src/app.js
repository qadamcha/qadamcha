const { loggerConfig } = require('./config/logger');
const fastify = require('fastify')({
    trustProxy: true,
    logger: loggerConfig
});

const config = require('./config/env');
const connectDB = require('./config/database');
const { connectRedis, disconnectRedis } = require('./config/redis');
const { API_PREFIX } = require('./config/constants');

// Sentry — eng tepada init qilish
const { initSentry, sentryErrorHandler } = require('./plugins/sentry.plugin');
initSentry();

// Register Plugins
const registerPlugins = async () => {
    // CORS — production da faqat ruxsat etilgan originlar
    const corsOrigin = (() => {
        if (config.NODE_ENV !== 'production') return true;
        const origins = config.ALLOWED_ORIGINS;
        if (!origins || origins === '*') return true;  // [FIX MED-2] * = barcha originlarga ruxsat
        return origins.split(',').map(o => o.trim());
    })();

    await fastify.register(require('@fastify/cors'), {
        origin: corsOrigin,
        credentials: true
    });

    // [FIX MED-1] Global sanitizeBody middleware — XSS oldini olish
    const { sanitizeBody } = require('./middlewares/validator.middleware');
    fastify.addHook('preHandler', sanitizeBody);

    // Security Headers
    await fastify.register(require('@fastify/helmet'), {
        contentSecurityPolicy: false
    });

    // JWT
    await fastify.register(require('@fastify/jwt'), {
        secret: config.JWT_SECRET,
        sign: { expiresIn: config.JWT_ACCESS_EXPIRES }
    });

    // Rate Limiting — global 100/min
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

// Authentication Middleware — plugins dan keyin register qilinadi (MED-3)

// Register Routes
const registerRoutes = async () => {
    // Monitoring plugin — /health va /metrics endpointlar
    await fastify.register(require('./plugins/monitoring'));

    // Force HTTPS redirect (production)
    const { forceHttpsRedirect } = require('./config/tls');
    forceHttpsRedirect(fastify);

    // API Routes
    fastify.register(require('./routes'), { prefix: API_PREFIX });
};

// Error Handler — Sentry bilan
fastify.setErrorHandler((error, request, reply) => {
    fastify.log.error(error);

    // Sentry ga yuborish
    sentryErrorHandler(error, request);

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
        // [FIX SEC-9] Stack trace faqat STRICT development da qaytariladi
        ...(config.NODE_ENV === 'development' && { stack: error.stack })
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

        // Connect to Redis (await ensures no race condition)
        const redis = await connectRedis();

        // Store Redis in app
        fastify.decorate('redis', redis);

        // Configure services with Redis
        const smsService = require('./services/sms.service');
        smsService.setRedis(redis);
        const blacklistService = require('./services/blacklist.service');
        blacklistService.setRedis(redis);

        const cacheService = require('./services/cache.service');
        cacheService.setRedis(redis);

        // [FIX HIGH-6] OTP Rate Limiter ni Redis bilan ulash
        const otpRateLimiter = require('./services/otp-rate-limiter');
        otpRateLimiter.setRedis(redis);

        // Initialize notification service
        const notificationService = require('./services/notification.service');
        notificationService.init();

        // Register plugins and routes
        await registerPlugins();

        // [FIX MED-3] Auth middleware — JWT plugin dan keyin register qilish
        const { registerAuth } = require('./middlewares/auth.middleware');
        registerAuth(fastify);

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

        // [FIX HIGH-7] Subscription expiry scheduler
        const subscriptionScheduler = require('./services/subscription-scheduler');
        subscriptionScheduler.start();

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
        await disconnectRedis();
        // Scheduler ni to'xtatish
        try {
            const subscriptionScheduler = require('./services/subscription-scheduler');
            subscriptionScheduler.stop();
        } catch { }
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
