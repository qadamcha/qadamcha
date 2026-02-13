const { Child, Activity } = require('../models');
const { ERRORS, SUCCESS } = require('../config/constants');

module.exports = {

    // GET /children - Bolalar ro'yxati
    async getAll(request, reply) {
        const { userId } = request.user;

        const children = await Child.find({
            parentId: userId,
            isActive: true
        }).sort({ createdAt: -1 });

        // Har bir bola uchun bugungi statistika (xatolik bo'lsa graceful fallback)
        const today = new Date().toISOString().split('T')[0];
        const childrenWithStats = await Promise.all(
            children.map(async (child) => {
                try {
                    const stats = await Activity.getDailyStats(child._id, today);
                    return {
                        ...child.toObject(),
                        todayUsage: stats.totalDuration,
                        remainingTime: Math.max(0, child.dailyLimit * 60 - stats.totalDuration)
                    };
                } catch (err) {
                    request.log.error(`Stats error for child ${child._id}:`, err);
                    return {
                        ...child.toObject(),
                        todayUsage: 0,
                        remainingTime: child.dailyLimit * 60
                    };
                }
            })
        );

        return { success: true, children: childrenWithStats };
    },

    // GET /children/:id - Bitta bolani olish
    async getOne(request, reply) {
        const { userId } = request.user;
        const { id } = request.params;

        const child = await Child.findOne({
            _id: id,
            parentId: userId,
            isActive: true
        });

        if (!child) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        // Haftalik statistika
        const weeklyStats = await Activity.getWeeklyStats(child._id);

        return {
            success: true,
            child,
            weeklyStats
        };
    },

    // POST /children - Yangi bola qo'shish
    async create(request, reply) {
        const { userId } = request.user;
        const { name, age, gender, dailyLimit } = request.body;

        // Bola soni chegarasi (5 ta)
        const childCount = await Child.countDocuments({ parentId: userId, isActive: true });
        if (childCount >= 5) {
            return reply.status(400).send({
                success: false,
                message: 'Maksimal 5 ta bola qo\'shish mumkin'
            });
        }

        const child = await Child.create({
            parentId: userId,
            name,
            age,
            gender,
            dailyLimit: dailyLimit || 60
        });

        return reply.status(201).send({
            success: true,
            message: 'Bola qo\'shildi',
            child
        });
    },

    // PUT /children/:id - Bola ma'lumotlarini yangilash
    async update(request, reply) {
        const { userId } = request.user;
        const { id } = request.params;

        // Faqat ruxsat etilgan fieldlar (IDOR himoyasi)
        const ALLOWED_FIELDS = ['name', 'age', 'gender', 'avatar', 'dailyLimit', 'weekdayLimit', 'weekendLimit'];
        const updates = {};
        for (const field of ALLOWED_FIELDS) {
            if (request.body[field] !== undefined) {
                updates[field] = request.body[field];
            }
        }

        if (Object.keys(updates).length === 0) {
            return reply.status(400).send({
                success: false,
                message: 'Yangilanadigan ma\'lumot topilmadi'
            });
        }

        const child = await Child.findOneAndUpdate(
            { _id: id, parentId: userId, isActive: true },
            { $set: updates },
            { new: true, runValidators: true }
        );

        if (!child) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        return { success: true, message: SUCCESS.UPDATED, child };
    },

    // DELETE /children/:id - Bolani o'chirish (soft delete)
    async delete(request, reply) {
        const { userId } = request.user;
        const { id } = request.params;

        const child = await Child.findOneAndUpdate(
            { _id: id, parentId: userId },
            { isActive: false },
            { new: true }
        );

        if (!child) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        return { success: true, message: SUCCESS.DELETED };
    },

    // POST /children/:id/limit - Vaqt limitini o'zgartirish
    async setLimit(request, reply) {
        const { userId } = request.user;
        const { id } = request.params;
        const { dailyLimit, weekdayLimit, weekendLimit } = request.body;

        const update = {};
        if (dailyLimit) update.dailyLimit = dailyLimit;
        if (weekdayLimit) update.weekdayLimit = weekdayLimit;
        if (weekendLimit) update.weekendLimit = weekendLimit;

        const child = await Child.findOneAndUpdate(
            { _id: id, parentId: userId, isActive: true },
            { $set: update },
            { new: true }
        );

        if (!child) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        return {
            success: true,
            message: 'Vaqt limiti yangilandi',
            child
        };
    },

    // GET /children/:id/activities - Bola faollik tarixi
    async getActivities(request, reply) {
        const { userId } = request.user;
        const { id } = request.params;
        const { date, limit = 50 } = request.query;

        // Limit validation (max 500)
        const parsedLimit = Math.min(500, Math.max(1, parseInt(limit) || 50));

        // Date format validation
        if (date && !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
            return reply.status(400).send({
                success: false,
                message: 'Sana formati noto\'g\'ri (YYYY-MM-DD)'
            });
        }

        // Bola ota-onaga tegishliligini tekshirish
        const child = await Child.findOne({ _id: id, parentId: userId });
        if (!child) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        const query = { childId: id };
        if (date) query.date = date;

        const activities = await Activity.find(query)
            .sort({ createdAt: -1 })
            .limit(parsedLimit);

        return { success: true, activities };
    }
};
