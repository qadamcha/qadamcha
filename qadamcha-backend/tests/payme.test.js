/**
 * Payme Subscribe API — Controller Integration Tests
 *
 * Endpointlar uchun integration testlar (payme.service mock bilan):
 * - Authentication (JWT)
 * - Input validation (TypeBox)
 * - Card CRUD (create, verify-code, verify, check, remove)
 * - Payment (pay, cancel, status)
 * - Ownership checks
 */

const { buildTestServer, closeTestServer, createTestToken } = require('./helpers/testServer');

// ============= MOCKS =============

jest.mock('../src/services/payme.service', () => ({
    createCardToken: jest.fn(),
    getVerifyCode: jest.fn(),
    verifyCard: jest.fn(),
    checkCard: jest.fn(),
    removeCard: jest.fn(),
    createReceipt: jest.fn(),
    payReceipt: jest.fn(),
    cancelReceipt: jest.fn(),
    checkReceipt: jest.fn(),
}));

jest.mock('../src/models', () => {
    return {
        PaymeTransaction: { create: jest.fn(), findOne: jest.fn() },
        Subscription: { findById: jest.fn() },
        User: jest.fn(), Child: jest.fn(), Device: jest.fn(),
        Content: jest.fn(), Activity: jest.fn(), ContentLike: jest.fn(),
    };
});

jest.mock('../src/config/env', () => ({
    PAYME_MERCHANT_ID: 'test-merchant-id',
    PAYME_KEY: 'test-key',
    PAYME_API_URL: 'https://checkout.test.paycom.uz/api',
    PLANS: {
        monthly: { price: 49000, days: 30, name: 'Oylik' },
        yearly: { price: 399000, days: 365, name: 'Yillik' },
        lifetime: { price: 990000, days: 36500, name: 'Umrbod' },
    },
}));

const paymeService = require('../src/services/payme.service');
const { PaymeTransaction, Subscription } = require('../src/models');

let app;
let authToken;
const TEST_USER_ID = '507f1f77bcf86cd799439011';
const TEST_ORDER_ID = '507f1f77bcf86cd799439022';

beforeAll(async () => {
    app = await buildTestServer();
    await app.register(require('../src/routes/payme.routes'), { prefix: '/payme' });
    await app.ready();
    authToken = createTestToken(app, { userId: TEST_USER_ID });
});

afterAll(async () => {
    await closeTestServer(app);
});

beforeEach(() => {
    jest.clearAllMocks();
});

// ============= AUTHENTICATION =============

describe('Autentifikatsiya', () => {
    test('JWT tokensiz — 401', async () => {
        const res = await app.inject({
            method: 'POST', url: '/payme/card/create',
            payload: { cardNumber: '8600069195406311', expire: '0399' },
        });
        expect(res.statusCode).toBe(401);
    });

    test('Noto\'g\'ri JWT — 401', async () => {
        const res = await app.inject({
            method: 'POST', url: '/payme/card/create',
            payload: { cardNumber: '8600069195406311', expire: '0399' },
            headers: { Authorization: 'Bearer invalid' },
        });
        expect(res.statusCode).toBe(401);
    });

    test('Barcha endpointlar JWT talab qiladi', async () => {
        const endpoints = [
            { method: 'POST', url: '/payme/card/create', payload: { cardNumber: '8600069195406311', expire: '0399' } },
            { method: 'POST', url: '/payme/card/verify-code', payload: { token: 'x' } },
            { method: 'POST', url: '/payme/card/verify', payload: { token: 'x', code: '666666' } },
            { method: 'POST', url: '/payme/card/check', payload: { token: 'x' } },
            { method: 'DELETE', url: '/payme/card/test' },
            { method: 'POST', url: '/payme/pay', payload: { orderId: 'x', token: 'x' } },
            { method: 'POST', url: '/payme/cancel', payload: { orderId: 'x' } },
            { method: 'GET', url: '/payme/status/test' },
        ];
        for (const ep of endpoints) {
            const res = await app.inject(ep);
            expect(res.statusCode).toBe(401);
        }
    });
});

// ============= INPUT VALIDATION =============

describe('Input validatsiyasi', () => {
    test('Karta raqami qisqa — 400', async () => {
        const res = await app.inject({
            method: 'POST', url: '/payme/card/create',
            payload: { cardNumber: '1234', expire: '0399' },
            headers: { Authorization: `Bearer ${authToken}` },
        });
        expect(res.statusCode).toBe(400);
    });

    test('Karta raqami harflar bilan — 400', async () => {
        const res = await app.inject({
            method: 'POST', url: '/payme/card/create',
            payload: { cardNumber: '8600abcd95406311', expire: '0399' },
            headers: { Authorization: `Bearer ${authToken}` },
        });
        expect(res.statusCode).toBe(400);
    });

    test('Expire qisqa — 400', async () => {
        const res = await app.inject({
            method: 'POST', url: '/payme/card/create',
            payload: { cardNumber: '8600069195406311', expire: '03' },
            headers: { Authorization: `Bearer ${authToken}` },
        });
        expect(res.statusCode).toBe(400);
    });

    test('SMS kod 6 dan kam — 400', async () => {
        const res = await app.inject({
            method: 'POST', url: '/payme/card/verify',
            payload: { token: 'test', code: '12' },
            headers: { Authorization: `Bearer ${authToken}` },
        });
        expect(res.statusCode).toBe(400);
    });

    test('SMS kod harflar bilan — 400', async () => {
        const res = await app.inject({
            method: 'POST', url: '/payme/card/verify',
            payload: { token: 'test', code: 'abcdef' },
            headers: { Authorization: `Bearer ${authToken}` },
        });
        expect(res.statusCode).toBe(400);
    });

    test('Pay — token yo\'q — 400', async () => {
        const res = await app.inject({
            method: 'POST', url: '/payme/pay',
            payload: { orderId: 'test-id' },
            headers: { Authorization: `Bearer ${authToken}` },
        });
        expect(res.statusCode).toBe(400);
    });
});

// ============= CARD ENDPOINTS =============

describe('POST /payme/card/create', () => {
    test('Muvaffaqiyatli', async () => {
        paymeService.createCardToken.mockResolvedValue({
            token: 'test-token',
            card: { number: '860006******6311', expire: '03/99', type: 'uzcard', recurrent: true, verify: false },
        });

        const res = await app.inject({
            method: 'POST', url: '/payme/card/create',
            payload: { cardNumber: '8600069195406311', expire: '0399' },
            headers: { Authorization: `Bearer ${authToken}` },
        });

        const body = JSON.parse(res.body);
        expect(res.statusCode).toBe(200);
        expect(body.success).toBe(true);
        expect(body.token).toBe('test-token');
        expect(body.card.number).toBe('860006******6311');
        expect(paymeService.createCardToken).toHaveBeenCalledWith('8600069195406311', '0399');
    });

    test('Payme xatosi — 400', async () => {
        paymeService.createCardToken.mockRejectedValue(
            Object.assign(new Error('Karta noto\'g\'ri'), { code: -31300 })
        );

        const res = await app.inject({
            method: 'POST', url: '/payme/card/create',
            payload: { cardNumber: '8600069195406311', expire: '0399' },
            headers: { Authorization: `Bearer ${authToken}` },
        });

        const body = JSON.parse(res.body);
        expect(res.statusCode).toBe(400);
        expect(body.code).toBe(-31300);
    });
});

describe('POST /payme/card/verify-code', () => {
    test('Muvaffaqiyatli SMS', async () => {
        paymeService.getVerifyCode.mockResolvedValue({ sent: true, phone: '99890*****12', wait: 60 });

        const res = await app.inject({
            method: 'POST', url: '/payme/card/verify-code',
            payload: { token: 'test-token' },
            headers: { Authorization: `Bearer ${authToken}` },
        });

        const body = JSON.parse(res.body);
        expect(res.statusCode).toBe(200);
        expect(body.sent).toBe(true);
        expect(body.wait).toBe(60);
    });
});

describe('POST /payme/card/verify', () => {
    test('Muvaffaqiyatli tasdiqlash', async () => {
        paymeService.verifyCard.mockResolvedValue({
            verified: true,
            card: { number: '860006******6311', expire: '03/99', token: 'v-token', recurrent: true, type: 'uzcard' },
        });

        const res = await app.inject({
            method: 'POST', url: '/payme/card/verify',
            payload: { token: 'test-token', code: '666666' },
            headers: { Authorization: `Bearer ${authToken}` },
        });

        const body = JSON.parse(res.body);
        expect(res.statusCode).toBe(200);
        expect(body.verified).toBe(true);
    });
});

describe('POST /payme/card/check', () => {
    test('Tasdiqlangan karta', async () => {
        paymeService.checkCard.mockResolvedValue({
            verified: true,
            card: { number: '860006******6311', expire: '03/99', type: 'uzcard', recurrent: true },
        });

        const res = await app.inject({
            method: 'POST', url: '/payme/card/check',
            payload: { token: 'test-token' },
            headers: { Authorization: `Bearer ${authToken}` },
        });

        expect(JSON.parse(res.body).verified).toBe(true);
    });
});

describe('DELETE /payme/card/:token', () => {
    test('Karta o\'chirildi', async () => {
        paymeService.removeCard.mockResolvedValue({ success: true });

        const res = await app.inject({
            method: 'DELETE', url: '/payme/card/test-token',
            headers: { Authorization: `Bearer ${authToken}` },
        });

        expect(JSON.parse(res.body).success).toBe(true);
    });
});

// ============= PAYMENT ENDPOINT =============

describe('POST /payme/pay', () => {
    const mockOrder = {
        _id: TEST_ORDER_ID,
        userId: { toString: () => TEST_USER_ID },
        status: 'pending', plan: 'monthly', price: 49000,
        paymentMethod: null, transactionId: null,
        startDate: null, endDate: new Date(),
        save: jest.fn(),
    };

    test('Muvaffaqiyatli to\'lov', async () => {
        const save = jest.fn();
        Subscription.findById.mockResolvedValue({ ...mockOrder, save });
        paymeService.createReceipt.mockResolvedValue({ receiptId: 'r-123', state: 0 });
        paymeService.payReceipt.mockResolvedValue({ receiptId: 'r-123', state: 4 });
        PaymeTransaction.create.mockResolvedValue({
            _id: { toString: () => 'tx-123' }, receiptId: 'r-123', state: 4, amount: 4900000,
        });

        const res = await app.inject({
            method: 'POST', url: '/payme/pay',
            payload: { orderId: TEST_ORDER_ID, token: 'card-token' },
            headers: { Authorization: `Bearer ${authToken}` },
        });

        const body = JSON.parse(res.body);
        expect(res.statusCode).toBe(200);
        expect(body.success).toBe(true);
        expect(body.subscription.status).toBe('active');
        expect(paymeService.createReceipt).toHaveBeenCalledWith(4900000, TEST_ORDER_ID);
        expect(paymeService.payReceipt).toHaveBeenCalledWith('r-123', 'card-token');
        expect(save).toHaveBeenCalled();
    });

    test('Buyurtma topilmadi — 404', async () => {
        Subscription.findById.mockResolvedValue(null);
        const res = await app.inject({
            method: 'POST', url: '/payme/pay',
            payload: { orderId: 'none', token: 'x' },
            headers: { Authorization: `Bearer ${authToken}` },
        });
        expect(res.statusCode).toBe(404);
    });

    test('Boshqa foydalanuvchi — 403', async () => {
        Subscription.findById.mockResolvedValue({
            ...mockOrder, userId: { toString: () => 'other' },
        });
        const res = await app.inject({
            method: 'POST', url: '/payme/pay',
            payload: { orderId: TEST_ORDER_ID, token: 'x' },
            headers: { Authorization: `Bearer ${authToken}` },
        });
        expect(res.statusCode).toBe(403);
        expect(paymeService.createReceipt).not.toHaveBeenCalled();
    });

    test('Allaqachon active — 400', async () => {
        Subscription.findById.mockResolvedValue({ ...mockOrder, status: 'active' });
        const res = await app.inject({
            method: 'POST', url: '/payme/pay',
            payload: { orderId: TEST_ORDER_ID, token: 'x' },
            headers: { Authorization: `Bearer ${authToken}` },
        });
        expect(res.statusCode).toBe(400);
    });

    test('Mablag\' yetarli emas — 400 (-31008)', async () => {
        Subscription.findById.mockResolvedValue({ ...mockOrder, save: jest.fn() });
        paymeService.createReceipt.mockResolvedValue({ receiptId: 'r-456', state: 0 });
        paymeService.payReceipt.mockRejectedValue(
            Object.assign(new Error('Insufficient'), { code: -31008 })
        );

        const res = await app.inject({
            method: 'POST', url: '/payme/pay',
            payload: { orderId: TEST_ORDER_ID, token: 'x' },
            headers: { Authorization: `Bearer ${authToken}` },
        });

        expect(res.statusCode).toBe(400);
        expect(JSON.parse(res.body).code).toBe(-31008);
    });
});

// ============= CANCEL =============

describe('POST /payme/cancel', () => {
    test('Muvaffaqiyatli bekor qilish', async () => {
        const txSave = jest.fn();
        PaymeTransaction.findOne.mockResolvedValue({
            _id: 'tx-1', receiptId: 'r-1', orderId: TEST_ORDER_ID,
            userId: TEST_USER_ID, state: 4, cancelTime: 0, save: txSave,
        });
        paymeService.cancelReceipt.mockResolvedValue({ receiptId: 'r-1', state: 50 });

        const orderSave = jest.fn();
        Subscription.findById.mockResolvedValue({
            status: 'active', cancelledAt: null, cancelReason: null, save: orderSave,
        });

        const res = await app.inject({
            method: 'POST', url: '/payme/cancel',
            payload: { orderId: TEST_ORDER_ID },
            headers: { Authorization: `Bearer ${authToken}` },
        });

        const body = JSON.parse(res.body);
        expect(res.statusCode).toBe(200);
        expect(body.state).toBe(50);
        expect(txSave).toHaveBeenCalled();
        expect(orderSave).toHaveBeenCalled();
    });

    test('Tranzaksiya topilmadi — 404', async () => {
        PaymeTransaction.findOne.mockResolvedValue(null);
        const res = await app.inject({
            method: 'POST', url: '/payme/cancel',
            payload: { orderId: TEST_ORDER_ID },
            headers: { Authorization: `Bearer ${authToken}` },
        });
        expect(res.statusCode).toBe(404);
    });
});

// ============= STATUS =============

describe('GET /payme/status/:orderId', () => {
    test('To\'langan — Payme dan real-time check', async () => {
        const tx = {
            _id: { toString: () => 'tx-1' }, receiptId: 'r-1', state: 4,
            amount: 4900000, createTime: Date.now(), performTime: Date.now(),
            save: jest.fn(),
        };
        PaymeTransaction.findOne.mockReturnValue({ sort: jest.fn().mockResolvedValue(tx) });
        paymeService.checkReceipt.mockResolvedValue({ receiptId: 'r-1', state: 4 });
        Subscription.findById.mockResolvedValue({
            plan: 'monthly', status: 'active', startDate: new Date(), endDate: new Date(),
        });

        const res = await app.inject({
            method: 'GET', url: `/payme/status/${TEST_ORDER_ID}`,
            headers: { Authorization: `Bearer ${authToken}` },
        });

        const body = JSON.parse(res.body);
        expect(body.paid).toBe(true);
        expect(body.state).toBe(4);
    });

    test('Tranzaksiya yo\'q — paid: false', async () => {
        PaymeTransaction.findOne.mockReturnValue({ sort: jest.fn().mockResolvedValue(null) });

        const res = await app.inject({
            method: 'GET', url: `/payme/status/${TEST_ORDER_ID}`,
            headers: { Authorization: `Bearer ${authToken}` },
        });

        expect(JSON.parse(res.body).paid).toBe(false);
    });

    test('Payme API xatosi — graceful degradation', async () => {
        const tx = {
            _id: { toString: () => 'tx-1' }, receiptId: 'r-1', state: 4,
            amount: 4900000, createTime: Date.now(), performTime: Date.now(),
            save: jest.fn(),
        };
        PaymeTransaction.findOne.mockReturnValue({ sort: jest.fn().mockResolvedValue(tx) });
        paymeService.checkReceipt.mockRejectedValue(new Error('Network error'));
        Subscription.findById.mockResolvedValue({
            plan: 'monthly', status: 'active', startDate: new Date(), endDate: new Date(),
        });

        const res = await app.inject({
            method: 'GET', url: `/payme/status/${TEST_ORDER_ID}`,
            headers: { Authorization: `Bearer ${authToken}` },
        });

        // Xato bo'lsa ham lokal holat qaytariladi
        const body = JSON.parse(res.body);
        expect(body.paid).toBe(true);
        expect(body.state).toBe(4);
    });
});
