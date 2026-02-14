const { PaymeTransaction, Subscription } = require('../models');
const config = require('../config/env');

// Payme JSON-RPC error codes
const PaymeError = {
    InvalidAmount: -31001,
    OrderNotFound: -31050,
    CantDoOperation: -31008,
    TransactionNotFound: -31003,
    InvalidAuthorization: -32504,
    MethodNotFound: -32601,
};

// 12 soat — tranzaksiya timeout (ms)
const TRANSACTION_TIMEOUT = 43200000;

function paymeError(id, code, messageUz, messageRu, messageEn) {
    return {
        jsonrpc: '2.0',
        id,
        error: {
            code,
            message: { uz: messageUz, ru: messageRu || messageUz, en: messageEn || messageUz },
        },
    };
}

function paymeResult(id, result) {
    return { jsonrpc: '2.0', id, result };
}

// Basic Auth tekshiruvi: "Basic Base64(Paycom:{PAYME_KEY})"
function checkAuth(request) {
    const authHeader = request.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Basic ')) return false;

    const decoded = Buffer.from(authHeader.slice(6), 'base64').toString('utf-8');
    const [login, password] = decoded.split(':');
    return login === 'Paycom' && password === config.PAYME_KEY;
}

async function CheckPerformTransaction(id, params) {
    const { account, amount } = params;
    const orderId = account?.order_id;

    const order = await Subscription.findById(orderId);
    if (!order) {
        return paymeError(id, PaymeError.OrderNotFound, 'Buyurtma topilmadi');
    }

    if (order.status !== 'pending') {
        return paymeError(id, PaymeError.CantDoOperation, 'Buyurtma allaqachon to\'langan yoki bekor qilingan');
    }

    // amount tiyin da keladi, price so'm da
    if (amount !== order.price * 100) {
        return paymeError(id, PaymeError.InvalidAmount, 'Noto\'g\'ri summa');
    }

    return paymeResult(id, { allow: true });
}

async function CreateTransaction(id, params) {
    const { account, amount, time } = params;
    const paymeId = params.id;
    const orderId = account?.order_id;

    // Mavjud tranzaksiya bormi?
    const existing = await PaymeTransaction.findOne({ paymeId });
    if (existing) {
        if (existing.state !== 1) {
            return paymeError(id, PaymeError.CantDoOperation, 'Tranzaksiya yaratib bo\'lmaydi');
        }
        // Timeout tekshirish
        if (Date.now() - existing.createTime > TRANSACTION_TIMEOUT) {
            existing.state = -1;
            existing.cancelTime = Date.now();
            existing.reason = 4; // timeout
            await existing.save();
            return paymeError(id, PaymeError.CantDoOperation, 'Tranzaksiya muddati tugagan');
        }
        return paymeResult(id, {
            create_time: existing.createTime,
            transaction: existing._id.toString(),
            state: existing.state,
        });
    }

    // Buyurtma tekshiruvi
    const order = await Subscription.findById(orderId);
    if (!order) {
        return paymeError(id, PaymeError.OrderNotFound, 'Buyurtma topilmadi');
    }
    if (order.status !== 'pending') {
        return paymeError(id, PaymeError.CantDoOperation, 'Buyurtma allaqachon to\'langan');
    }
    if (amount !== order.price * 100) {
        return paymeError(id, PaymeError.InvalidAmount, 'Noto\'g\'ri summa');
    }

    // Bu buyurtma uchun boshqa active tranzaksiya bormi?
    const activeForOrder = await PaymeTransaction.findOne({ orderId, state: 1 });
    if (activeForOrder) {
        // Oldingi tranzaksiyani bekor qilish
        activeForOrder.state = -1;
        activeForOrder.cancelTime = Date.now();
        activeForOrder.reason = 4;
        await activeForOrder.save();
    }

    const transaction = await PaymeTransaction.create({
        paymeId,
        orderId,
        userId: order.userId,
        state: 1,
        amount,
        createTime: time,
    });

    return paymeResult(id, {
        create_time: transaction.createTime,
        transaction: transaction._id.toString(),
        state: 1,
    });
}

async function PerformTransaction(id, params) {
    const paymeId = params.id;

    const transaction = await PaymeTransaction.findOne({ paymeId });
    if (!transaction) {
        return paymeError(id, PaymeError.TransactionNotFound, 'Tranzaksiya topilmadi');
    }

    if (transaction.state === 2) {
        return paymeResult(id, {
            perform_time: transaction.performTime,
            transaction: transaction._id.toString(),
            state: 2,
        });
    }

    if (transaction.state !== 1) {
        return paymeError(id, PaymeError.CantDoOperation, 'Tranzaksiyani bajarib bo\'lmaydi');
    }

    // Timeout tekshirish
    if (Date.now() - transaction.createTime > TRANSACTION_TIMEOUT) {
        transaction.state = -1;
        transaction.cancelTime = Date.now();
        transaction.reason = 4;
        await transaction.save();
        return paymeError(id, PaymeError.CantDoOperation, 'Tranzaksiya muddati tugagan');
    }

    // Tranzaksiyani bajarish
    transaction.state = 2;
    transaction.performTime = Date.now();
    await transaction.save();

    // Obunani faollashtirish
    const order = await Subscription.findById(transaction.orderId);
    if (order && order.status === 'pending') {
        const planData = config.PLANS[order.plan];
        order.status = 'active';
        order.paymentMethod = 'payme';
        order.transactionId = paymeId;
        order.startDate = new Date();
        order.endDate = new Date();
        order.endDate.setDate(order.endDate.getDate() + planData.days);
        await order.save();
    }

    return paymeResult(id, {
        perform_time: transaction.performTime,
        transaction: transaction._id.toString(),
        state: 2,
    });
}

async function CancelTransaction(id, params) {
    const paymeId = params.id;
    const { reason } = params;

    const transaction = await PaymeTransaction.findOne({ paymeId });
    if (!transaction) {
        return paymeError(id, PaymeError.TransactionNotFound, 'Tranzaksiya topilmadi');
    }

    if (transaction.state === 1) {
        transaction.state = -1;
        transaction.cancelTime = Date.now();
        transaction.reason = reason;
        await transaction.save();

        // Buyurtmani qaytarish
        const order = await Subscription.findById(transaction.orderId);
        if (order && order.status === 'pending') {
            order.status = 'cancelled';
            order.cancelledAt = new Date();
            order.cancelReason = 'Payme tomonidan bekor qilindi';
            await order.save();
        }

        return paymeResult(id, {
            cancel_time: transaction.cancelTime,
            transaction: transaction._id.toString(),
            state: -1,
        });
    }

    if (transaction.state === 2) {
        // To'lov amalga oshirilgan — qaytarish (refund)
        transaction.state = -2;
        transaction.cancelTime = Date.now();
        transaction.reason = reason;
        await transaction.save();

        const order = await Subscription.findById(transaction.orderId);
        if (order) {
            order.status = 'cancelled';
            order.cancelledAt = new Date();
            order.cancelReason = 'Payme tomonidan qaytarildi';
            await order.save();
        }

        return paymeResult(id, {
            cancel_time: transaction.cancelTime,
            transaction: transaction._id.toString(),
            state: -2,
        });
    }

    // Allaqachon bekor qilingan
    return paymeResult(id, {
        cancel_time: transaction.cancelTime,
        transaction: transaction._id.toString(),
        state: transaction.state,
    });
}

async function CheckTransaction(id, params) {
    const paymeId = params.id;

    const transaction = await PaymeTransaction.findOne({ paymeId });
    if (!transaction) {
        return paymeError(id, PaymeError.TransactionNotFound, 'Tranzaksiya topilmadi');
    }

    return paymeResult(id, {
        create_time: transaction.createTime,
        perform_time: transaction.performTime,
        cancel_time: transaction.cancelTime,
        transaction: transaction._id.toString(),
        state: transaction.state,
        reason: transaction.reason,
    });
}

async function GetStatement(id, params) {
    const { from, to } = params;

    const transactions = await PaymeTransaction.find({
        createTime: { $gte: from, $lte: to },
    });

    const items = transactions.map((t) => ({
        id: t.paymeId,
        time: t.createTime,
        amount: t.amount,
        account: { order_id: t.orderId.toString() },
        create_time: t.createTime,
        perform_time: t.performTime,
        cancel_time: t.cancelTime,
        transaction: t._id.toString(),
        state: t.state,
        reason: t.reason,
    }));

    return paymeResult(id, { transactions: items });
}

// Asosiy JSON-RPC handler
const methods = {
    CheckPerformTransaction,
    CreateTransaction,
    PerformTransaction,
    CancelTransaction,
    CheckTransaction,
    GetStatement,
};

module.exports = {
    async handle(request, reply) {
        const { id, method, params } = request.body;

        // Auth tekshiruvi
        if (!checkAuth(request)) {
            return reply.status(200).send(
                paymeError(id, PaymeError.InvalidAuthorization, 'Autentifikatsiya xatosi')
            );
        }

        const handler = methods[method];
        if (!handler) {
            return reply.status(200).send(
                paymeError(id, PaymeError.MethodNotFound, `Method topilmadi: ${method}`)
            );
        }

        try {
            const result = await handler(id, params);
            return reply.status(200).send(result);
        } catch (err) {
            request.log.error(`Payme ${method} error:`, err);
            return reply.status(200).send(
                paymeError(id, -32400, 'Ichki server xatosi')
            );
        }
    },
};
