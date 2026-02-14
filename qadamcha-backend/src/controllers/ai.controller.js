const aiService = require('../services/ai.service');
const cacheService = require('../services/cache.service');
const { Child } = require('../models');
const { ERRORS } = require('../config/constants');

module.exports = {

    // POST /ai/chat - AI bilan suhbat
    async chat(request, reply) {
        const { userId } = request.user;
        const { message, childId } = request.body;

        if (!message || message.trim().length < 3) {
            return reply.status(400).send({
                success: false,
                message: 'Savol juda qisqa'
            });
        }

        // Bola konteksti
        let context = {};
        if (childId) {
            const child = await Child.findOne({
                _id: childId,
                parentId: userId,
                isActive: true
            });

            if (child) {
                context = {
                    childName: child.name,
                    childAge: child.age,
                    childGender: child.gender
                };
            }
        }

        const result = await aiService.chat(message, context);

        return result;
    },

    // GET /ai/tips - Tez maslahatlar — cached
    async getTips(request, reply) {
        const { age } = request.query;

        const parsedAge = parseInt(age);
        if (isNaN(parsedAge) || parsedAge < 1 || parsedAge > 18) {
            return reply.status(400).send({
                success: false,
                message: 'Yosh 1-18 orasida bo\'lishi kerak'
            });
        }

        // Cache tekshirish
        const cacheKey = `ai:tips:${parsedAge}`;
        const cached = await cacheService.get(cacheKey);
        if (cached) return cached;

        const tips = aiService.getQuickTips(parsedAge);

        const result = {
            success: true,
            tips
        };

        await cacheService.set(cacheKey, result, cacheService.TTL.AI_TIPS);
        return result;
    },

    // GET /ai/status - AI holati
    async getStatus(request, reply) {
        return {
            success: true,
            ...aiService.getStatus()
        };
    }
};
