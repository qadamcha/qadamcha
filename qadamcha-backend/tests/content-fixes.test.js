/**
 * Content Controller Fixes Tests
 * Tests for: #14 views counter race condition, #18 negative duration validation
 */

const { buildTestServer, closeTestServer, createTestToken } = require('./helpers/testServer');
const mongoose = require('mongoose');

// Mock mongoose session
const mockSession = {
    startTransaction: jest.fn(),
    commitTransaction: jest.fn(),
    abortTransaction: jest.fn(),
    endSession: jest.fn()
};
jest.spyOn(mongoose, 'startSession').mockResolvedValue(mockSession);

// Mock models
jest.mock('../src/models', () => ({
    Content: {
        findOne: jest.fn(),
        findById: jest.fn(),
        findByIdAndUpdate: jest.fn(),
        updateOne: jest.fn(),
        find: jest.fn(),
        countDocuments: jest.fn(),
        aggregate: jest.fn()
    },
    Activity: {
        create: jest.fn(),
        findOneAndUpdate: jest.fn(),
        getDailyStats: jest.fn()
    },
    Child: {
        findOne: jest.fn(),
        updateOne: jest.fn()
    }
}));

jest.mock('../src/services/video.service', () => ({
    getStreamUrl: jest.fn((videoId) => `https://stream.example.com/${videoId}`),
    getThumbnailUrl: jest.fn((videoId) => `https://thumb.example.com/${videoId}`)
}));

jest.mock('../src/config/constants', () => ({
    ERRORS: {
        NOT_FOUND: 'Topilmadi',
        FORBIDDEN: 'Ruxsat yo\'q'
    },
    CONTENT_TYPES: {
        CARTOON: 'cartoon',
        GAME: 'game',
        STORY: 'story',
        QUEST: 'quest'
    }
}));

const { Content, Activity, Child } = require('../src/models');

describe('Content Controller Fixes', () => {
    let app;
    let token;

    beforeAll(async () => {
        app = await buildTestServer();

        const contentController = require('../src/controllers/content.controller');

        // Register routes manually
        app.get('/content/:id', async (request, reply) => {
            return contentController.getOne(request, reply);
        });

        app.post('/content/:id/activity', {
            preHandler: [app.authenticate]
        }, async (request, reply) => {
            return contentController.recordActivity(request, reply);
        });

        await app.ready();
        token = createTestToken(app, { userId: 'parent-123', deviceId: 'device-123' });
    });

    afterAll(async () => {
        await closeTestServer(app);
    });

    beforeEach(() => {
        jest.clearAllMocks();
        mockSession.startTransaction.mockClear();
        mockSession.commitTransaction.mockClear();
        mockSession.abortTransaction.mockClear();
        mockSession.endSession.mockClear();
    });

    // ============================================================
    // #14 — Views counter race condition (atomic $inc)
    // ============================================================
    describe('#14: Views counter atomic increment', () => {
        it('should use atomic updateOne with $inc instead of read-modify-write', async () => {
            const mockContent = {
                _id: 'content-1',
                title: 'Test Video',
                videoId: 'vid-123',
                views: 10,
                isActive: true,
                toObject: () => ({
                    _id: 'content-1',
                    title: 'Test Video',
                    videoId: 'vid-123',
                    views: 10
                })
            };

            Content.findOne.mockResolvedValue(mockContent);
            Content.updateOne.mockResolvedValue({ modifiedCount: 1 });

            const response = await app.inject({
                method: 'GET',
                url: '/content/content-1'
            });

            expect(response.statusCode).toBe(200);

            // Verify atomic $inc was used (not content.save())
            expect(Content.updateOne).toHaveBeenCalledWith(
                { _id: 'content-1' },
                { $inc: { views: 1 } }
            );
        });

        it('should return 404 for non-existent content', async () => {
            Content.findOne.mockResolvedValue(null);

            const response = await app.inject({
                method: 'GET',
                url: '/content/nonexistent'
            });

            expect(response.statusCode).toBe(404);
            // updateOne should NOT be called
            expect(Content.updateOne).not.toHaveBeenCalled();
        });
    });

    // ============================================================
    // #18 — Negative duration validation
    // ============================================================
    describe('#18: Duration validation in recordActivity', () => {
        const mockChild = {
            _id: 'child-1',
            parentId: 'parent-123',
            name: 'Ali',
            isActive: true
        };
        const mockContent = {
            _id: 'content-1',
            type: 'cartoon',
            title: 'Test',
            videoId: 'vid-1'
        };

        beforeEach(() => {
            Child.findOne.mockResolvedValue(mockChild);
            Content.findById.mockResolvedValue(mockContent);
        });

        it('should reject negative duration', async () => {
            const response = await app.inject({
                method: 'POST',
                url: '/content/content-1/activity',
                headers: { authorization: `Bearer ${token}` },
                payload: {
                    childId: 'child-1',
                    duration: -100,
                    action: 'update'
                }
            });

            expect(response.statusCode).toBe(400);
            const data = JSON.parse(response.body);
            expect(data.message).toContain('0-86400');
        });

        it('should reject duration exceeding 86400 seconds (24h)', async () => {
            const response = await app.inject({
                method: 'POST',
                url: '/content/content-1/activity',
                headers: { authorization: `Bearer ${token}` },
                payload: {
                    childId: 'child-1',
                    duration: 86401,
                    action: 'update'
                }
            });

            expect(response.statusCode).toBe(400);
            const data = JSON.parse(response.body);
            expect(data.message).toContain('0-86400');
        });

        it('should accept duration of 0', async () => {
            Activity.create.mockResolvedValue({ _id: 'activity-1' });

            const response = await app.inject({
                method: 'POST',
                url: '/content/content-1/activity',
                headers: { authorization: `Bearer ${token}` },
                payload: {
                    childId: 'child-1',
                    duration: 0,
                    action: 'start'
                }
            });

            expect(response.statusCode).toBe(200);
        });

        it('should accept valid duration (3600 seconds = 1 hour)', async () => {
            Activity.findOneAndUpdate.mockResolvedValue({ _id: 'activity-1' });
            Child.updateOne.mockResolvedValue({ modifiedCount: 1 });

            const response = await app.inject({
                method: 'POST',
                url: '/content/content-1/activity',
                headers: { authorization: `Bearer ${token}` },
                payload: {
                    childId: 'child-1',
                    duration: 3600,
                    action: 'end'
                }
            });

            expect(response.statusCode).toBe(200);
        });

        it('should reject non-numeric duration', async () => {
            const response = await app.inject({
                method: 'POST',
                url: '/content/content-1/activity',
                headers: { authorization: `Bearer ${token}` },
                payload: {
                    childId: 'child-1',
                    duration: 'abc',
                    action: 'update'
                }
            });

            expect(response.statusCode).toBe(400);
        });
    });
});
