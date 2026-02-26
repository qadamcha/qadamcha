const aiService = require('../services/ai.service');
const cacheService = require('../services/cache.service');
const { Child } = require('../models');
const { ERRORS } = require('../config/constants');

module.exports = {

    // POST /ai/chat - AI bilan suhbat (tarix bilan)
    async chat(request, reply) {
        const { userId } = request.user;
        let { message, childId, history } = request.body;

        if (!message || message.trim().length < 3) {
            return reply.status(400).send({
                success: false,
                message: 'Xabar kamida 3 ta belgi bo\'lishi kerak'
            });
        }

        // [FIX MED-5] Xabar uzunligini cheklash — API xarajatlarini nazorat qilish
        if (message.length > 2000) {
            return reply.status(400).send({
                success: false,
                message: 'Xabar 2000 ta belgidan oshmasligi kerak'
            });
        }

        // [FIX MED-5] Tarix massivi uzunligini cheklash
        if (history && Array.isArray(history) && history.length > 20) {
            history = history.slice(-20);
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

        // History array ni validatsiya qilish
        const validHistory = Array.isArray(history) ? history.filter(
            h => h && typeof h.role === 'string' && typeof h.text === 'string'
                && ['user', 'model'].includes(h.role)
                && h.text.length > 0
        ) : [];

        const result = await aiService.chat(message, validHistory, context);

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
