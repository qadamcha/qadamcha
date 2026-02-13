/**
 * Children Controller Fixes Tests
 * Tests for: #13 PUT schema validation, #15 activities validation, #16 Promise.all error handling
 */

const { buildTestServer, closeTestServer, createTestToken } = require('./helpers/testServer');

// Mock models
jest.mock('../src/models', () => ({
    Child: {
        find: jest.fn(),
        findOne: jest.fn(),
        findOneAndUpdate: jest.fn(),
        create: jest.fn(),
        countDocuments: jest.fn()
    },
    Activity: {
        find: jest.fn(),
        getDailyStats: jest.fn(),
        getWeeklyStats: jest.fn()
    }
}));

jest.mock('../src/config/constants', () => ({
    ERRORS: {
        NOT_FOUND: 'Topilmadi',
        FORBIDDEN: 'Ruxsat yo\'q'
    },
    SUCCESS: {
        UPDATED: 'Muvaffaqiyatli yangilandi',
        DELETED: 'Muvaffaqiyatli o\'chirildi'
    }
}));

const { Child, Activity } = require('../src/models');

describe('Children Controller Fixes', () => {
    let app;
    let token;

    beforeAll(async () => {
        app = await buildTestServer();

        // Register children routes
        const childrenRoutes = require('../src/routes/children.routes');
        await app.register(childrenRoutes, { prefix: '/children' });

        await app.ready();
        token = createTestToken(app, { userId: 'parent-123', deviceId: 'device-123' });
    });

    afterAll(async () => {
        await closeTestServer(app);
    });

    beforeEach(() => {
        jest.clearAllMocks();
    });

    // ============================================================
    // #13 — PUT /children/:id schema validation
    // ============================================================
    describe('#13: PUT /children/:id schema validation', () => {
        it('should accept valid update data', async () => {
            Child.findOneAndUpdate.mockResolvedValue({
                _id: 'child-1',
                name: 'Yangi Ism',
                age: 7,
                parentId: 'parent-123'
            });

            const response = await app.inject({
                method: 'PUT',
                url: '/children/child-1',
                headers: { authorization: `Bearer ${token}` },
                payload: { name: 'Yangi Ism', age: 7 }
            });

            expect(response.statusCode).toBe(200);
            const data = JSON.parse(response.body);
            expect(data.success).toBe(true);
        });

        it('should reject name shorter than 2 characters', async () => {
            const response = await app.inject({
                method: 'PUT',
                url: '/children/child-1',
                headers: { authorization: `Bearer ${token}` },
                payload: { name: 'A' }
            });

            expect(response.statusCode).toBe(400);
        });

        it('should reject name longer than 30 characters', async () => {
            const response = await app.inject({
                method: 'PUT',
                url: '/children/child-1',
                headers: { authorization: `Bearer ${token}` },
                payload: { name: 'A'.repeat(31) }
            });

            expect(response.statusCode).toBe(400);
        });

        it('should reject age below 1', async () => {
            const response = await app.inject({
                method: 'PUT',
                url: '/children/child-1',
                headers: { authorization: `Bearer ${token}` },
                payload: { age: 0 }
            });

            expect(response.statusCode).toBe(400);
        });

        it('should reject age above 18', async () => {
            const response = await app.inject({
                method: 'PUT',
                url: '/children/child-1',
                headers: { authorization: `Bearer ${token}` },
                payload: { age: 19 }
            });

            expect(response.statusCode).toBe(400);
        });

        it('should reject invalid gender value', async () => {
            const response = await app.inject({
                method: 'PUT',
                url: '/children/child-1',
                headers: { authorization: `Bearer ${token}` },
                payload: { gender: 'invalid' }
            });

            expect(response.statusCode).toBe(400);
        });

        it('should reject dailyLimit below 5', async () => {
            const response = await app.inject({
                method: 'PUT',
                url: '/children/child-1',
                headers: { authorization: `Bearer ${token}` },
                payload: { dailyLimit: 2 }
            });

            expect(response.statusCode).toBe(400);
        });

        it('should reject dailyLimit above 480', async () => {
            const response = await app.inject({
                method: 'PUT',
                url: '/children/child-1',
                headers: { authorization: `Bearer ${token}` },
                payload: { dailyLimit: 500 }
            });

            expect(response.statusCode).toBe(400);
        });

        it('should accept valid gender values', async () => {
            Child.findOneAndUpdate.mockResolvedValue({
                _id: 'child-1',
                gender: 'female',
                parentId: 'parent-123'
            });

            const response = await app.inject({
                method: 'PUT',
                url: '/children/child-1',
                headers: { authorization: `Bearer ${token}` },
                payload: { gender: 'female' }
            });

            expect(response.statusCode).toBe(200);
        });
    });

    // ============================================================
    // #15 — Activities endpoint validation
    // ============================================================
    describe('#15: GET /children/:id/activities validation', () => {
        const mockChild = {
            _id: 'child-1',
            parentId: 'parent-123',
            name: 'Ali',
            age: 5
        };

        beforeEach(() => {
            Child.findOne.mockResolvedValue(mockChild);
            Activity.find.mockReturnValue({
                sort: jest.fn().mockReturnValue({
                    limit: jest.fn().mockResolvedValue([])
                })
            });
        });

        it('should accept valid date format (YYYY-MM-DD)', async () => {
            const response = await app.inject({
                method: 'GET',
                url: '/children/child-1/activities?date=2026-02-09',
                headers: { authorization: `Bearer ${token}` }
            });

            expect(response.statusCode).toBe(200);
        });

        it('should reject invalid date format', async () => {
            const response = await app.inject({
                method: 'GET',
                url: '/children/child-1/activities?date=02-09-2026',
                headers: { authorization: `Bearer ${token}` }
            });

            expect(response.statusCode).toBe(400);
            const data = JSON.parse(response.body);
            expect(data.message).toContain('YYYY-MM-DD');
        });

        it('should reject date with invalid characters', async () => {
            const response = await app.inject({
                method: 'GET',
                url: '/children/child-1/activities?date=abcd-ef-gh',
                headers: { authorization: `Bearer ${token}` }
            });

            expect(response.statusCode).toBe(400);
        });

        it('should cap limit at 500', async () => {
            const response = await app.inject({
                method: 'GET',
                url: '/children/child-1/activities?limit=1000',
                headers: { authorization: `Bearer ${token}` }
            });

            expect(response.statusCode).toBe(200);
            // Verify that limit was capped — Activity.find().sort().limit() called with 500
            const findMock = Activity.find.mock.results[0].value;
            const sortMock = findMock.sort.mock.results[0].value;
            expect(sortMock.limit).toHaveBeenCalledWith(500);
        });

        it('should default limit to 50', async () => {
            const response = await app.inject({
                method: 'GET',
                url: '/children/child-1/activities',
                headers: { authorization: `Bearer ${token}` }
            });

            expect(response.statusCode).toBe(200);
            const findMock = Activity.find.mock.results[0].value;
            const sortMock = findMock.sort.mock.results[0].value;
            expect(sortMock.limit).toHaveBeenCalledWith(50);
        });

        it('should enforce minimum limit of 1', async () => {
            const response = await app.inject({
                method: 'GET',
                url: '/children/child-1/activities?limit=-5',
                headers: { authorization: `Bearer ${token}` }
            });

            expect(response.statusCode).toBe(200);
            const findMock = Activity.find.mock.results[0].value;
            const sortMock = findMock.sort.mock.results[0].value;
            expect(sortMock.limit).toHaveBeenCalledWith(1);
        });
    });

    // ============================================================
    // #16 — Promise.all error handling in GET /children
    // ============================================================
    describe('#16: GET /children Promise.all graceful fallback', () => {
        it('should return children even when stats fail for one child', async () => {
            const mockChildren = [
                { _id: 'child-1', name: 'Ali', dailyLimit: 60, toObject: () => ({ _id: 'child-1', name: 'Ali', dailyLimit: 60 }) },
                { _id: 'child-2', name: 'Vali', dailyLimit: 90, toObject: () => ({ _id: 'child-2', name: 'Vali', dailyLimit: 90 }) }
            ];

            Child.find.mockReturnValue({
                sort: jest.fn().mockResolvedValue(mockChildren)
            });

            // First child stats succeed, second fails
            Activity.getDailyStats
                .mockResolvedValueOnce({ totalDuration: 1800, byType: {}, count: 3 })
                .mockRejectedValueOnce(new Error('DB connection lost'));

            const response = await app.inject({
                method: 'GET',
                url: '/children',
                headers: { authorization: `Bearer ${token}` }
            });

            const data = JSON.parse(response.body);
            expect(response.statusCode).toBe(200);
            expect(data.success).toBe(true);
            expect(data.children).toHaveLength(2);

            // First child has real stats
            expect(data.children[0].todayUsage).toBe(1800);
            expect(data.children[0].remainingTime).toBe(60 * 60 - 1800);

            // Second child has fallback stats (0 usage)
            expect(data.children[1].todayUsage).toBe(0);
            expect(data.children[1].remainingTime).toBe(90 * 60);
        });

        it('should handle all stats failing gracefully', async () => {
            const mockChildren = [
                { _id: 'child-1', name: 'Ali', dailyLimit: 60, toObject: () => ({ _id: 'child-1', name: 'Ali', dailyLimit: 60 }) }
            ];

            Child.find.mockReturnValue({
                sort: jest.fn().mockResolvedValue(mockChildren)
            });

            Activity.getDailyStats.mockRejectedValue(new Error('DB down'));

            const response = await app.inject({
                method: 'GET',
                url: '/children',
                headers: { authorization: `Bearer ${token}` }
            });

            const data = JSON.parse(response.body);
            expect(response.statusCode).toBe(200);
            expect(data.success).toBe(true);
            expect(data.children[0].todayUsage).toBe(0);
        });
    });
});
