/**
 * Test Server Helper
 * Fastify test serverni yaratish uchun
 */

const fastify = require('fastify');
const RedisMock = require('ioredis-mock');

/**
 * Test uchun Fastify server yaratish
 */
async function buildTestServer() {
    const app = fastify({
        logger: false // Test uchun loglarni o'chirish
    });

    // Mock Redis
    const redis = new RedisMock();
    app.decorate('redis', redis);

    // JWT Plugin
    await app.register(require('@fastify/jwt'), {
        secret: 'test-secret-key-for-testing-only'
    });

    // Authentication decorator
    app.decorate('authenticate', async (request, reply) => {
        try {
            await request.jwtVerify();
        } catch (err) {
            reply.status(401).send({
                success: false,
                message: 'Autentifikatsiya talab qilinadi'
            });
        }
    });

    return app;
}

/**
 * Test server'ni yopish
 */
async function closeTestServer(app) {
    await app.close();
}

/**
 * Mock user token yaratish
 */
function createTestToken(app, payload = {}) {
    return app.jwt.sign({
        userId: payload.userId || 'test-user-id',
        role: payload.role || 'parent',
        deviceId: payload.deviceId || 'test-device-id',
        ...payload
    });
}

module.exports = {
    buildTestServer,
    closeTestServer,
    createTestToken
};
