/**
 * AI Controller Fixes Tests
 * Tests for: #20 AI tips age validation
 */

const { buildTestServer, closeTestServer, createTestToken } = require('./helpers/testServer');

// Mock AI service
jest.mock('../src/services/ai.service', () => ({
    getQuickTips: jest.fn((age) => {
        if (age <= 5) return ['Tip 3-5 yosh'];
        if (age <= 8) return ['Tip 6-8 yosh'];
        return ['Tip 9-12 yosh'];
    }),
    chat: jest.fn(),
    getStatus: jest.fn(() => ({ configured: true, model: 'test' }))
}));

jest.mock('../src/models', () => ({
    Child: {
        findOne: jest.fn()
    }
}));

const aiService = require('../src/services/ai.service');

describe('AI Controller Fixes', () => {
    let app;
    let token;

    beforeAll(async () => {
        app = await buildTestServer();

        // Register AI routes
        const aiRoutes = require('../src/routes/ai.routes');
        await app.register(aiRoutes, { prefix: '/ai' });

        await app.ready();
        token = createTestToken(app, { userId: 'user-123', deviceId: 'device-123' });
    });

    afterAll(async () => {
        await closeTestServer(app);
    });

    beforeEach(() => {
        jest.clearAllMocks();
    });

    // ============================================================
    // #20 — AI tips age validation
    // ============================================================
    describe('#20: GET /ai/tips age validation', () => {
        it('should return tips for valid age (5)', async () => {
            const response = await app.inject({
                method: 'GET',
                url: '/ai/tips?age=5',
                headers: { authorization: `Bearer ${token}` }
            });

            const data = JSON.parse(response.body);
            expect(response.statusCode).toBe(200);
            expect(data.success).toBe(true);
            expect(data.tips).toBeDefined();
            expect(aiService.getQuickTips).toHaveBeenCalledWith(5);
        });

        it('should return tips for edge case age (1)', async () => {
            const response = await app.inject({
                method: 'GET',
                url: '/ai/tips?age=1',
                headers: { authorization: `Bearer ${token}` }
            });

            expect(response.statusCode).toBe(200);
            expect(aiService.getQuickTips).toHaveBeenCalledWith(1);
        });

        it('should return tips for edge case age (18)', async () => {
            const response = await app.inject({
                method: 'GET',
                url: '/ai/tips?age=18',
                headers: { authorization: `Bearer ${token}` }
            });

            expect(response.statusCode).toBe(200);
            expect(aiService.getQuickTips).toHaveBeenCalledWith(18);
        });

        it('should reject age below 1', async () => {
            const response = await app.inject({
                method: 'GET',
                url: '/ai/tips?age=0',
                headers: { authorization: `Bearer ${token}` }
            });

            expect(response.statusCode).toBe(400);
            const data = JSON.parse(response.body);
            expect(data.success).toBe(false);
            expect(data.message).toContain('1-18');
        });

        it('should reject negative age', async () => {
            const response = await app.inject({
                method: 'GET',
                url: '/ai/tips?age=-5',
                headers: { authorization: `Bearer ${token}` }
            });

            expect(response.statusCode).toBe(400);
        });

        it('should reject age above 18', async () => {
            const response = await app.inject({
                method: 'GET',
                url: '/ai/tips?age=19',
                headers: { authorization: `Bearer ${token}` }
            });

            expect(response.statusCode).toBe(400);
            const data = JSON.parse(response.body);
            expect(data.message).toContain('1-18');
        });

        it('should reject non-numeric age', async () => {
            const response = await app.inject({
                method: 'GET',
                url: '/ai/tips?age=abc',
                headers: { authorization: `Bearer ${token}` }
            });

            expect(response.statusCode).toBe(400);
        });

        it('should reject missing age parameter', async () => {
            const response = await app.inject({
                method: 'GET',
                url: '/ai/tips',
                headers: { authorization: `Bearer ${token}` }
            });

            expect(response.statusCode).toBe(400);
        });
    });
});
