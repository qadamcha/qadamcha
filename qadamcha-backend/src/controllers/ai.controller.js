const aiService = require('../services/ai.service');
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

    // GET /ai/tips - Tez maslahatlar
    async getTips(request, reply) {
        const { age } = request.query;

        const parsedAge = parseInt(age);
        if (isNaN(parsedAge) || parsedAge < 1 || parsedAge > 18) {
            return reply.status(400).send({
                success: false,
                message: 'Yosh 1-18 orasida bo\'lishi kerak'
            });
        }

        const tips = aiService.getQuickTips(parsedAge);

        return {
            success: true,
            tips
        };
    },

    // GET /ai/status - AI holati
    async getStatus(request, reply) {
        return {
            success: true,
            ...aiService.getStatus()
        };
    }
};
