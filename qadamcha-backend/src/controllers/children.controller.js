const { Child, Activity, WeeklyStats } = require('../models');
const { ERRORS, SUCCESS } = require('../config/constants');
const { todayUzbekistan, currentWeekNumber } = require('../utils/dateUtils');

module.exports = {

    // GET /children - Bolalar ro'yxati
    async getAll(request, reply) {
        const { userId } = request.user;

        const children = await Child.find({
            parentId: userId,
            isActive: true
        }).sort({ createdAt: -1 });

        const today = todayUzbekistan();

        // ✅ OPTIMIZED: Bitta aggregate — barcha bolalar uchun kunlik stats
        // Eskisi: N+1 query (har bir bola uchun alohida getDailyStats)
        // Yangisi: 1 ta aggregate (barcha bolalar uchun bir marta)
        const childIds = children.map(c => c._id);
        let statsMap = new Map();
        try {
            // Yangi schema: har bir childId uchun 1 ta Activity doc
            const allActivities = await Activity.find(
                { childId: { $in: childIds } },
                { childId: 1, totalDuration: 1, contentIds: 1 }
            );
            for (const act of allActivities) {
                statsMap.set(act.childId.toString(), {
                    totalDuration: act.totalDuration || 0,
                    count: (act.contentIds || []).length
                });
            }
        } catch (err) {
            request.log.error('Activity stats error:', err);
        }

        const childrenWithStats = children.map((child) => {
            const syncedUsage = child.todayUsage || {};
            const isSameDay = child.lastUsageDate === today;
            const syncMinutes = isSameDay ? (syncedUsage.minutesUsed || 0) : 0;
            const syncVideos = isSameDay ? (syncedUsage.videosWatched || 0) : 0;
            const syncGames = isSameDay ? (syncedUsage.gamesPlayed || 0) : 0;
            const syncStories = isSameDay ? (syncedUsage.storiesRead || 0) : 0;

            // Faqat todayUsage dan olish (Activity.totalDuration kunlik emas — FIFO)
            const totalMinutes = syncMinutes;

            return {
                ...child.toObject(),
                todayUsage: {
                    minutesUsed: totalMinutes,
                    videosWatched: Math.max(0, syncVideos),
                    gamesPlayed: Math.max(0, syncGames),
                    storiesRead: Math.max(0, syncStories),
                },
                remainingTime: Math.max(0, child.dailyLimit * 60 - totalMinutes * 60)
            };
        });

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
    // [FIX HIGH-2] runValidators qo'shildi + limit qiymatlari validatsiyasi
    async setLimit(request, reply) {
        const { userId } = request.user;
        const { id } = request.params;
        const { dailyLimit, weekdayLimit, weekendLimit, weekdayMinutes, weekendMinutes } = request.body;

        const update = {};
        if (dailyLimit !== undefined) {
            if (typeof dailyLimit !== 'number' || dailyLimit < 5 || dailyLimit > 480) {
                return reply.status(400).send({ success: false, message: 'dailyLimit 5-480 daqiqa orasida bo\'lishi kerak' });
            }
            update.dailyLimit = dailyLimit;
        }

        // Flutter weekdayMinutes/weekendMinutes yuboradi, backend weekdayLimit/weekendLimit saqlaydi
        const wdVal = weekdayMinutes !== undefined ? weekdayMinutes : weekdayLimit;
        const weVal = weekendMinutes !== undefined ? weekendMinutes : weekendLimit;

        if (wdVal !== undefined) {
            if (typeof wdVal !== 'number' || wdVal < 5 || wdVal > 480) {
                return reply.status(400).send({ success: false, message: 'weekdayLimit 5-480 daqiqa orasida bo\'lishi kerak' });
            }
            update.weekdayLimit = wdVal;
        }
        if (weVal !== undefined) {
            if (typeof weVal !== 'number' || weVal < 5 || weVal > 480) {
                return reply.status(400).send({ success: false, message: 'weekendLimit 5-480 daqiqa orasida bo\'lishi kerak' });
            }
            update.weekendLimit = weVal;
        }

        if (Object.keys(update).length === 0) {
            return reply.status(400).send({
                success: false,
                message: 'Kamida bitta limit qiymati kerak'
            });
        }

        const child = await Child.findOneAndUpdate(
            { _id: id, parentId: userId, isActive: true },
            { $set: update },
            { new: true, runValidators: true }
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

        const activity = await Activity.findOne({ childId: id });

        if (!activity) {
            return { success: true, activities: [] };
        }

        // Activity doc dan items ro'yxatini yaratish
        const items = (activity.contentIds || []).map((cid, i) => ({
            contentId: cid,
            title: (activity.contentTitles || [])[i] || 'Noma\'lum',
            duration: (activity.durations || [])[i] || 0,
            timestamp: (activity.timestamps || [])[i] || activity.createdAt
        }));

        return {
            success: true,
            activities: [{
                _id: activity._id,
                childId: activity.childId,
                totalDuration: activity.totalDuration,
                items,
                createdAt: activity.createdAt
            }]
        };
    },

    // GET /children/:id/stats/weekly - Haftalik statistika
    // ✅ OPTIMIZED: 2 ta alohida query o'rniga bitta aggregate
    async getWeeklyStatsEndpoint(request, reply) {
        const { userId } = request.user;
        const { id } = request.params;

        const child = await Child.findOne({ _id: id, parentId: userId });
        if (!child) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        const oneWeekAgo = new Date();
        oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

        const weeklyData = await Activity.aggregate([
            {
                $match: {
                    childId: child._id,
                    createdAt: { $gte: oneWeekAgo }
                }
            },
            {
                $project: {
                    date: 1,
                    totalDuration: 1,
                    sessions: { $size: '$contentIds' }
                }
            },
            { $sort: { date: 1 } }
        ]);

        const dailyMinutes = [0, 0, 0, 0, 0, 0, 0];
        let totalMinutes = 0;
        let videosWatched = 0;
        let gamesPlayed = 0;
        let storiesRead = 0;

        for (const day of weeklyData) {
            const date = new Date(day.date);
            let dayIndex = date.getDay() - 1;
            if (dayIndex < 0) dayIndex = 6;
            dailyMinutes[dayIndex] = Math.round((day.totalDuration || 0) / 60);
            totalMinutes += Math.round((day.totalDuration || 0) / 60);
            videosWatched += day.sessions || 0;
        }

        // videosWatched/gamesPlayed/storiesRead — Child.todayUsage dan olish
        const syncedUsage = child.todayUsage || {};
        const today = todayUzbekistan();
        if (child.lastUsageDate === today) {
            videosWatched = Math.max(videosWatched, syncedUsage.videosWatched || 0);
            gamesPlayed = syncedUsage.gamesPlayed || 0;
            storiesRead = syncedUsage.storiesRead || 0;
        }

        return {
            success: true,
            stats: {
                totalMinutes,
                videosWatched,
                gamesPlayed,
                storiesRead,
                dailyMinutes
            }
        };
    },

    // POST /children/:id/activity - Faoliyatni yozish
    // Har bir childId uchun 1 ta Activity doc — max 5 ta element (FIFO)
    async recordActivity(request, reply) {
        const { userId } = request.user;
        const { id } = request.params;
        const { contentId, contentTitle, durationMinutes } = request.body;

        const child = await Child.findOne({ _id: id, parentId: userId });
        if (!child) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        const durationSeconds = (durationMinutes || 1) * 60;
        const resolvedContentId = contentId || 'unknown';
        const resolvedTitle = contentTitle || 'Noma\'lum';

        // 5 tadan oshib ketmasligi uchun eski elementni o'chirish (FIFO)
        const existing = await Activity.findOne({ childId: child._id });
        if (existing && existing.contentIds.length >= 5) {
            const removedDuration = existing.durations[0] || 0;
            await Activity.updateOne(
                { childId: child._id },
                {
                    $pop: { contentIds: -1, contentTitles: -1, durations: -1, timestamps: -1 },
                    $inc: { totalDuration: -removedDuration }
                }
            );
        }

        // Yangi element qo'shish
        const activity = await Activity.findOneAndUpdate(
            { childId: child._id },
            {
                $push: {
                    contentIds: resolvedContentId,
                    contentTitles: resolvedTitle,
                    durations: durationSeconds,
                    timestamps: new Date()
                },
                $inc: { totalDuration: durationSeconds },
                $setOnInsert: { childId: child._id }
            },
            { upsert: true, new: true }
        );

        return { success: true, activity };
    },

    // POST /children/:id/sync-usage — Batch sync (LocalMonitoringService → DB)
    // $max operatori: faqat kattaroq qiymatni yozadi
    async syncUsage(request, reply) {
        const { userId } = request.user;
        const { id } = request.params;
        const { minutesUsed, videosWatched, gamesPlayed, storiesRead } = request.body;

        const child = await Child.findOne({ _id: id, parentId: userId });
        if (!child) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        const today = todayUzbekistan();

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

        // WeeklyStats ga ham joriy haftani yangilash (bitta doc, weeks[] array)
        const week = currentWeekNumber();
        const todayDate = new Date(today + 'T12:00:00Z');
        let dayIndex = todayDate.getDay() - 1; // 0=Du, 6=Ya
        if (dayIndex < 0) dayIndex = 6;

        let statsDoc = await WeeklyStats.findOne({ childId: child._id });
        if (!statsDoc) {
            // Birinchi marta — yangi doc yaratish
            const newWeek = { weekNumber: week, dailyMinutes: [0,0,0,0,0,0,0], totalMinutes: 0, totalSessions: 0 };
            newWeek.dailyMinutes[dayIndex] = minutesUsed || 0;
            newWeek.totalMinutes = newWeek.dailyMinutes.reduce((a,b) => a+b, 0);
            statsDoc = await WeeklyStats.create({ childId: child._id, weeks: [newWeek] });
        } else {
            // Mavjud doc — joriy haftani topish yoki qo'shish
            const weekIdx = statsDoc.weeks.findIndex(w => w.weekNumber === week);
            if (weekIdx >= 0) {
                // Mavjud hafta — $max bilan yangilash
                const current = statsDoc.weeks[weekIdx].dailyMinutes[dayIndex] || 0;
                if ((minutesUsed || 0) > current) {
                    statsDoc.weeks[weekIdx].dailyMinutes[dayIndex] = minutesUsed;
                    statsDoc.weeks[weekIdx].totalMinutes = statsDoc.weeks[weekIdx].dailyMinutes.reduce((a,b) => a+b, 0);
                    await statsDoc.save();
                }
            } else {
                // Yangi hafta — qo'shish (15 tadan oshsa eskini o'chirish)
                if (statsDoc.weeks.length >= 15) {
                    statsDoc.weeks.shift(); // Eng eskini o'chirish (FIFO)
                }
                const newWeek = { weekNumber: week, dailyMinutes: [0,0,0,0,0,0,0], totalMinutes: 0, totalSessions: 0 };
                newWeek.dailyMinutes[dayIndex] = minutesUsed || 0;
                newWeek.totalMinutes = newWeek.dailyMinutes.reduce((a,b) => a+b, 0);
                statsDoc.weeks.push(newWeek);
                await statsDoc.save();
            }
        }

        return { success: true, message: 'Usage synced' };
    },

    // POST /children/:id/sync-weekly — Haftalik stats ni MongoDB ga saqlash
    // App hafta almashganda chaqiradi — eski hafta ma'lumotlarini yuboradi
    async syncWeekly(request, reply) {
        const { userId } = request.user;
        const { id } = request.params;
        const { weekNumber, dailyMinutes, totalSessions } = request.body;

        const child = await Child.findOne({ _id: id, parentId: userId });
        if (!child) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        if (!weekNumber || !dailyMinutes || dailyMinutes.length !== 7) {
            return reply.status(400).send({
                success: false,
                message: 'weekNumber va dailyMinutes (7 element) kerak'
            });
        }

        const totalMinutes = dailyMinutes.reduce((a, b) => a + b, 0);

        let statsDoc = await WeeklyStats.findOne({ childId: child._id });
        if (!statsDoc) {
            statsDoc = await WeeklyStats.create({
                childId: child._id,
                weeks: [{ weekNumber, dailyMinutes, totalMinutes, totalSessions: totalSessions || 0 }]
            });
        } else {
            const weekIdx = statsDoc.weeks.findIndex(w => w.weekNumber === weekNumber);
            if (weekIdx >= 0) {
                // Mavjud hafta — yangilash
                statsDoc.weeks[weekIdx].dailyMinutes = dailyMinutes;
                statsDoc.weeks[weekIdx].totalMinutes = totalMinutes;
                statsDoc.weeks[weekIdx].totalSessions = totalSessions || 0;
            } else {
                // Yangi hafta — 15 tadan oshsa eskini o'chirish
                if (statsDoc.weeks.length >= 15) {
                    statsDoc.weeks.shift(); // FIFO — eng eskini chiqarish
                }
                statsDoc.weeks.push({ weekNumber, dailyMinutes, totalMinutes, totalSessions: totalSessions || 0 });
            }
            await statsDoc.save();
        }

        return { success: true, message: 'Weekly stats synced' };
    },

    // GET /children/:id/weekly-history — Oxirgi 15 hafta tarixi
    async getWeeklyHistory(request, reply) {
        const { userId } = request.user;
        const { id } = request.params;

        const child = await Child.findOne({ _id: id, parentId: userId });
        if (!child) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        const statsDoc = await WeeklyStats.findOne({ childId: child._id }).lean();
        const weeks = statsDoc ? statsDoc.weeks : [];

        return { success: true, weeks };
    }
};
