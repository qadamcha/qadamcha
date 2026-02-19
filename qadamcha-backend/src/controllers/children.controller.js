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

    // POST|PATCH /children/:id/limit(s) - Vaqt limitini o'zgartirish
    async setLimit(request, reply) {
        const { userId } = request.user;
        const { id } = request.params;
        const { dailyLimit, weekdayLimit, weekendLimit, weekdayMinutes, weekendMinutes } = request.body;

        const update = {};
        if (dailyLimit !== undefined) update.dailyLimit = dailyLimit;
        // Flutter weekdayMinutes/weekendMinutes yuboradi, backend weekdayLimit/weekendLimit saqlaydi
        if (weekdayMinutes !== undefined) update.weekdayLimit = weekdayMinutes;
        if (weekdayLimit !== undefined) update.weekdayLimit = weekdayLimit;
        if (weekendMinutes !== undefined) update.weekendLimit = weekendMinutes;
        if (weekendLimit !== undefined) update.weekendLimit = weekendLimit;

        if (Object.keys(update).length === 0) {
            return reply.status(400).send({
                success: false,
                message: 'Kamida bitta limit qiymati kerak'
            });
        }

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

    // PATCH /children/:id/settings - Bolaning sozlamalarini yangilash
    async updateSettings(request, reply) {
        const { userId } = request.user;
        const { id } = request.params;
        const { allowGames, allowVideos, allowStories, safeMode } = request.body;

        const settingsUpdate = {};
        if (allowGames !== undefined) settingsUpdate['settings.allowGames'] = allowGames;
        if (allowVideos !== undefined) settingsUpdate['settings.allowVideos'] = allowVideos;
        if (allowStories !== undefined) settingsUpdate['settings.allowStories'] = allowStories;
        if (safeMode !== undefined) settingsUpdate['settings.safeMode'] = safeMode;

        if (Object.keys(settingsUpdate).length === 0) {
            return reply.status(400).send({
                success: false,
                message: 'Kamida bitta sozlama kerak'
            });
        }

        const child = await Child.findOneAndUpdate(
            { _id: id, parentId: userId, isActive: true },
            { $set: settingsUpdate },
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
            message: 'Sozlamalar yangilandi',
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
    },

    // GET /children/:id/stats/weekly - Haftalik statistika
    async getWeeklyStatsEndpoint(request, reply) {
        const { userId } = request.user;
        const { id } = request.params;

        // Bola ota-onaga tegishliligini tekshirish
        const child = await Child.findOne({ _id: id, parentId: userId });
        if (!child) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        const weeklyData = await Activity.getWeeklyStats(child._id);

        // Kunlik daqiqalarni to'ldirish (Du-Yak, 7 kun)
        const dailyMinutes = [0, 0, 0, 0, 0, 0, 0];
        let totalMinutes = 0;
        let videosWatched = 0;
        let gamesPlayed = 0;

        // Haftalik ma'lumotlarni qayta ishlash
        const oneWeekAgo = new Date();
        oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

        for (const day of weeklyData) {
            const date = new Date(day._id);
            // 0=Yakshanba, 1=Dushanba, ..., 6=Shanba -> Du=0, Se=1, ..., Yak=6
            let dayIndex = date.getDay() - 1;
            if (dayIndex < 0) dayIndex = 6; // Yakshanba
            dailyMinutes[dayIndex] = Math.round((day.totalDuration || 0) / 60);
            totalMinutes += Math.round((day.totalDuration || 0) / 60);
        }

        // Haftalik video va o'yin sanash
        const today = new Date().toISOString().split('T')[0];
        const weekStart = new Date();
        weekStart.setDate(weekStart.getDate() - 7);
        const weekStartStr = weekStart.toISOString().split('T')[0];

        const activities = await Activity.find({
            childId: child._id,
            date: { $gte: weekStartStr, $lte: today }
        });

        for (const act of activities) {
            if (act.contentType === 'video' || act.contentType === 'cartoon') {
                videosWatched++;
            } else if (act.contentType === 'game') {
                gamesPlayed++;
            }
        }

        return {
            success: true,
            stats: {
                totalMinutes,
                videosWatched,
                gamesPlayed,
                storiesRead: 0,
                dailyMinutes
            }
        };
    },

    // POST /children/:id/activity - Faoliyatni yozish (vaqt tracking)
    async recordActivity(request, reply) {
        const { userId } = request.user;
        const { id } = request.params;
        const { contentId, activityType, durationMinutes, contentTitle } = request.body;

        // Bola ota-onaga tegishliligini tekshirish
        const child = await Child.findOne({ _id: id, parentId: userId });
        if (!child) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        const now = new Date();
        const today = now.toISOString().split('T')[0];
        const durationSeconds = (durationMinutes || 1) * 60;

        // Content title aniqlash: request body'dan yoki default
        const resolvedTitle = contentTitle ||
            (activityType === 'video_watch' ? 'Multfilm ko\'rish' :
                activityType === 'game_play' ? 'O\'yin o\'ynash' :
                    activityType === 'story_read' ? 'Ertak o\'qish' :
                        'Ilova foydalanish');

        // Activity yozish
        const activity = await Activity.create({
            childId: child._id,
            contentId: contentId || undefined,
            contentType: activityType,
            contentTitle: resolvedTitle,
            duration: durationSeconds,
            date: today,
            startedAt: new Date(now.getTime() - durationSeconds * 1000),
            endedAt: now,
        });

        // Kunlik reset tekshirish (lazy)
        if (child.lastUsageDate !== today) {
            child.todayUsage = { minutesUsed: 0, videosWatched: 0, gamesPlayed: 0, storiesRead: 0 };
            child.lastUsageDate = today;
        }

        // Bolaning bugungi foydalanishini yangilash
        await Child.updateOne(
            { _id: child._id },
            {
                $set: { lastUsageDate: today },
                $inc: {
                    'todayUsage.minutesUsed': durationMinutes || 1,
                    ...(activityType === 'video_watch' ? { 'todayUsage.videosWatched': 1 } : {}),
                    ...(activityType === 'game_play' ? { 'todayUsage.gamesPlayed': 1 } : {}),
                    ...(activityType === 'story_read' ? { 'todayUsage.storiesRead': 1 } : {}),
                }
            }
        );

        return { success: true, activity };
    },

    // POST /children/:id/sync-usage — Batch sync (LocalMonitoringService → DB)
    // $max operatori: faqat kattaroq qiymatni yozadi (double counting muammosini hal qiladi)
    async syncUsage(request, reply) {
        const { userId } = request.user;
        const { id } = request.params;
        const { minutesUsed, videosWatched, gamesPlayed, storiesRead } = request.body;

        // Bola ota-onaga tegishliligini tekshirish
        const child = await Child.findOne({ _id: id, parentId: userId });
        if (!child) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        const today = new Date().toISOString().split('T')[0];

        // Kunlik reset tekshirish
        if (child.lastUsageDate !== today) {
            await Child.updateOne(
                { _id: child._id },
                {
                    $set: {
                        lastUsageDate: today,
                        'todayUsage.minutesUsed': minutesUsed || 0,
                        'todayUsage.videosWatched': videosWatched || 0,
                        'todayUsage.gamesPlayed': gamesPlayed || 0,
                        'todayUsage.storiesRead': storiesRead || 0,
                    }
                }
            );
        } else {
            // $max — faqat kattaroq qiymatni saqlash
            await Child.updateOne(
                { _id: child._id },
                {
                    $max: {
                        'todayUsage.minutesUsed': minutesUsed || 0,
                        'todayUsage.videosWatched': videosWatched || 0,
                        'todayUsage.gamesPlayed': gamesPlayed || 0,
                        'todayUsage.storiesRead': storiesRead || 0,
                    }
                }
            );
        }

        return { success: true, message: 'Usage synced' };
    }
};
