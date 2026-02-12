const mongoose = require('mongoose');
const { Subscription, User } = require('../models');
const config = require('../config/env');
const { ERRORS, SUCCESS } = require('../config/constants');

module.exports = {

    // GET /subscription - Joriy obuna
    async getCurrent(request, reply) {
        const { userId } = request.user;

        const subscription = await Subscription.getActive(userId);

        if (!subscription) {
            return {
                success: true,
                hasSubscription: false,
                message: 'Obuna mavjud emas'
            };
        }

        return {
            success: true,
            hasSubscription: true,
            subscription: {
                plan: subscription.plan,
                status: subscription.status,
                startDate: subscription.startDate,
                endDate: subscription.endDate,
                daysRemaining: Math.ceil((subscription.endDate - new Date()) / (1000 * 60 * 60 * 24)),
                maxDevices: subscription.maxDevices
            }
        };
    },

    // GET /subscription/plans - Mavjud planlar
    async getPlans(request, reply) {
        const plans = Object.entries(config.PLANS).map(([key, plan]) => ({
            id: key,
            name: plan.name,
            price: plan.price,
            days: plan.days,
            priceFormatted: `${plan.price.toLocaleString()} so'm`,
            features: [
                '3 ta qurilma',
                'Barcha kontentlar',
                'AI maslahatchi',
                'Vaqt boshqaruvi'
            ]
        }));

        return { success: true, plans };
    },

    // POST /subscription/create - Yangi obuna yaratish (to'lov oldidan)
    async create(request, reply) {
        const { userId } = request.user;
        const { plan } = request.body;

        if (!config.PLANS[plan]) {
            return reply.status(400).send({
                success: false,
                message: 'Noto\'g\'ri plan'
            });
        }

        const planData = config.PLANS[plan];
        const endDate = new Date();
        endDate.setDate(endDate.getDate() + planData.days);

        // Pending obuna yaratish
        const subscription = await Subscription.create({
            userId,
            plan,
            status: 'pending',
            price: planData.price,
            endDate,
            createdBy: userId
        });

        return {
            success: true,
            subscription,
            orderId: subscription._id.toString(),
            amount: planData.price,
            message: 'To\'lov kutilmoqda'
        };
    },

    // POST /subscription/activate - Obunani faollashtirish (to'lovdan keyin)
    async activate(request, reply) {
        const { userId } = request.user;
        const { orderId, transactionId, paymentMethod } = request.body;

        const subscription = await Subscription.findById(orderId);

        if (!subscription) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        // Ownership tekshiruvi
        if (subscription.userId.toString() !== userId) {
            return reply.status(403).send({
                success: false,
                message: ERRORS.FORBIDDEN
            });
        }

        if (subscription.status === 'active') {
            return {
                success: true,
                message: 'Obuna allaqachon faol'
            };
        }

        // transactionId takroriy ishlatilmaganini tekshirish
        const existingTx = await Subscription.findOne({
            transactionId,
            status: 'active'
        });
        if (existingTx) {
            return reply.status(400).send({
                success: false,
                message: 'Bu to\'lov allaqachon ishlatilgan'
            });
        }

        // Obunani faollashtirish — transaction bilan (to'lov + obuna atomik)
        const session = await mongoose.startSession();
        session.startTransaction();

        try {
            subscription.status = 'active';
            subscription.transactionId = transactionId;
            subscription.paymentMethod = paymentMethod;
            subscription.startDate = new Date();

            const planData = config.PLANS[subscription.plan];
            subscription.endDate = new Date();
            subscription.endDate.setDate(subscription.endDate.getDate() + planData.days);

            await subscription.save({ session });
            await session.commitTransaction();
        } catch (err) {
            await session.abortTransaction();
            request.log.error('Subscription activation failed:', err);
            return reply.status(500).send({
                success: false,
                message: 'Obunani faollashtirishda xatolik yuz berdi'
            });
        } finally {
            session.endSession();
        }

        return {
            success: true,
            message: 'Obuna faollashtirildi',
            subscription
        };
    },

    // POST /subscription/cancel - Obunani bekor qilish
    async cancel(request, reply) {
        const { userId } = request.user;
        const { reason } = request.body;

        const subscription = await Subscription.findOne({
            userId,
            status: 'active'
        });

        if (!subscription) {
            return reply.status(404).send({
                success: false,
                message: 'Faol obuna topilmadi'
            });
        }

        subscription.status = 'cancelled';
        subscription.cancelledAt = new Date();
        subscription.cancelReason = reason;
        subscription.autoRenew = false;
        await subscription.save();

        return {
            success: true,
            message: 'Obuna bekor qilindi. Muddat tugagunga qadar foydalanishingiz mumkin.'
        };
    },

    // GET /subscription/history - Obuna tarixi
    async getHistory(request, reply) {
        const { userId } = request.user;

        const subscriptions = await Subscription.find({ userId })
            .sort({ createdAt: -1 })
            .limit(10);

        return { success: true, subscriptions };
    }
};
