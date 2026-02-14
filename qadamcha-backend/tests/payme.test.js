/**
 * Payme Controller Tests
 * Payme to'lov tizimi integratsiyasi uchun testlar
 */

const { buildTestServer, closeTestServer } = require('./helpers/testServer');

// Mock models
jest.mock('../src/models', () => ({
    PaymeTransaction: {
        findOne: jest.fn(),
        create: jest.fn(),
        find: jest.fn()
    },
    Subscription: {
        findById: jest.fn()
    }
}));

// Mock config — PAYME_KEY nomi controller da ishlatiladi
jest.mock('../src/config/env', () => ({
    PAYME_KEY: 'test-payme-key',
    PLANS: {
        monthly: { name: 'Oylik', price: 29900, days: 30 },
        yearly: { name: 'Yillik', price: 214900, days: 365 },
        lifetime: { name: 'Umrbod', price: 499900, days: 36500 }
    },
    NODE_ENV: 'test'
}));

const { PaymeTransaction, Subscription } = require('../src/models');
const paymeController = require('../src/controllers/payme.controller');

// Payme Basic Auth header yaratish
function createPaymeAuth(login = 'Paycom', key = 'test-payme-key') {
    const encoded = Buffer.from(`${login}:${key}`).toString('base64');
    return `Basic ${encoded}`;
}

describe('Payme Controller', () => {
    let app;

    beforeAll(async () => {
        app = await buildTestServer();

        // Register Payme route
        app.post('/payme', async (request, reply) => paymeController.handle(request, reply));

        await app.ready();
    });

    afterAll(async () => {
        await closeTestServer(app);
    });

    beforeEach(() => {
        jest.clearAllMocks();
    });

    // =====================================================
    // Basic Auth tekshiruvi
    // =====================================================
    describe('Authentication', () => {
        it('should reject requests without auth header', async () => {
            const response = await app.inject({
                method: 'POST',
                url: '/payme',
                payload: {
                    method: 'CheckPerformTransaction',
                    params: {},
                    id: 1
                }
            });

            const data = JSON.parse(response.body);
            expect(data.error).toBeDefined();
            expect(data.error.code).toBe(-32504);
        });

        it('should reject requests with wrong credentials', async () => {
            const response = await app.inject({
                method: 'POST',
                url: '/payme',
                headers: { authorization: createPaymeAuth('Paycom', 'wrong-key') },
                payload: {
                    method: 'CheckPerformTransaction',
                    params: {},
                    id: 1
                }
            });

            const data = JSON.parse(response.body);
            expect(data.error).toBeDefined();
            expect(data.error.code).toBe(-32504);
        });

        it('should accept valid credentials', async () => {
            Subscription.findById.mockResolvedValue({
                _id: 'sub123',
                status: 'pending',
                price: 29900,
                plan: 'monthly'
            });

            const response = await app.inject({
                method: 'POST',
                url: '/payme',
                headers: { authorization: createPaymeAuth() },
                payload: {
                    method: 'CheckPerformTransaction',
                    params: {
                        amount: 2990000,
                        account: { order_id: 'sub123' }
                    },
                    id: 1
                }
            });

            const data = JSON.parse(response.body);
            expect(data.error).toBeUndefined();
            expect(data.result).toBeDefined();
        });
    });

    // =====================================================
    // CheckPerformTransaction
    // =====================================================
    describe('CheckPerformTransaction', () => {
        const makeRequest = (params) => ({
            method: 'POST',
            url: '/payme',
            headers: { authorization: createPaymeAuth() },
            payload: {
                method: 'CheckPerformTransaction',
                params,
                id: 1
            }
        });

        it('should return allow:true for valid order', async () => {
            Subscription.findById.mockResolvedValue({
                _id: 'sub123',
                status: 'pending',
                price: 29900,
                plan: 'monthly'
            });

            const response = await app.inject(makeRequest({
                amount: 2990000,
                account: { order_id: 'sub123' }
            }));

            const data = JSON.parse(response.body);
            expect(data.result).toBeDefined();
            expect(data.result.allow).toBe(true);
        });

        it('should return error for non-existent order', async () => {
            Subscription.findById.mockResolvedValue(null);

            const response = await app.inject(makeRequest({
                amount: 2990000,
                account: { order_id: 'nonexistent' }
            }));

            const data = JSON.parse(response.body);
            expect(data.error).toBeDefined();
            expect(data.error.code).toBe(-31050);
        });

        it('should return error for wrong amount', async () => {
            Subscription.findById.mockResolvedValue({
                _id: 'sub123',
                status: 'pending',
                price: 29900,
                plan: 'monthly'
            });

            const response = await app.inject(makeRequest({
                amount: 5000000, // Noto'g'ri summa
                account: { order_id: 'sub123' }
            }));

            const data = JSON.parse(response.body);
            expect(data.error).toBeDefined();
            expect(data.error.code).toBe(-31001);
        });

        it('should reject non-pending subscription', async () => {
            Subscription.findById.mockResolvedValue({
                _id: 'sub123',
                status: 'active', // Allaqachon faol
                price: 29900,
                plan: 'monthly'
            });

            const response = await app.inject(makeRequest({
                amount: 2990000,
                account: { order_id: 'sub123' }
            }));

            const data = JSON.parse(response.body);
            expect(data.error).toBeDefined();
            expect(data.error.code).toBe(-31008);
        });
    });

    // =====================================================
    // CreateTransaction
    // =====================================================
    describe('CreateTransaction', () => {
        const makeRequest = (params) => ({
            method: 'POST',
            url: '/payme',
            headers: { authorization: createPaymeAuth() },
            payload: {
                method: 'CreateTransaction',
                params,
                id: 2
            }
        });

        it('should create new transaction', async () => {
            PaymeTransaction.findOne
                .mockResolvedValueOnce(null) // paymeId qidiruv
                .mockResolvedValueOnce(null); // orderId uchun active tx qidiruv

            Subscription.findById.mockResolvedValue({
                _id: 'sub123',
                userId: 'user123',
                status: 'pending',
                price: 29900,
                plan: 'monthly'
            });

            const now = Date.now();
            PaymeTransaction.create.mockResolvedValue({
                _id: { toString: () => 'tx-id-1' },
                paymeId: 'payme-tx-1',
                orderId: 'sub123',
                state: 1,
                amount: 2990000,
                createTime: now
            });

            const response = await app.inject(makeRequest({
                id: 'payme-tx-1',
                time: now,
                amount: 2990000,
                account: { order_id: 'sub123' }
            }));

            const data = JSON.parse(response.body);
            expect(data.result).toBeDefined();
            expect(data.result.state).toBe(1);
            expect(data.result.create_time).toBeDefined();
            expect(data.result.transaction).toBe('tx-id-1');
        });

        it('should return existing transaction if already created', async () => {
            const existingTx = {
                _id: { toString: () => 'tx-id-existing' },
                paymeId: 'payme-tx-1',
                orderId: 'sub123',
                state: 1,
                amount: 2990000,
                createTime: Date.now()
            };
            PaymeTransaction.findOne.mockResolvedValue(existingTx);

            const response = await app.inject(makeRequest({
                id: 'payme-tx-1',
                time: Date.now(),
                amount: 2990000,
                account: { order_id: 'sub123' }
            }));

            const data = JSON.parse(response.body);
            expect(data.result).toBeDefined();
            expect(data.result.state).toBe(1);
            expect(data.result.transaction).toBe('tx-id-existing');
        });

        it('should timeout expired transaction', async () => {
            const expiredTx = {
                _id: { toString: () => 'tx-expired' },
                paymeId: 'payme-tx-old',
                orderId: 'sub123',
                state: 1,
                amount: 2990000,
                createTime: Date.now() - 50000000, // 50000 sec ago > 12 hours
                save: jest.fn().mockResolvedValue(true)
            };
            PaymeTransaction.findOne.mockResolvedValue(expiredTx);

            const response = await app.inject(makeRequest({
                id: 'payme-tx-old',
                time: Date.now(),
                amount: 2990000,
                account: { order_id: 'sub123' }
            }));

            const data = JSON.parse(response.body);
            expect(data.error).toBeDefined();
            expect(data.error.code).toBe(-31008);
            expect(expiredTx.state).toBe(-1);
            expect(expiredTx.save).toHaveBeenCalled();
        });
    });

    // =====================================================
    // PerformTransaction
    // =====================================================
    describe('PerformTransaction', () => {
        const makeRequest = (params) => ({
            method: 'POST',
            url: '/payme',
            headers: { authorization: createPaymeAuth() },
            payload: {
                method: 'PerformTransaction',
                params,
                id: 3
            }
        });

        it('should perform transaction and activate subscription', async () => {
            const mockTx = {
                _id: { toString: () => 'tx-id-perf' },
                paymeId: 'payme-tx-1',
                orderId: 'sub123',
                state: 1,
                createTime: Date.now(),
                performTime: 0,
                save: jest.fn().mockResolvedValue(true)
            };
            PaymeTransaction.findOne.mockResolvedValue(mockTx);

            const mockSub = {
                _id: 'sub123',
                status: 'pending',
                plan: 'monthly',
                endDate: new Date(),
                save: jest.fn().mockResolvedValue(true)
            };
            Subscription.findById.mockResolvedValue(mockSub);

            const response = await app.inject(makeRequest({
                id: 'payme-tx-1'
            }));

            const data = JSON.parse(response.body);
            expect(data.result).toBeDefined();
            expect(data.result.state).toBe(2);
            expect(data.result.perform_time).toBeGreaterThan(0);
            expect(mockTx.state).toBe(2);
            expect(mockTx.save).toHaveBeenCalled();
            expect(mockSub.status).toBe('active');
        });

        it('should return result for already performed transaction', async () => {
            PaymeTransaction.findOne.mockResolvedValue({
                _id: { toString: () => 'tx-id-done' },
                paymeId: 'payme-tx-1',
                state: 2,
                performTime: Date.now()
            });

            const response = await app.inject(makeRequest({
                id: 'payme-tx-1'
            }));

            const data = JSON.parse(response.body);
            expect(data.result).toBeDefined();
            expect(data.result.state).toBe(2);
        });

        it('should return error for not found transaction', async () => {
            PaymeTransaction.findOne.mockResolvedValue(null);

            const response = await app.inject(makeRequest({
                id: 'nonexistent'
            }));

            const data = JSON.parse(response.body);
            expect(data.error).toBeDefined();
            expect(data.error.code).toBe(-31003);
        });

        it('should reject non-state-1 transaction', async () => {
            PaymeTransaction.findOne.mockResolvedValue({
                _id: { toString: () => 'tx-cancelled' },
                paymeId: 'payme-tx-1',
                state: -1
            });

            const response = await app.inject(makeRequest({
                id: 'payme-tx-1'
            }));

            const data = JSON.parse(response.body);
            expect(data.error).toBeDefined();
            expect(data.error.code).toBe(-31008);
        });
    });

    // =====================================================
    // CancelTransaction
    // =====================================================
    describe('CancelTransaction', () => {
        const makeRequest = (params) => ({
            method: 'POST',
            url: '/payme',
            headers: { authorization: createPaymeAuth() },
            payload: {
                method: 'CancelTransaction',
                params,
                id: 4
            }
        });

        it('should cancel state=1 transaction', async () => {
            const mockTx = {
                _id: { toString: () => 'tx-cancel-1' },
                paymeId: 'payme-tx-1',
                orderId: 'sub123',
                state: 1,
                cancelTime: 0,
                save: jest.fn().mockResolvedValue(true)
            };
            PaymeTransaction.findOne.mockResolvedValue(mockTx);

            const mockSub = {
                _id: 'sub123',
                status: 'pending',
                save: jest.fn().mockResolvedValue(true)
            };
            Subscription.findById.mockResolvedValue(mockSub);

            const response = await app.inject(makeRequest({
                id: 'payme-tx-1',
                reason: 1
            }));

            const data = JSON.parse(response.body);
            expect(data.result).toBeDefined();
            expect(data.result.state).toBe(-1);
            expect(mockTx.state).toBe(-1);
            expect(mockSub.status).toBe('cancelled');
        });

        it('should cancel state=2 transaction (refund)', async () => {
            const mockTx = {
                _id: { toString: () => 'tx-refund-1' },
                paymeId: 'payme-tx-1',
                orderId: 'sub123',
                state: 2,
                cancelTime: 0,
                save: jest.fn().mockResolvedValue(true)
            };
            PaymeTransaction.findOne.mockResolvedValue(mockTx);

            const mockSub = {
                _id: 'sub123',
                status: 'active',
                save: jest.fn().mockResolvedValue(true)
            };
            Subscription.findById.mockResolvedValue(mockSub);

            const response = await app.inject(makeRequest({
                id: 'payme-tx-1',
                reason: 2
            }));

            const data = JSON.parse(response.body);
            expect(data.result).toBeDefined();
            expect(data.result.state).toBe(-2);
            expect(mockSub.status).toBe('cancelled');
        });

        it('should return error for not found transaction', async () => {
            PaymeTransaction.findOne.mockResolvedValue(null);

            const response = await app.inject(makeRequest({
                id: 'nonexistent',
                reason: 1
            }));

            const data = JSON.parse(response.body);
            expect(data.error).toBeDefined();
            expect(data.error.code).toBe(-31003);
        });
    });

    // =====================================================
    // CheckTransaction
    // =====================================================
    describe('CheckTransaction', () => {
        it('should return transaction status', async () => {
            PaymeTransaction.findOne.mockResolvedValue({
                _id: { toString: () => 'tx-check-1' },
                paymeId: 'payme-tx-1',
                state: 2,
                createTime: Date.now() - 10000,
                performTime: Date.now(),
                cancelTime: 0,
                reason: null
            });

            const response = await app.inject({
                method: 'POST',
                url: '/payme',
                headers: { authorization: createPaymeAuth() },
                payload: {
                    method: 'CheckTransaction',
                    params: { id: 'payme-tx-1' },
                    id: 5
                }
            });

            const data = JSON.parse(response.body);
            expect(data.result).toBeDefined();
            expect(data.result.state).toBe(2);
            expect(data.result.transaction).toBe('tx-check-1');
        });

        it('should return error for unknown transaction', async () => {
            PaymeTransaction.findOne.mockResolvedValue(null);

            const response = await app.inject({
                method: 'POST',
                url: '/payme',
                headers: { authorization: createPaymeAuth() },
                payload: {
                    method: 'CheckTransaction',
                    params: { id: 'unknown' },
                    id: 5
                }
            });

            const data = JSON.parse(response.body);
            expect(data.error).toBeDefined();
            expect(data.error.code).toBe(-31003);
        });
    });

    // =====================================================
    // GetStatement
    // =====================================================
    describe('GetStatement', () => {
        it('should return transactions in time range', async () => {
            const now = Date.now();
            PaymeTransaction.find.mockResolvedValue([
                {
                    _id: { toString: () => 'tx-stmt-1' },
                    paymeId: 'tx-1',
                    orderId: { toString: () => 'sub1' },
                    amount: 2990000,
                    state: 2,
                    createTime: now - 3600000,
                    performTime: now - 3000000,
                    cancelTime: 0,
                    reason: null
                }
            ]);

            const response = await app.inject({
                method: 'POST',
                url: '/payme',
                headers: { authorization: createPaymeAuth() },
                payload: {
                    method: 'GetStatement',
                    params: {
                        from: now - 86400000,
                        to: now
                    },
                    id: 6
                }
            });

            const data = JSON.parse(response.body);
            expect(data.result).toBeDefined();
            expect(data.result.transactions).toHaveLength(1);
            expect(data.result.transactions[0].id).toBe('tx-1');
            expect(data.result.transactions[0].state).toBe(2);
        });

        it('should return empty array for no transactions', async () => {
            PaymeTransaction.find.mockResolvedValue([]);

            const response = await app.inject({
                method: 'POST',
                url: '/payme',
                headers: { authorization: createPaymeAuth() },
                payload: {
                    method: 'GetStatement',
                    params: { from: 0, to: Date.now() },
                    id: 6
                }
            });

            const data = JSON.parse(response.body);
            expect(data.result).toBeDefined();
            expect(data.result.transactions).toHaveLength(0);
        });
    });

    // =====================================================
    // Invalid Method
    // =====================================================
    describe('Invalid Methods', () => {
        it('should return error for unknown method', async () => {
            const response = await app.inject({
                method: 'POST',
                url: '/payme',
                headers: { authorization: createPaymeAuth() },
                payload: {
                    method: 'UnknownMethod',
                    params: {},
                    id: 99
                }
            });

            const data = JSON.parse(response.body);
            expect(data.error).toBeDefined();
            expect(data.error.code).toBe(-32601);
        });
    });
});
