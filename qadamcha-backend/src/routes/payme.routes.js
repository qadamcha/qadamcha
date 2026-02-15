/**
 * Payme Subscribe API Routes
 * 
 * Barcha endpointlar autentifikatsiya talab qiladi (JWT).
 * Card endpointlarida kuchaytirilgan rate limiting ishlatiladi.
 */

const { Type } = require('@sinclair/typebox');
const paymeController = require('../controllers/payme.controller');

// ============= REQUEST SCHEMAS =============

const CardCreateSchema = Type.Object({
    cardNumber: Type.String({ minLength: 16, maxLength: 16, pattern: '^[0-9]{16}$' }),
    expire: Type.String({ minLength: 4, maxLength: 4, pattern: '^[0-9]{4}$' }),
});

const TokenSchema = Type.Object({
    token: Type.String({ minLength: 1 }),
});

const VerifySchema = Type.Object({
    token: Type.String({ minLength: 1 }),
    code: Type.String({ minLength: 6, maxLength: 6, pattern: '^[0-9]{6}$' }),
});

const PaySchema = Type.Object({
    orderId: Type.String({ minLength: 1 }),
    token: Type.String({ minLength: 1 }),
});

const CancelSchema = Type.Object({
    orderId: Type.String({ minLength: 1 }),
});

// ============= RATE LIMIT CONFIG =============

const cardRateLimit = {
    max: 10,
    timeWindow: '1 minute',
};

const payRateLimit = {
    max: 5,
    timeWindow: '1 minute',
};

// ============= ROUTES =============

module.exports = async function (fastify) {

    // --- Card Management ---

    // POST /payme/card/create — karta tokenini yaratish
    fastify.post('/card/create', {
        preHandler: [fastify.authenticate],
        schema: { body: CardCreateSchema },
        config: { rateLimit: cardRateLimit },
    }, paymeController.createCard);

    // POST /payme/card/verify-code — SMS kod so'rash
    fastify.post('/card/verify-code', {
        preHandler: [fastify.authenticate],
        schema: { body: TokenSchema },
        config: { rateLimit: cardRateLimit },
    }, paymeController.getVerifyCode);

    // POST /payme/card/verify — kartani SMS kod bilan tasdiqlash
    fastify.post('/card/verify', {
        preHandler: [fastify.authenticate],
        schema: { body: VerifySchema },
        config: { rateLimit: cardRateLimit },
    }, paymeController.verifyCard);

    // POST /payme/card/check — karta tokenini tekshirish
    fastify.post('/card/check', {
        preHandler: [fastify.authenticate],
        schema: { body: TokenSchema },
        config: { rateLimit: cardRateLimit },
    }, paymeController.checkCard);

    // DELETE /payme/card/:token — karta tokenini o'chirish
    fastify.delete('/card/:token', {
        preHandler: [fastify.authenticate],
        config: { rateLimit: cardRateLimit },
    }, paymeController.removeCard);

    // --- Payment ---

    // POST /payme/pay — to'lovni amalga oshirish
    fastify.post('/pay', {
        preHandler: [fastify.authenticate],
        schema: { body: PaySchema },
        config: { rateLimit: payRateLimit },
    }, paymeController.pay);

    // POST /payme/cancel — to'lovni bekor qilish
    fastify.post('/cancel', {
        preHandler: [fastify.authenticate],
        schema: { body: CancelSchema },
        config: { rateLimit: payRateLimit },
    }, paymeController.cancel);

    // GET /payme/status/:orderId — to'lov holatini tekshirish
    fastify.get('/status/:orderId', {
        preHandler: [fastify.authenticate],
    }, paymeController.getStatus);
};
