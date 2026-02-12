/**
 * Swagger/OpenAPI Plugin
 * API dokumentatsiya uchun
 */

const packageJson = require('../../package.json');

/**
 * Swagger options
 */
const swaggerOptions = {
    openapi: {
        info: {
            title: 'Qadamcha API',
            description: 'Qadamcha - Ota-ona va bola uchun vaqt boshqaruv ilovasi API',
            version: packageJson.version,
            contact: {
                name: 'Qadamcha Team',
                email: 'support@qadamcha.uz'
            }
        },
        servers: [
            {
                url: `http://localhost:${process.env.PORT || 3000}`,
                description: 'Development server'
            },
            {
                url: 'https://api.qadamcha.uz',
                description: 'Production server'
            }
        ],
        tags: [
            { name: 'Auth', description: 'Autentifikatsiya endpointlari' },
            { name: 'Children', description: 'Bolalarni boshqarish' },
            { name: 'Content', description: 'Kontent va video' },
            { name: 'Devices', description: 'Qurilmalar boshqaruvi' },
            { name: 'Subscription', description: 'Obuna boshqaruvi' },
            { name: 'AI', description: 'AI maslahatchi' }
        ],
        components: {
            securitySchemes: {
                bearerAuth: {
                    type: 'http',
                    scheme: 'bearer',
                    bearerFormat: 'JWT'
                }
            }
        }
    }
};

/**
 * Swagger UI options
 */
const swaggerUiOptions = {
    routePrefix: '/docs',
    uiConfig: {
        docExpansion: 'list',
        deepLinking: true,
        defaultModelsExpandDepth: 1,
        displayRequestDuration: true
    },
    staticCSP: true,
    transformStaticCSP: (header) => header,
    uiHooks: {
        onRequest: function (request, reply, next) { next(); },
        preHandler: function (request, reply, next) { next(); }
    }
};

/**
 * Register Swagger plugin
 */
async function registerSwagger(fastify) {
    try {
        const fastifySwagger = require('@fastify/swagger');
        const fastifySwaggerUi = require('@fastify/swagger-ui');

        await fastify.register(fastifySwagger, swaggerOptions);
        await fastify.register(fastifySwaggerUi, swaggerUiOptions);

        fastify.log.info('📚 Swagger documentation available at /docs');
    } catch (error) {
        if (error.code === 'MODULE_NOT_FOUND') {
            fastify.log.warn('⚠️ Swagger not installed. Run: npm install @fastify/swagger @fastify/swagger-ui');
        } else {
            fastify.log.warn('⚠️ Swagger registration failed:', error.message);
        }
    }
}

module.exports = {
    registerSwagger,
    swaggerOptions,
    swaggerUiOptions
};
