const { Type } = require('@sinclair/typebox');
const authController = require('../controllers/auth.controller');

// Validation Schemas
const PhoneSchema = Type.Object({
    phone: Type.String({
        pattern: '^\\+998[0-9]{9}$'
    }),
    purpose: Type.Optional(Type.Union([
        Type.Literal('register'),
        Type.Literal('reset-pin')
    ]))
});

const OtpVerifySchema = Type.Object({
    phone: Type.String({ pattern: '^\\+998[0-9]{9}$' }),
    code: Type.String({ minLength: 6, maxLength: 6 })
});

const RegisterSchema = Type.Object({
    phone: Type.String({ pattern: '^\\+998[0-9]{9}$' }),
    name: Type.String({ minLength: 2, maxLength: 50 }),
    pin: Type.String({ minLength: 4, maxLength: 6, pattern: '^[0-9]+$' }),
    verifiedToken: Type.String({ minLength: 1 })
});

const LoginSchema = Type.Object({
    phone: Type.String({ pattern: '^\\+998[0-9]{9}$' }),
    pin: Type.String({ minLength: 4, maxLength: 6 }),
    deviceId: Type.String({ minLength: 1 }),
    deviceName: Type.Optional(Type.String()),
    deviceType: Type.Optional(Type.Union([
        Type.Literal('android'),
        Type.Literal('ios')
    ]))
});

const RefreshSchema = Type.Object({
    refreshToken: Type.String({ minLength: 1 })
});

const ResetPinSchema = Type.Object({
    phone: Type.String({ pattern: '^\\+998[0-9]{9}$' }),
    newPin: Type.String({ minLength: 4, maxLength: 6, pattern: '^[0-9]+$' }),
    verifiedToken: Type.String({ minLength: 1 })
});

const VerifyPinSchema = Type.Object({
    pin: Type.String({ minLength: 4, maxLength: 6, pattern: '^[0-9]+$' })
});

// Auth endpointlar uchun rate limitlar
const authRateLimit = {
    config: {
        rateLimit: {
            max: 5,
            timeWindow: '1 minute',
        }
    }
};
const otpRateLimit = {
    config: {
        rateLimit: {
            max: 3,
            timeWindow: '1 minute',
        }
    }
};

module.exports = async function (fastify) {

    // POST /auth/send-otp - OTP yuborish
    fastify.post('/send-otp', {
        schema: { body: PhoneSchema },
        ...otpRateLimit
    }, authController.sendOtp);

    // POST /auth/verify-otp - OTP tekshirish
    fastify.post('/verify-otp', {
        schema: { body: OtpVerifySchema },
        ...otpRateLimit
    }, authController.verifyOtp);

    // POST /auth/register - Ro'yxatdan o'tish
    fastify.post('/register', {
        schema: { body: RegisterSchema },
        ...authRateLimit
    }, authController.register);

    // POST /auth/reset-pin - PIN tiklash
    fastify.post('/reset-pin', {
        schema: { body: ResetPinSchema },
        ...authRateLimit
    }, authController.resetPin);

    // POST /auth/login - Kirish
    fastify.post('/login', {
        schema: { body: LoginSchema },
        ...authRateLimit
    }, authController.login);

    // POST /auth/refresh - Token yangilash
    fastify.post('/refresh', {
        schema: { body: RefreshSchema },
        ...authRateLimit
    }, authController.refresh);

    // POST /auth/verify-pin - PIN tekshirish (faqat token borlar uchun)
    fastify.post('/verify-pin', {
        schema: { body: VerifyPinSchema },
        preHandler: [fastify.authenticate],
        ...authRateLimit
    }, authController.verifyPin);

    // POST /auth/logout - Chiqish
    fastify.post('/logout', {
        preHandler: [fastify.authenticate]
    }, authController.logout);

    // [FIX MED-8] PUT /auth/profile olib tashlandi — /user/profile orqali yangilash kerak
    // Duplicate endpoint bo'lgani uchun confusion oldini olish maqsadida olib tashlandi

};
