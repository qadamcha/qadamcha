/**
 * Auth Controller Tests
 * Autentifikatsiya funksiyalari uchun testlar
 */

const { buildTestServer, closeTestServer } = require('./helpers/testServer');
const RedisMock = require('ioredis-mock');

// Mock models
jest.mock('../src/models', () => ({
    User: {
        findOne: jest.fn(),
        create: jest.fn(),
        findById: jest.fn()
    },
    Device: {
        findOne: jest.fn(),
        create: jest.fn(),
        countDocuments: jest.fn()
    }
}));

// Mock SMS service
jest.mock('../src/services/sms.service', () => ({
    generateOtp: jest.fn(() => '123456'),
    sendOtp: jest.fn(() => Promise.resolve({ success: true })),
    setRedis: jest.fn()
}));

const { User, Device } = require('../src/models');
const smsService = require('../src/services/sms.service');

describe('Auth Controller', () => {
    let app;
    let redis;

    beforeAll(async () => {
        app = await buildTestServer();
        redis = app.redis;

        // Register auth routes
        const authController = require('../src/controllers/auth.controller');

        app.post('/auth/send-otp', async function (request, reply) {
            return authController.sendOtp.call(this, request, reply);
        });

        app.post('/auth/verify-otp', async function (request, reply) {
            return authController.verifyOtp.call(this, request, reply);
        });

        await app.ready();
    });

    afterAll(async () => {
        await closeTestServer(app);
    });

    beforeEach(() => {
        jest.clearAllMocks();
    });

    describe('POST /auth/send-otp', () => {
        it('should send OTP successfully', async () => {
            const response = await app.inject({
                method: 'POST',
                url: '/auth/send-otp',
                payload: {
                    phone: '+998901234567'
                }
            });

            const data = JSON.parse(response.body);
            expect(response.statusCode).toBe(200);
            expect(data.success).toBe(true);
            expect(smsService.generateOtp).toHaveBeenCalled();
        });

        it('should block after 3 attempts', async () => {
            // Set attempts to 3
            await redis.set('otp_attempts:+998907654321', '3');

            const response = await app.inject({
                method: 'POST',
                url: '/auth/send-otp',
                payload: {
                    phone: '+998907654321'
                }
            });

            expect(response.statusCode).toBe(429);
        });
    });

    describe('POST /auth/verify-otp', () => {
        it('should verify correct OTP', async () => {
            const phone = '+998901112233';
            await redis.setex(`otp:${phone}`, 300, '123456');
            User.findOne.mockResolvedValue(null); // New user

            const response = await app.inject({
                method: 'POST',
                url: '/auth/verify-otp',
                payload: { phone, code: '123456' }
            });

            const data = JSON.parse(response.body);
            expect(response.statusCode).toBe(200);
            expect(data.success).toBe(true);
            expect(data.isNewUser).toBe(true);
        });

        it('should reject incorrect OTP', async () => {
            const phone = '+998901112244';
            await redis.setex(`otp:${phone}`, 300, '123456');

            const response = await app.inject({
                method: 'POST',
                url: '/auth/verify-otp',
                payload: { phone, code: 'wrong!' }
            });

            expect(response.statusCode).toBe(400);
        });
    });
});

describe('Auth Validation', () => {
    it('should validate phone format', () => {
        const validPhones = ['+998901234567', '+998712345678'];
        const invalidPhones = ['998901234567', '+1234567890', 'abc'];

        validPhones.forEach(phone => {
            expect(phone.match(/^\+998[0-9]{9}$/)).toBeTruthy();
        });

        invalidPhones.forEach(phone => {
            expect(phone.match(/^\+998[0-9]{9}$/)).toBeFalsy();
        });
    });

    it('should validate PIN format', () => {
        const validPins = ['1234', '123456'];
        const invalidPins = ['123', '1234567', 'abcd'];

        validPins.forEach(pin => {
            expect(pin.length >= 4 && pin.length <= 6 && /^\d+$/.test(pin)).toBe(true);
        });

        invalidPins.forEach(pin => {
            expect(pin.length >= 4 && pin.length <= 6 && /^\d+$/.test(pin)).toBe(false);
        });
    });
});
