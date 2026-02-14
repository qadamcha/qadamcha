/**
 * Auth Middleware
 * JWT tekshirish va token blacklist boshqaruvi
 */

const blacklistService = require('../services/blacklist.service');

/**
 * Fastify ga authenticate decorator qo'shish
 * @param {import('fastify').FastifyInstance} fastify
 */
function registerAuth(fastify) {
    fastify.decorate('authenticate', async (request, reply) => {
        try {
            await request.jwtVerify();

            // Token blacklist da bormi tekshirish
            if (request.user.jti) {
                const isBlacklisted = await blacklistService.isBlacklisted(request.user.jti);
                if (isBlacklisted) {
                    return reply.status(401).send({
                        success: false,
                        message: 'Token bekor qilingan'
                    });
                }
            }
        } catch (err) {
            return reply.status(401).send({
                success: false,
                message: 'Autentifikatsiya talab qilinadi'
            });
        }
    });

    // Faqat parent role uchun middleware
    fastify.decorate('requireParent', async (request, reply) => {
        if (request.user.role !== 'parent') {
            return reply.status(403).send({
                success: false,
                message: 'Faqat ota-onalar uchun'
            });
        }
    });

    // Obuna tekshirish middleware
    fastify.decorate('requireSubscription', async (request, reply) => {
        try {
            const { Subscription } = require('../models');
            const subscription = await Subscription.getActive(request.user.userId);

            if (!subscription) {
                return reply.status(403).send({
                    success: false,
                    message: 'Obuna talab qilinadi'
                });
            }

            request.subscription = subscription;
        } catch (err) {
            return reply.status(500).send({
                success: false,
                message: 'Obuna tekshirishda xatolik'
            });
        }
    });
}

module.exports = { registerAuth };
