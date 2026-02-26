/**
 * Payme Subscribe API Controller
 * 
 * Foydalanuvchi ilovadan karta kiritadi → backend Payme API ga so'rov yuboradi.
 * Eski Merchant API webhook o'rniga REST endpointlar.
 */

const paymeService = require('../services/payme.service');
const otpRateLimiter = require('../services/otp-rate-limiter');
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
        // [FIX MED-6] PCI DSS — karta raqami logga yozilmasligi kerak
        request.log.error('Payme cards.create xatosi:', {
            message: err.message,
            code: err.code,
            // cardNumber va expire LOGGA YOZILMAYDI
        });
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
 * 
 * Rate limiting:
 * - Bloklangan user'ga SMS yuborilmaydi
 * - Qayta yuborish orasida kamida 60s kutish kerak
 */
async function getVerifyCode(request, reply) {
    const { userId } = request.user;
    const { token } = request.body;

    // 1. Bloklangan foydalanuvchini tekshirish
    const blockStatus = await otpRateLimiter.isBlocked(userId);
    if (blockStatus.blocked) {
        return reply.status(429).send({
            success: false,
            errorCode: 'BLOCKED',
            message: `Ko'p marta noto'g'ri kod kiritdingiz. ${blockStatus.remainingSeconds} soniya kutib turing`,
            remainingSeconds: blockStatus.remainingSeconds,
        });
    }

    // 2. Qayta yuborish tezligini tekshirish
    const resendStatus = await otpRateLimiter.canResendCode(userId);
    if (!resendStatus.canResend) {
        return reply.status(429).send({
            success: false,
            errorCode: 'RESEND_TOO_FAST',
            message: `SMS kodni qayta yuborish uchun ${resendStatus.waitSeconds} soniya kutib turing`,
            waitSeconds: resendStatus.waitSeconds,
        });
    }

    try {
        const result = await paymeService.getVerifyCode(token);

        // 3. Kod sessiyasini qayd etish (60s muddat boshlanadi)
        await otpRateLimiter.recordCodeSent(userId, token);

        return {
            success: true,
            sent: result.sent,
            phone: result.phone,
            wait: result.wait,
            codeExpiresIn: 60,
            attemptsLeft: await otpRateLimiter.getAttemptsLeft(userId),
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
 * 
 * Rate limiting:
 * - Bloklangan user verify qila olmaydi
 * - Kod muddati (60s) o'tgan bo'lsa, qayta yuborish kerak
 * - 3 marta noto'g'ri = 5 daqiqa blok
 */
async function verifyCard(request, reply) {
    const { userId } = request.user;
    const { token, code } = request.body;

    // 1. Bloklangan foydalanuvchini tekshirish
    const blockStatus = await otpRateLimiter.isBlocked(userId);
    if (blockStatus.blocked) {
        return reply.status(429).send({
            success: false,
            errorCode: 'BLOCKED',
            message: `Ko'p marta noto'g'ri kod kiritdingiz. ${blockStatus.remainingSeconds} soniya kutib turing`,
            remainingSeconds: blockStatus.remainingSeconds,
        });
    }

    // 2. Kod muddatini tekshirish
    const expiryStatus = await otpRateLimiter.isCodeExpired(userId);
    if (expiryStatus.expired) {
        return reply.status(400).send({
            success: false,
            errorCode: 'CODE_EXPIRED',
            message: 'Tasdiqlash kodi muddati tugagan. Iltimos, qayta yuborish tugmasini bosing',
            attemptsLeft: await otpRateLimiter.getAttemptsLeft(userId),
        });
    }

    try {
        const result = await paymeService.verifyCard(token, code);

        // 3. Muvaffaqiyat — barcha counterlarni tozalash
        await otpRateLimiter.resetAttempts(userId);

        return {
            success: true,
            verified: result.verified,
            card: result.card,
        };
    } catch (err) {
        request.log.error('Payme cards.verify xatosi:', err);

        // 4. Noto'g'ri kod — urinishni qayd etish
        const attemptResult = await otpRateLimiter.recordFailedAttempt(userId);

        if (attemptResult.blocked) {
            return reply.status(429).send({
                success: false,
                errorCode: 'MAX_ATTEMPTS',
                message: `3 marta noto'g'ri kod kiritdingiz. ${attemptResult.remainingSeconds} soniya kutib turing`,
                remainingSeconds: attemptResult.remainingSeconds,
                attemptsLeft: 0,
            });
        }

        return reply.status(400).send({
            success: false,
            errorCode: 'VERIFY_FAILED',
            message: err.message || 'Tasdiqlash kodi noto\'g\'ri',
            attemptsLeft: attemptResult.attemptsLeft,
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

    // 1. ATOMIC: pending → processing (race condition oldini olish)
    // Ikkita parallel so'rov kelsa, faqat bittasi muvaffaqiyatli bo'ladi
    const order = await Subscription.findOneAndUpdate(
        { _id: orderId, userId, status: 'pending' },
        { $set: { status: 'processing' } },
        { new: true }
    );

    if (!order) {
        // Aniq xato xabarini qaytarish
        const existing = await Subscription.findById(orderId);
        if (!existing) {
            return reply.status(404).send({
                success: false,
                message: 'Buyurtma topilmadi',
            });
        }
        if (existing.userId.toString() !== userId) {
            return reply.status(403).send({
                success: false,
                message: 'Ruxsat yo\'q',
            });
        }
        return reply.status(400).send({
            success: false,
            message: 'Buyurtma allaqachon to\'langan yoki qayta ishlanyapti',
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

        // 5. Subscription ni activate qilish (processing → active)
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

        // ROLLBACK: processing → pending (to'lov muvaffaqiyatsiz bo'lsa)
        await Subscription.updateOne(
            { _id: orderId, status: 'processing' },
            { $set: { status: 'pending' } }
        );

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
