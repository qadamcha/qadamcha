/**
 * Payme Subscribe API — Service Unit Tests
 * 
 * payme.service.js ni bevosita test qiladi (axios mock bilan).
 * 
 * Rasmiy dokumentatsiya bo'yicha tekshiruvlar:
 * - X-Auth header formati (cards=ID, receipts=ID:KEY)
 * - JSON-RPC 2.0 format
 * - Receipt javob formati (result.receipt._id)
 * - Payer object (receipts.pay)
 * - Error handling & error code tarjimalari
 */

jest.mock('axios');
const axios = require('axios');

jest.mock('../src/config/env', () => ({
    PAYME_MERCHANT_ID: 'test-merchant-id',
    PAYME_KEY: 'test-secret-key',
    PAYME_API_URL: 'https://checkout.test.paycom.uz/api',
}));

const paymeService = require('../src/services/payme.service');

beforeEach(() => {
    jest.clearAllMocks();
});

// ============= X-Auth FORMAT TESTS =============

describe('X-Auth header formati (rasmiy docs)', () => {

    test('cards.create — X-Auth faqat MERCHANT_ID', async () => {
        axios.post.mockResolvedValue({
            data: {
                result: {
                    card: {
                        number: '860006******6311', expire: '03/99',
                        token: 'test-token', recurrent: true, verify: false, type: 'uzcard',
                    },
                },
            },
        });

        await paymeService.createCardToken('8600069195406311', '0399');
        expect(axios.post.mock.calls[0][2].headers['X-Auth']).toBe('test-merchant-id');
    });

    test('cards.get_verify_code — X-Auth faqat MERCHANT_ID', async () => {
        axios.post.mockResolvedValue({
            data: { result: { sent: true, phone: '99890*****12', wait: 60 } },
        });

        await paymeService.getVerifyCode('test-token');
        expect(axios.post.mock.calls[0][2].headers['X-Auth']).toBe('test-merchant-id');
    });

    test('cards.verify — X-Auth faqat MERCHANT_ID', async () => {
        axios.post.mockResolvedValue({
            data: {
                result: {
                    card: {
                        number: '860006******6311', expire: '03/99',
                        token: 'v-token', recurrent: true, verify: true, type: 'uzcard',
                    },
                },
            },
        });

        await paymeService.verifyCard('test-token', '666666');
        expect(axios.post.mock.calls[0][2].headers['X-Auth']).toBe('test-merchant-id');
    });

    test('cards.check — X-Auth faqat MERCHANT_ID', async () => {
        axios.post.mockResolvedValue({
            data: {
                result: {
                    card: {
                        number: '860006******6311', expire: '03/99',
                        verify: true, recurrent: true, type: 'uzcard',
                    },
                },
            },
        });

        await paymeService.checkCard('test-token');
        expect(axios.post.mock.calls[0][2].headers['X-Auth']).toBe('test-merchant-id');
    });

    test('cards.remove — X-Auth faqat MERCHANT_ID', async () => {
        axios.post.mockResolvedValue({ data: { result: { success: true } } });

        await paymeService.removeCard('test-token');
        expect(axios.post.mock.calls[0][2].headers['X-Auth']).toBe('test-merchant-id');
    });

    test('receipts.create — X-Auth = ID:KEY', async () => {
        axios.post.mockResolvedValue({
            data: { result: { receipt: { _id: 'r-123', state: 0 } } },
        });

        await paymeService.createReceipt(500000, 'order-1');
        expect(axios.post.mock.calls[0][2].headers['X-Auth']).toBe('test-merchant-id:test-secret-key');
    });

    test('receipts.pay — X-Auth = ID:KEY', async () => {
        axios.post.mockResolvedValue({
            data: { result: { receipt: { _id: 'r-123', state: 4 } } },
        });

        await paymeService.payReceipt('r-123', 'card-token');
        expect(axios.post.mock.calls[0][2].headers['X-Auth']).toBe('test-merchant-id:test-secret-key');
    });

    test('receipts.cancel — X-Auth = ID:KEY', async () => {
        axios.post.mockResolvedValue({
            data: { result: { receipt: { _id: 'r-123', state: 50 } } },
        });

        await paymeService.cancelReceipt('r-123');
        expect(axios.post.mock.calls[0][2].headers['X-Auth']).toBe('test-merchant-id:test-secret-key');
    });

    test('receipts.check — X-Auth = ID:KEY', async () => {
        axios.post.mockResolvedValue({
            data: { result: { receipt: { _id: 'r-123', state: 4 } } },
        });

        await paymeService.checkReceipt('r-123');
        expect(axios.post.mock.calls[0][2].headers['X-Auth']).toBe('test-merchant-id:test-secret-key');
    });
});

// ============= JSON-RPC FORMAT TESTS =============

describe('JSON-RPC 2.0 format', () => {

    test('cards.create — to\'g\'ri JSON-RPC payload', async () => {
        axios.post.mockResolvedValue({
            data: {
                result: {
                    card: {
                        number: '860006******6311', expire: '03/99',
                        token: 'test-token', recurrent: true, verify: false, type: 'uzcard',
                    },
                },
            },
        });

        await paymeService.createCardToken('8600069195406311', '0399');

        const [url, payload, options] = axios.post.mock.calls[0];
        expect(url).toBe('https://checkout.test.paycom.uz/api');
        expect(payload).toHaveProperty('id');
        expect(payload.method).toBe('cards.create');
        expect(payload.params).toEqual({
            card: { number: '8600069195406311', expire: '0399' },
            save: true,
        });
        expect(options.headers['Content-Type']).toBe('application/json');
        expect(options.headers['Cache-Control']).toBe('no-cache');
    });

    test('receipts.create — description va account yuboriladi', async () => {
        axios.post.mockResolvedValue({
            data: { result: { receipt: { _id: 'r-123', state: 0 } } },
        });

        await paymeService.createReceipt(500000, 'order-1');

        const payload = axios.post.mock.calls[0][1];
        expect(payload.method).toBe('receipts.create');
        expect(payload.params.amount).toBe(500000);
        expect(payload.params.account.order_id).toBe('order-1');
        expect(payload.params.description).toBeDefined();
    });

    test('receipts.pay — payer object yuboriladi', async () => {
        axios.post.mockResolvedValue({
            data: { result: { receipt: { _id: 'r-123', state: 4 } } },
        });

        await paymeService.payReceipt('r-123', 'card-token', { phone: '998901234567' });

        const payload = axios.post.mock.calls[0][1];
        expect(payload.params.payer).toEqual({ phone: '998901234567' });
    });

    test('receipts.pay — payer bo\'lmasa ham ishlaydi', async () => {
        axios.post.mockResolvedValue({
            data: { result: { receipt: { _id: 'r-123', state: 4 } } },
        });

        await paymeService.payReceipt('r-123', 'card-token');

        const payload = axios.post.mock.calls[0][1];
        expect(payload.params.payer).toBeUndefined();
    });
});

// ============= RECEIPT RESPONSE PARSING TESTS =============

describe('Receipt javob formati (result.receipt._id)', () => {

    test('receipts.create — result.receipt._id dan receiptId olinadi', async () => {
        axios.post.mockResolvedValue({
            data: {
                result: {
                    receipt: {
                        _id: '62da73b0803aced907a52b46',
                        state: 0,
                        create_time: 1658483632482,
                    },
                },
            },
        });

        const result = await paymeService.createReceipt(500000, 'test-order');
        expect(result.receiptId).toBe('62da73b0803aced907a52b46');
        expect(result.state).toBe(0);
    });

    test('receipts.pay — state 4 (to\'langan)', async () => {
        axios.post.mockResolvedValue({
            data: {
                result: {
                    receipt: {
                        _id: '2e0b1bc1f1eb50d487ba268d',
                        state: 4,
                        pay_time: 1481113810265,
                    },
                },
            },
        });

        const result = await paymeService.payReceipt('2e0b1bc1f1eb50d487ba268d', 'test-token');
        expect(result.receiptId).toBe('2e0b1bc1f1eb50d487ba268d');
        expect(result.state).toBe(4);
    });

    test('receipts.cancel — state 50 (bekor qilingan)', async () => {
        axios.post.mockResolvedValue({
            data: {
                result: { receipt: { _id: 'cancel-id', state: 50 } },
            },
        });

        const result = await paymeService.cancelReceipt('cancel-id');
        expect(result.receiptId).toBe('cancel-id');
        expect(result.state).toBe(50);
    });
});

// ============= CARD RESPONSE PARSING =============

describe('Card response parsing', () => {

    test('createCardToken — verify holati qaytariladi', async () => {
        axios.post.mockResolvedValue({
            data: {
                jsonrpc: '2.0',
                id: 123,
                result: {
                    card: {
                        number: '860006******6311',
                        expire: '03/99',
                        token: 'long-token-string',
                        recurrent: true,
                        verify: false,
                        type: 'uzcard',
                    },
                },
            },
        });

        const result = await paymeService.createCardToken('8600069195406311', '0399');
        expect(result.token).toBe('long-token-string');
        expect(result.card.number).toBe('860006******6311');
        expect(result.card.verify).toBe(false);
        expect(result.card.type).toBe('uzcard');
    });
});

// ============= ERROR HANDLING TESTS =============

describe('Xatolar bilan ishlash', () => {

    test('Payme API xatosi — error code va paymeData qaytariladi', async () => {
        axios.post.mockResolvedValue({
            data: {
                error: { code: -31300, message: 'Invalid card number', data: 'card.number' },
            },
        });

        try {
            await paymeService.createCardToken('1234', '0399');
            fail('Expected error');
        } catch (err) {
            expect(err.code).toBe(-31300);
            expect(err.paymeData).toBe('card.number');
        }
    });

    test('Network timeout xatosi', async () => {
        axios.post.mockRejectedValue(new Error('timeout of 30000ms exceeded'));

        try {
            await paymeService.createCardToken('8600069195406311', '0399');
            fail('Expected error');
        } catch (err) {
            expect(err.message).toContain('timeout');
        }
    });

    test('HTTP 500 xatosi', async () => {
        axios.post.mockRejectedValue({
            response: { status: 500, data: { error: { message: 'Internal error' } } },
            message: 'Request failed',
        });

        try {
            await paymeService.createCardToken('8600069195406311', '0399');
            fail('Expected error');
        } catch (err) {
            expect(err.code).toBe(500);
        }
    });

    test('SMS kod noto\'g\'ri — o\'zbekcha xabar (-31304)', async () => {
        axios.post.mockResolvedValue({
            data: { error: { code: -31304, message: 'SMS code is incorrect' } },
        });

        try {
            await paymeService.verifyCard('test-token', '123456');
            fail('Expected error');
        } catch (err) {
            expect(err.code).toBe(-31304);
            expect(err.message).toContain('SMS kod noto\'g\'ri');
        }
    });

    test('Mablag\' yetarli emas — o\'zbekcha xabar (-31008)', async () => {
        axios.post.mockResolvedValue({
            data: { error: { code: -31008, message: 'Insufficient funds' } },
        });

        try {
            await paymeService.payReceipt('r-123', 't-123');
            fail('Expected error');
        } catch (err) {
            expect(err.code).toBe(-31008);
            expect(err.message).toContain('mablag\' yetarli emas');
        }
    });

    test('Avtorizatsiya xatosi — o\'zbekcha xabar (-32504)', async () => {
        axios.post.mockResolvedValue({
            data: { error: { code: -32504, message: 'Authorization required' } },
        });

        try {
            await paymeService.createCardToken('8600069195406311', '0399');
            fail('Expected error');
        } catch (err) {
            expect(err.code).toBe(-32504);
            expect(err.message).toContain('avtorizatsiya');
        }
    });
});
