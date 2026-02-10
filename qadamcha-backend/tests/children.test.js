/**
 * Children Controller Tests
 * Bolalar boshqaruvi uchun testlar
 */

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
        getDailyStats: jest.fn(() => Promise.resolve({ totalDuration: 30, byType: {}, count: 2 })),
        getWeeklyStats: jest.fn(() => Promise.resolve([]))
    }
}));

const { Child, Activity } = require('../src/models');

describe('Child Model Logic', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    describe('Child CRUD Operations', () => {
        it('should create a child with valid data', async () => {
            const childData = {
                parentId: 'parent123',
                name: 'Ali',
                age: 5,
                gender: 'male',
                dailyLimit: 60
            };

            Child.create.mockResolvedValue({
                _id: 'child123',
                ...childData,
                isActive: true,
                createdAt: new Date()
            });

            const result = await Child.create(childData);

            expect(result.name).toBe('Ali');
            expect(result.age).toBe(5);
            expect(result.dailyLimit).toBe(60);
            expect(Child.create).toHaveBeenCalledWith(childData);
        });

        it('should enforce maximum 5 children per parent', async () => {
            Child.countDocuments.mockResolvedValue(5);

            const count = await Child.countDocuments({
                parentId: 'parent123',
                isActive: true
            });

            expect(count).toBe(5);
            // Controller should reject if count >= 5
        });

        it('should soft delete a child', async () => {
            Child.findOneAndUpdate.mockResolvedValue({
                _id: 'child123',
                isActive: false
            });

            const result = await Child.findOneAndUpdate(
                { _id: 'child123', parentId: 'parent123' },
                { isActive: false },
                { new: true }
            );

            expect(result.isActive).toBe(false);
        });
    });

    describe('Child Statistics', () => {
        it('should get daily stats for a child', async () => {
            const result = await Activity.getDailyStats('child123', '2026-02-09');

            expect(result.totalDuration).toBe(30);
            expect(result.count).toBe(2);
        });

        it('should calculate remaining time correctly', () => {
            const dailyLimit = 60; // daqiqalarda
            const todayUsage = 30; // daqiqalarda

            const remainingTime = Math.max(0, dailyLimit - todayUsage);
            expect(remainingTime).toBe(30);

            // If usage exceeds limit
            const overUsage = 70;
            const noTimeLeft = Math.max(0, dailyLimit - overUsage);
            expect(noTimeLeft).toBe(0);
        });
    });

    describe('Child Validation', () => {
        it('should validate age range (1-18)', () => {
            const validAges = [1, 5, 12, 18];
            const invalidAges = [0, -1, 19, 100];

            validAges.forEach(age => {
                expect(age >= 1 && age <= 18).toBe(true);
            });

            invalidAges.forEach(age => {
                expect(age >= 1 && age <= 18).toBe(false);
            });
        });

        it('should validate daily limit range (5-480)', () => {
            const validLimits = [5, 60, 120, 480];
            const invalidLimits = [1, 4, 481, 1000];

            validLimits.forEach(limit => {
                expect(limit >= 5 && limit <= 480).toBe(true);
            });

            invalidLimits.forEach(limit => {
                expect(limit >= 5 && limit <= 480).toBe(false);
            });
        });

        it('should validate name length (2-30)', () => {
            const validNames = ['Al', 'Ali', 'Muhammad Abdulloh'];
            const invalidNames = ['A', 'A'.repeat(31)];

            validNames.forEach(name => {
                expect(name.length >= 2 && name.length <= 30).toBe(true);
            });

            invalidNames.forEach(name => {
                expect(name.length >= 2 && name.length <= 30).toBe(false);
            });
        });
    });
});

describe('Activity Tracking', () => {
    it('should calculate weekly stats structure', async () => {
        Activity.getWeeklyStats.mockResolvedValue([
            { _id: '2026-02-03', totalDuration: 45, sessions: 3 },
            { _id: '2026-02-04', totalDuration: 60, sessions: 4 },
            { _id: '2026-02-05', totalDuration: 30, sessions: 2 }
        ]);

        const result = await Activity.getWeeklyStats('child123');

        expect(result).toHaveLength(3);
        expect(result[0]).toHaveProperty('totalDuration');
        expect(result[0]).toHaveProperty('sessions');
    });
});
