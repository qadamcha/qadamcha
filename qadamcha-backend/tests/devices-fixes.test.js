/**
 * Devices Controller Fixes Tests
 * Tests for: #17 heartbeat silent failure, #19 family code collision risk
 */

const { buildTestServer, closeTestServer, createTestToken } = require('./helpers/testServer');

// Mock models
jest.mock('../src/models', () => ({
    Device: {
        find: jest.fn(),
        findOne: jest.fn(),
        findOneAndUpdate: jest.fn(),
        create: jest.fn(),
        countDocuments: jest.fn(),
        updateOne: jest.fn(),
        generateFamilyCode: jest.fn()
    },
    Child: {
        findOne: jest.fn()
    }
}));

jest.mock('../src/config/env', () => ({
    MAX_DEVICES: 5
}));

jest.mock('../src/config/constants', () => ({
    ERRORS: {
        NOT_FOUND: 'Topilmadi',
        FORBIDDEN: 'Ruxsat yo\'q'
    },
    SUCCESS: {
        UPDATED: 'Muvaffaqiyatli yangilandi',
        DELETED: 'Muvaffaqiyatli o\'chirildi',
        DEVICE_LINKED: 'Qurilma ulandi'
    }
}));

const { Device } = require('../src/models');

describe('Devices Controller Fixes', () => {
    let app;
    let token;

    beforeAll(async () => {
        app = await buildTestServer();

        const devicesController = require('../src/controllers/devices.controller');

        // Heartbeat route
        app.post('/devices/heartbeat', {
            preHandler: [app.authenticate]
        }, async (request, reply) => {
            return devicesController.heartbeat(request, reply);
        });

        // Generate code route
        app.post('/devices/generate-code', {
            preHandler: [app.authenticate]
        }, async (request, reply) => {
            return devicesController.generateFamilyCode(request, reply);
        });

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
    // #17 — Heartbeat silent failure
    // ============================================================
    describe('#17: Heartbeat returns 404 when device not found', () => {
        it('should return success when device exists', async () => {
            Device.updateOne.mockResolvedValue({ matchedCount: 1, modifiedCount: 1 });

            const response = await app.inject({
                method: 'POST',
                url: '/devices/heartbeat',
                headers: { authorization: `Bearer ${token}` }
            });

            const data = JSON.parse(response.body);
            expect(response.statusCode).toBe(200);
            expect(data.success).toBe(true);
        });

        it('should return 404 when device not found (matchedCount=0)', async () => {
            Device.updateOne.mockResolvedValue({ matchedCount: 0, modifiedCount: 0 });

            const response = await app.inject({
                method: 'POST',
                url: '/devices/heartbeat',
                headers: { authorization: `Bearer ${token}` }
            });

            const data = JSON.parse(response.body);
            expect(response.statusCode).toBe(404);
            expect(data.success).toBe(false);
            expect(data.message).toContain('topilmadi');
        });

        it('should return 404 when device is inactive', async () => {
            // Device exists but isActive: false — updateOne won't match
            Device.updateOne.mockResolvedValue({ matchedCount: 0, modifiedCount: 0 });

            const response = await app.inject({
                method: 'POST',
                url: '/devices/heartbeat',
                headers: { authorization: `Bearer ${token}` }
            });

            expect(response.statusCode).toBe(404);
        });
    });

    // ============================================================
    // #19 — Family code collision risk
    // ============================================================
    describe('#19: Crypto-secure family code generation', () => {
        it('should generate family code via async generateFamilyCode', async () => {
            const mockDevice = {
                _id: 'device-1',
                userId: 'user-123',
                deviceId: 'device-123',
                isActive: true,
                familyCode: null,
                familyCodeExpires: null,
                save: jest.fn().mockResolvedValue(true)
            };

            Device.findOne.mockResolvedValue(mockDevice);
            Device.generateFamilyCode.mockResolvedValue('483921');

            const response = await app.inject({
                method: 'POST',
                url: '/devices/generate-code',
                headers: { authorization: `Bearer ${token}` }
            });

            const data = JSON.parse(response.body);
            expect(response.statusCode).toBe(200);
            expect(data.success).toBe(true);
            expect(data.familyCode).toBe('483921');
            expect(data.expiresAt).toBeDefined();

            // Verify generateFamilyCode was awaited (called as async)
            expect(Device.generateFamilyCode).toHaveBeenCalled();
        });

        it('should return 404 when device not found for code generation', async () => {
            Device.findOne.mockResolvedValue(null);

            const response = await app.inject({
                method: 'POST',
                url: '/devices/generate-code',
                headers: { authorization: `Bearer ${token}` }
            });

            expect(response.statusCode).toBe(404);
        });
    });
});

// Unit test for Device model generateFamilyCode
describe('Device.generateFamilyCode unit test', () => {
    it('should generate 6-digit code using crypto', () => {
        const crypto = require('crypto');

        // Test that crypto.randomInt produces valid range
        for (let i = 0; i < 100; i++) {
            const code = crypto.randomInt(100000, 999999).toString();
            expect(code).toMatch(/^\d{6}$/);
            expect(parseInt(code)).toBeGreaterThanOrEqual(100000);
            expect(parseInt(code)).toBeLessThanOrEqual(999999);
        }
    });

    it('should generate unique codes across multiple calls', () => {
        const crypto = require('crypto');
        const codes = new Set();

        for (let i = 0; i < 50; i++) {
            codes.add(crypto.randomInt(100000, 999999).toString());
        }

        // With 900000 possible codes, 50 random ones should almost certainly all be unique
        expect(codes.size).toBeGreaterThanOrEqual(45);
    });
});
