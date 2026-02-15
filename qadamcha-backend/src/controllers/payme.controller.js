/**
 * Payme Subscribe API Controller
 * 
 * Foydalanuvchi ilovadan karta kiritadi → backend Payme API ga so'rov yuboradi.
 * Eski Merchant API webhook o'rniga REST endpointlar.
 */

const paymeService = require('../services/payme.service');
const { PaymeTransaction, Subscription } = require('../models');
const config = require('../config/env');

// ============= CARD ENDPOINTS =============

/**
 * POST /payme/card/create
 * Karta tokenini yaratish
 */
async function createCard(request, reply) {
    const { cardNumber, expire } = request.body;

    try {
        const result = await paymeService.createCardToken(cardNumber, expire);

        return {
            success: true,
            token: result.token,
            card: result.card,
        };
    } catch (err) {
        request.log.error('Payme cards.create xatosi:', err);
        return reply.status(400).send({
            success: false,
            message: err.message || 'Karta tokenini yaratishda xatolik',
            code: err.code,
        });
    }
}

/**
 * POST /payme/card/verify-code
 * SMS tasdiqlash kodini so'rash
 */
async function getVerifyCode(request, reply) {
    const { token } = request.body;

    try {
        const result = await paymeService.getVerifyCode(token);

        return {
            success: true,
            sent: result.sent,
            phone: result.phone,
            wait: result.wait,
        };
    } catch (err) {
        request.log.error('Payme cards.get_verify_code xatosi:', err);
        return reply.status(400).send({
            success: false,
            message: err.message || 'SMS kod yuborishda xatolik',
            code: err.code,
        });
    }
}

/**
 * POST /payme/card/verify
 * Kartani SMS kod bilan tasdiqlash
 */
async function verifyCard(request, reply) {
    const { token, code } = request.body;

    try {
        const result = await paymeService.verifyCard(token, code);

        return {
            success: true,
            verified: result.verified,
            card: result.card,
        };
    } catch (err) {
        request.log.error('Payme cards.verify xatosi:', err);
        return reply.status(400).send({
            success: false,
            message: err.message || 'Kartani tasdiqlashda xatolik',
            code: err.code,
        });
    }
}

/**
 * POST /payme/card/check
 * Karta tokenini tekshirish
 */
async function checkCard(request, reply) {
    const { token } = request.body;

    try {
        const result = await paymeService.checkCard(token);

        return {
            success: true,
            verified: result.verified,
            card: result.card,
        };
    } catch (err) {
        request.log.error('Payme cards.check xatosi:', err);
        return reply.status(400).send({
            success: false,
            message: err.message || 'Kartani tekshirishda xatolik',
            code: err.code,
        });
    }
}

/**
 * DELETE /payme/card/:token
 * Karta tokenini o'chirish
 */
async function removeCard(request, reply) {
    const { token } = request.params;

    try {
        const result = await paymeService.removeCard(token);

        return {
            success: true,
            message: 'Karta o\'chirildi',
        };
    } catch (err) {
        request.log.error('Payme cards.remove xatosi:', err);
        return reply.status(400).send({
            success: false,
            message: err.message || 'Kartani o\'chirishda xatolik',
            code: err.code,
        });
    }
}

// ============= PAYMENT ENDPOINTS =============

/**
 * POST /payme/pay
 * To'lovni amalga oshirish (receipt yaratish + to'lash)
 * 
 * Oqim:
 *   1. Buyurtma (Subscription) mavjudligini tekshirish
 *   2. receipts.create — Payme da chek yaratish
 *   3. receipts.pay — karta tokeni bilan to'lash
 *   4. Subscription ni active ga o'zgartirish
 *   5. PaymeTransaction da saqlash
 */
async function pay(request, reply) {
    const { userId } = request.user;
    const { orderId, token } = request.body;

    // 1. Buyurtma tekshiruvi
    const order = await Subscription.findById(orderId);
    if (!order) {
        return reply.status(404).send({
            success: false,
            message: 'Buyurtma topilmadi',
        });
    }

    // Ownership tekshiruvi
    if (order.userId.toString() !== userId) {
        return reply.status(403).send({
            success: false,
            message: 'Ruxsat yo\'q',
        });
    }

    if (order.status !== 'pending') {
        return reply.status(400).send({
            success: false,
            message: 'Buyurtma allaqachon to\'langan yoki bekor qilingan',
        });
    }

    const amountTiyin = order.price * 100;

    try {
        // 2. Receipt yaratish
        const receipt = await paymeService.createReceipt(amountTiyin, orderId);

        // 3. Receipt to'lash
        const payResult = await paymeService.payReceipt(receipt.receiptId, token);

        // 4. PaymeTransaction yaratish
        const transaction = await PaymeTransaction.create({
            receiptId: receipt.receiptId,
            orderId: order._id,
            userId: order.userId,
            state: payResult.state, // 4 = to'langan
            amount: amountTiyin,
            cardNumber: null, // Payme maskirovka qiladi
            createTime: Date.now(),
            performTime: Date.now(),
        });

        // 5. Subscription ni activate qilish
        const planData = config.PLANS[order.plan];
        order.status = 'active';
        order.paymentMethod = 'payme';
        order.transactionId = transaction._id.toString();
        order.startDate = new Date();
        order.endDate = new Date();
        order.endDate.setDate(order.endDate.getDate() + planData.days);
        await order.save();

        return {
            success: true,
            message: 'To\'lov muvaffaqiyatli amalga oshirildi',
            transaction: {
                id: transaction._id.toString(),
                receiptId: transaction.receiptId,
                state: transaction.state,
                amount: order.price,
            },
            subscription: {
                plan: order.plan,
                status: order.status,
                startDate: order.startDate,
                endDate: order.endDate,
            },
        };
    } catch (err) {
        request.log.error('Payme pay xatosi:', err);

        // Agar receipt yaratilgan bo'lsa-yu to'lov muvaffaqiyatsiz bo'lsa
        return reply.status(400).send({
            success: false,
            message: err.message || 'To\'lovda xatolik yuz berdi',
            code: err.code,
        });
    }
}

/**
 * POST /payme/cancel
 * To'lovni bekor qilish (receipt cancel)
 */
async function cancel(request, reply) {
    const { userId } = request.user;
    const { orderId } = request.body;

    // Tranzaksiyani topish
    const transaction = await PaymeTransaction.findOne({
        orderId,
        userId,
        state: 4, // faqat to'langan receipt bekor qilinadi
    });

    if (!transaction) {
        return reply.status(404).send({
            success: false,
            message: 'To\'langan tranzaksiya topilmadi',
        });
    }

    try {
        const result = await paymeService.cancelReceipt(transaction.receiptId);

        // Tranzaksiya holatini yangilash
        transaction.state = result.state; // 50 = bekor qilingan
        transaction.cancelTime = Date.now();
        await transaction.save();

        // Subscription ni cancelled ga o'zgartirish
        const order = await Subscription.findById(orderId);
        if (order) {
            order.status = 'cancelled';
            order.cancelledAt = new Date();
            order.cancelReason = 'Payme to\'lov bekor qilindi';
            await order.save();
        }

        return {
            success: true,
            message: 'To\'lov bekor qilindi',
            state: result.state,
        };
    } catch (err) {
        request.log.error('Payme cancel xatosi:', err);
        return reply.status(400).send({
            success: false,
            message: err.message || 'To\'lovni bekor qilishda xatolik',
            code: err.code,
        });
    }
}

/**
 * GET /payme/status/:orderId
 * To'lov holatini tekshirish
 */
async function getStatus(request, reply) {
    const { userId } = request.user;
    const { orderId } = request.params;

    const transaction = await PaymeTransaction.findOne({
        orderId,
        userId,
    }).sort({ createdAt: -1 });

    if (!transaction) {
        return {
            success: true,
            paid: false,
            state: null,
            message: 'Tranzaksiya topilmadi',
        };
    }

    // Agar Payme dagi receiptId mavjud bo'lsa, real holatni tekshirish
    if (transaction.receiptId && transaction.state !== 50) {
        try {
            const check = await paymeService.checkReceipt(transaction.receiptId);
            if (check.state !== transaction.state) {
                transaction.state = check.state;
                if (check.state === 4 && !transaction.performTime) {
                    transaction.performTime = Date.now();
                }
                await transaction.save();
            }
        } catch (err) {
            request.log.warn('Receipt check xatosi:', err.message);
            // Davom etamiz — lokal ma'lumotni qaytaramiz
        }
    }

    const order = await Subscription.findById(orderId);

    return {
        success: true,
        paid: transaction.state === 4,
        state: transaction.state,
        transaction: {
            id: transaction._id.toString(),
            receiptId: transaction.receiptId,
            amount: transaction.amount / 100, // so'mga aylantirish
            createTime: transaction.createTime,
            performTime: transaction.performTime,
        },
        subscription: order ? {
            plan: order.plan,
            status: order.status,
            startDate: order.startDate,
            endDate: order.endDate,
        } : null,
    };
}

module.exports = {
    createCard,
    getVerifyCode,
    verifyCard,
    checkCard,
    removeCard,
    pay,
    cancel,
    getStatus,
};
