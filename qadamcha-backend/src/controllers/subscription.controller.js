const { Subscription, User, PaymeTransaction } = require('../models');
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
                _id: subscription._id,
                userId: subscription.userId,
                plan: subscription.plan,
                status: subscription.status,
                startDate: subscription.startDate,
                endDate: subscription.endDate,
                daysRemaining: Math.ceil((subscription.endDate - new Date()) / (1000 * 60 * 60 * 24)),
                maxDevices: subscription.maxDevices,
                autoRenew: subscription.autoRenew,
                paymentMethod: subscription.paymentMethod,
                createdAt: subscription.createdAt
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

    // POST /subscription/create - Yangi obuna yaratish + Payme checkout URL
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

        const orderId = subscription._id.toString();

        // Subscribe API: to'lov /payme/pay endpoint orqali amalga oshiriladi
        return {
            success: true,
            orderId,
            amount: planData.price,
            message: 'To\'lov kutilmoqda'
        };
    },

    // GET /subscription/check/:orderId - To'lov holatini tekshirish
    async checkOrder(request, reply) {
        const { userId } = request.user;
        const { orderId } = request.params;

        const subscription = await Subscription.findById(orderId);

        if (!subscription) {
            return reply.status(404).send({
                success: false,
                message: 'Buyurtma topilmadi'
            });
        }

        if (subscription.userId.toString() !== userId) {
            return reply.status(403).send({
                success: false,
                message: 'Ruxsat yo\'q'
            });
        }

        return {
            success: true,
            status: subscription.status,
            paid: subscription.status === 'active',
            subscription: subscription.status === 'active' ? {
                plan: subscription.plan,
                status: subscription.status,
                startDate: subscription.startDate,
                endDate: subscription.endDate,
                daysRemaining: Math.ceil((subscription.endDate - new Date()) / (1000 * 60 * 60 * 24)),
                maxDevices: subscription.maxDevices
            } : null
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

        // [FIX CRIT-2] PaymeTransaction jadvaldan to'lov muvaffaqiyatini tekshirish
        // Fake transactionId bilan obuna faollashtirishning oldini oladi
        const verifiedTx = await PaymeTransaction.findOne({
            _id: transactionId,
            orderId,
            userId,
            state: 4,  // faqat to'langan
        });
        if (!verifiedTx) {
            return reply.status(400).send({
                success: false,
                message: 'To\'lov tasdiqlanmagan yoki tranzaksiya topilmadi'
            });
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

        // Obunani faollashtirish (Atlas free tier uchun transaction siz)
        try {
            subscription.status = 'active';
            subscription.transactionId = transactionId;
            subscription.paymentMethod = paymentMethod;
            subscription.startDate = new Date();

            const planData = config.PLANS[subscription.plan];
            subscription.endDate = new Date();
            subscription.endDate.setDate(subscription.endDate.getDate() + planData.days);

            await subscription.save();
        } catch (err) {
            request.log.error('Subscription activation failed:', err);
            return reply.status(500).send({
                success: false,
                message: 'Obunani faollashtirishda xatolik yuz berdi'
            });
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
    },

    // POST /subscription/activate-test - Test rejimida obunani faollashtirish
    async activateTest(request, reply) {
        // [FIX CRIT-1] Production da test obunani bloklash
        if (config.NODE_ENV === 'production') {
            return reply.status(403).send({
                success: false,
                message: 'Test rejim faqat development muhitida ishlaydi'
            });
        }

        const { userId } = request.user;

        // Mavjud faol obunani tekshirish
        const existing = await Subscription.getActive(userId);
        if (existing) {
            return {
                success: true,
                message: 'Obuna allaqachon faol',
                subscription: {
                    _id: existing._id,
                    userId: existing.userId,
                    plan: existing.plan,
                    status: existing.status,
                    startDate: existing.startDate,
                    endDate: existing.endDate,
                    autoRenew: existing.autoRenew,
                    paymentMethod: existing.paymentMethod,
                    createdAt: existing.createdAt
                }
            };
        }

        // Yangi obuna yaratish (test rejim — to'lovsiz)
        const planData = config.PLANS['monthly'];
        const endDate = new Date();
        endDate.setDate(endDate.getDate() + planData.days);

        const subscription = await Subscription.create({
            userId,
            plan: 'monthly',
            status: 'active',
            price: planData.price,
            startDate: new Date(),
            endDate,
            paymentMethod: 'trial',
            createdBy: userId
        });

        // User modelini yangilash
        await User.findByIdAndUpdate(userId, {
            subscriptionStatus: 'active',
            subscriptionPlan: 'monthly'
        });

        return {
            success: true,
            message: 'Obuna muvaffaqiyatli faollashtirildi (test rejim)',
            subscription: {
                _id: subscription._id,
                userId: subscription.userId,
                plan: subscription.plan,
                status: subscription.status,
                startDate: subscription.startDate,
                endDate: subscription.endDate,
                autoRenew: subscription.autoRenew,
                paymentMethod: subscription.paymentMethod,
                createdAt: subscription.createdAt
            }
        };
    }
};
