/**
 * Subscription Controller Tests
 * Obuna boshqaruvi uchun testlar
 */

const { buildTestServer, closeTestServer, createTestToken } = require('./helpers/testServer');

// Mock models
jest.mock('../src/models', () => ({
    Subscription: {
        getActive: jest.fn(),
        findById: jest.fn(),
        findOne: jest.fn(),
        find: jest.fn(),
        create: jest.fn()
    },
    User: {
        findById: jest.fn()
    }
}));

// Mock config
jest.mock('../src/config/env', () => ({
    PLANS: {
        monthly: { name: 'Oylik', price: 29900, days: 30 },
        yearly: { name: 'Yillik', price: 214900, days: 365 },
        lifetime: { name: 'Umrbod', price: 499900, days: 36500 }
    },
    PAYME_MERCHANT_ID: 'test-merchant-id',
    PAYME_CHECKOUT_URL: 'https://test.paycom.uz',
    NODE_ENV: 'test'
}));

const { Subscription } = require('../src/models');
const subscriptionController = require('../src/controllers/subscription.controller');

describe('Subscription Controller', () => {
    let app;
    let authToken;

    beforeAll(async () => {
        app = await buildTestServer();

        // Register routes
        app.get('/subscription', {
            preHandler: [app.authenticate]
        }, async (request, reply) => subscriptionController.getCurrent(request, reply));

        app.get('/subscription/plans',
            async (request, reply) => subscriptionController.getPlans(request, reply));

        app.post('/subscription/create', {
            preHandler: [app.authenticate]
        }, async (request, reply) => subscriptionController.create(request, reply));

        app.get('/subscription/check/:orderId', {
            preHandler: [app.authenticate]
        }, async (request, reply) => subscriptionController.checkOrder(request, reply));

        app.post('/subscription/activate', {
            preHandler: [app.authenticate]
        }, async (request, reply) => subscriptionController.activate(request, reply));

        app.post('/subscription/cancel', {
            preHandler: [app.authenticate]
        }, async (request, reply) => subscriptionController.cancel(request, reply));

        app.get('/subscription/history', {
            preHandler: [app.authenticate]
        }, async (request, reply) => subscriptionController.getHistory(request, reply));

        await app.ready();
        authToken = createTestToken(app, { userId: 'user123', role: 'parent' });
    });

    afterAll(async () => {
        await closeTestServer(app);
    });

    beforeEach(() => {
        jest.clearAllMocks();
    });

    // =====================================================
    // GET /subscription — Joriy obuna
    // =====================================================
    describe('GET /subscription', () => {
        it('should return hasSubscription: false when no active subscription', async () => {
            Subscription.getActive.mockResolvedValue(null);

            const response = await app.inject({
                method: 'GET',
                url: '/subscription',
                headers: { authorization: `Bearer ${authToken}` }
            });

            const data = JSON.parse(response.body);
            expect(response.statusCode).toBe(200);
            expect(data.success).toBe(true);
            expect(data.hasSubscription).toBe(false);
        });

        it('should return subscription details when active', async () => {
            const now = new Date();
            const endDate = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

            Subscription.getActive.mockResolvedValue({
                plan: 'monthly',
                status: 'active',
                startDate: now,
                endDate,
                maxDevices: 3
            });

            const response = await app.inject({
                method: 'GET',
                url: '/subscription',
                headers: { authorization: `Bearer ${authToken}` }
            });

            const data = JSON.parse(response.body);
            expect(response.statusCode).toBe(200);
            expect(data.success).toBe(true);
            expect(data.hasSubscription).toBe(true);
            expect(data.subscription.plan).toBe('monthly');
            expect(data.subscription.daysRemaining).toBeGreaterThan(0);
        });

        it('should require authentication', async () => {
            const response = await app.inject({
                method: 'GET',
                url: '/subscription'
            });

            expect(response.statusCode).toBe(401);
        });
    });

    // =====================================================
    // GET /subscription/plans — Planlar ro'yxati
    // =====================================================
    describe('GET /subscription/plans', () => {
        it('should return all available plans', async () => {
            const response = await app.inject({
                method: 'GET',
                url: '/subscription/plans'
            });

            const data = JSON.parse(response.body);
            expect(response.statusCode).toBe(200);
            expect(data.success).toBe(true);
            expect(data.plans).toHaveLength(3);
            expect(data.plans[0]).toHaveProperty('id');
            expect(data.plans[0]).toHaveProperty('name');
            expect(data.plans[0]).toHaveProperty('price');
            expect(data.plans[0]).toHaveProperty('days');
            expect(data.plans[0]).toHaveProperty('features');
        });
    });

    // =====================================================
    // POST /subscription/create — Yangi obuna yaratish
    // =====================================================
    describe('POST /subscription/create', () => {
        it('should create subscription with checkout URL', async () => {
            Subscription.create.mockResolvedValue({
                _id: 'sub123',
                userId: 'user123',
                plan: 'monthly',
                status: 'pending',
                price: 29900,
                toString: () => 'sub123'
            });

            const response = await app.inject({
                method: 'POST',
                url: '/subscription/create',
                headers: { authorization: `Bearer ${authToken}` },
                payload: { plan: 'monthly' }
            });

            const data = JSON.parse(response.body);
            expect(response.statusCode).toBe(200);
            expect(data.success).toBe(true);
            expect(data.orderId).toBeDefined();
            expect(data.amount).toBe(29900);
            expect(Subscription.create).toHaveBeenCalled();
        });

        it('should reject invalid plan', async () => {
            const response = await app.inject({
                method: 'POST',
                url: '/subscription/create',
                headers: { authorization: `Bearer ${authToken}` },
                payload: { plan: 'invalid_plan' }
            });

            expect(response.statusCode).toBe(400);
        });
    });

    // =====================================================
    // GET /subscription/check/:orderId — To'lov tekshirish
    // =====================================================
    describe('GET /subscription/check/:orderId', () => {
        it('should return order status', async () => {
            Subscription.findById.mockResolvedValue({
                _id: 'sub123',
                userId: { toString: () => 'user123' },
                status: 'pending',
                plan: 'monthly'
            });

            const response = await app.inject({
                method: 'GET',
                url: '/subscription/check/sub123',
                headers: { authorization: `Bearer ${authToken}` }
            });

            const data = JSON.parse(response.body);
            expect(response.statusCode).toBe(200);
            expect(data.success).toBe(true);
            expect(data.status).toBe('pending');
            expect(data.paid).toBe(false);
        });

        it('should return 404 for non-existent order', async () => {
            Subscription.findById.mockResolvedValue(null);

            const response = await app.inject({
                method: 'GET',
                url: '/subscription/check/nonexistent',
                headers: { authorization: `Bearer ${authToken}` }
            });

            expect(response.statusCode).toBe(404);
        });

        it('should return 403 for other user order', async () => {
            Subscription.findById.mockResolvedValue({
                _id: 'sub123',
                userId: { toString: () => 'other-user-id' },
                status: 'pending'
            });

            const response = await app.inject({
                method: 'GET',
                url: '/subscription/check/sub123',
                headers: { authorization: `Bearer ${authToken}` }
            });

            expect(response.statusCode).toBe(403);
        });
    });

    // =====================================================
    // POST /subscription/activate — Obunani faollashtirish
    // =====================================================
    describe('POST /subscription/activate', () => {
        it('should activate pending subscription', async () => {
            const mockSub = {
                _id: 'sub123',
                userId: { toString: () => 'user123' },
                status: 'pending',
                plan: 'monthly',
                save: jest.fn().mockResolvedValue(true)
            };
            Subscription.findById.mockResolvedValue(mockSub);
            Subscription.findOne.mockResolvedValue(null); // No duplicate tx

            const response = await app.inject({
                method: 'POST',
                url: '/subscription/activate',
                headers: { authorization: `Bearer ${authToken}` },
                payload: {
                    orderId: 'sub123',
                    transactionId: 'tx-001',
                    paymentMethod: 'payme'
                }
            });

            const data = JSON.parse(response.body);
            expect(response.statusCode).toBe(200);
            expect(data.success).toBe(true);
            expect(mockSub.save).toHaveBeenCalled();
        });

        it('should reject duplicate transactionId', async () => {
            const mockSub = {
                _id: 'sub123',
                userId: { toString: () => 'user123' },
                status: 'pending',
                plan: 'monthly'
            };
            Subscription.findById.mockResolvedValue(mockSub);
            Subscription.findOne.mockResolvedValue({ _id: 'existing' }); // Duplicate tx

            const response = await app.inject({
                method: 'POST',
                url: '/subscription/activate',
                headers: { authorization: `Bearer ${authToken}` },
                payload: {
                    orderId: 'sub123',
                    transactionId: 'tx-duplicate',
                    paymentMethod: 'payme'
                }
            });

            expect(response.statusCode).toBe(400);
        });

        it('should return success if already active', async () => {
            Subscription.findById.mockResolvedValue({
                _id: 'sub123',
                userId: { toString: () => 'user123' },
                status: 'active'
            });

            const response = await app.inject({
                method: 'POST',
                url: '/subscription/activate',
                headers: { authorization: `Bearer ${authToken}` },
                payload: {
                    orderId: 'sub123',
                    transactionId: 'tx-002',
                    paymentMethod: 'payme'
                }
            });

            const data = JSON.parse(response.body);
            expect(data.success).toBe(true);
        });
    });

    // =====================================================
    // POST /subscription/cancel — Obuna bekor qilish
    // =====================================================
    describe('POST /subscription/cancel', () => {
        it('should cancel active subscription', async () => {
            const mockSub = {
                status: 'active',
                save: jest.fn().mockResolvedValue(true)
            };
            Subscription.findOne.mockResolvedValue(mockSub);

            const response = await app.inject({
                method: 'POST',
                url: '/subscription/cancel',
                headers: { authorization: `Bearer ${authToken}` },
                payload: { reason: 'Pul yetmadi' }
            });

            const data = JSON.parse(response.body);
            expect(response.statusCode).toBe(200);
            expect(data.success).toBe(true);
            expect(mockSub.status).toBe('cancelled');
            expect(mockSub.save).toHaveBeenCalled();
        });

        it('should return 404 when no active subscription', async () => {
            Subscription.findOne.mockResolvedValue(null);

            const response = await app.inject({
                method: 'POST',
                url: '/subscription/cancel',
                headers: { authorization: `Bearer ${authToken}` },
                payload: { reason: 'Test' }
            });

            expect(response.statusCode).toBe(404);
        });
    });

    // =====================================================
    // GET /subscription/history — Obuna tarixi
    // =====================================================
    describe('GET /subscription/history', () => {
        it('should return subscription history', async () => {
            const mockQuery = {
                sort: jest.fn().mockReturnThis(),
                limit: jest.fn().mockResolvedValue([
                    { plan: 'monthly', status: 'expired' },
                    { plan: 'yearly', status: 'active' }
                ])
            };
            Subscription.find.mockReturnValue(mockQuery);

            const response = await app.inject({
                method: 'GET',
                url: '/subscription/history',
                headers: { authorization: `Bearer ${authToken}` }
            });

            const data = JSON.parse(response.body);
            expect(response.statusCode).toBe(200);
            expect(data.success).toBe(true);
            expect(data.subscriptions).toHaveLength(2);
        });
    });
});

// =====================================================
// Subscription Model Logic Tests
// =====================================================
describe('Subscription Model Logic', () => {
    it('should validate plan types', () => {
        const validPlans = ['monthly', 'yearly', 'lifetime'];
        const invalidPlans = ['weekly', 'daily', ''];

        validPlans.forEach(plan => {
            expect(['monthly', 'yearly', 'lifetime'].includes(plan)).toBe(true);
        });

        invalidPlans.forEach(plan => {
            expect(['monthly', 'yearly', 'lifetime'].includes(plan)).toBe(false);
        });
    });

    it('should calculate days remaining correctly', () => {
        const now = new Date();
        const endDate = new Date(now.getTime() + 15 * 24 * 60 * 60 * 1000); // 15 kun
        const daysRemaining = Math.ceil((endDate - now) / (1000 * 60 * 60 * 24));
        expect(daysRemaining).toBe(15);
    });

    it('should handle expired subscription', () => {
        const now = new Date();
        const endDate = new Date(now.getTime() - 1 * 24 * 60 * 60 * 1000); // O'tgan kun
        const isValid = endDate > now;
        expect(isValid).toBe(false);
    });

    it('should calculate Payme amount in tiyin', () => {
        const priceInSum = 29900;
        const amountInTiyin = priceInSum * 100;
        expect(amountInTiyin).toBe(2990000);
    });
});
