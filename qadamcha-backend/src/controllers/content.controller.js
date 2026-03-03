const { Content, Activity, Child, ContentLike } = require('../models');
const videoService = require('../services/video.service');
const cacheService = require('../services/cache.service');
const notificationService = require('../services/notification.service');
const { ERRORS, CONTENT_TYPES } = require('../config/constants');

const VALID_CONTENT_TYPES = Object.values(CONTENT_TYPES);

module.exports = {

    // GET /content - Barcha kontentlar (filtrlash bilan) — cached
    async getAll(request, reply) {
        const { type, category, age, page = 1, limit = 20 } = request.query;

        // Input validation — NoSQL injection himoyasi
        if (type && !VALID_CONTENT_TYPES.includes(type)) {
            return reply.status(400).send({ success: false, message: 'Noto\'g\'ri content turi' });
        }
        if (category && (typeof category !== 'string' || category.length > 50)) {
            return reply.status(400).send({ success: false, message: 'Noto\'g\'ri kategoriya' });
        }
        const parsedAge = age ? parseInt(age) : null;
        if (parsedAge !== null && (isNaN(parsedAge) || parsedAge < 1 || parsedAge > 18)) {
            return reply.status(400).send({ success: false, message: 'Yosh 1-18 orasida bo\'lishi kerak' });
        }
        const parsedPage = Math.max(1, parseInt(page) || 1);
        const parsedLimit = Math.min(500, Math.max(1, parseInt(limit) || 20));

        // Cache tekshirish
        const cacheKey = `content:list:${type || ''}:${category || ''}:${parsedAge || ''}:${parsedPage}:${parsedLimit}`;
        const cached = await cacheService.get(cacheKey);
        if (cached) return cached;

        const query = { isActive: true };

        if (type) query.type = type;
        if (category) query.category = String(category);
        if (parsedAge) {
            query['ageRange.min'] = { $lte: parsedAge };
            query['ageRange.max'] = { $gte: parsedAge };
        }

        const skip = (parsedPage - 1) * parsedLimit;

        const [contents, total] = await Promise.all([
            Content.find(query)
                .sort({ order: 1, createdAt: -1 })
                .skip(skip)
                .limit(parsedLimit),
            Content.countDocuments(query)
        ]);

        const contentsWithUrls = contents.map(content => ({
            ...content.toObject(),
            thumbnailUrl: content.thumbnail || videoService.getThumbnailUrl(content.videoId),
            streamUrl: videoService.getStreamUrl(content.videoId)
        }));

        const result = {
            success: true,
            contents: contentsWithUrls,
            pagination: {
                page: parsedPage,
                limit: parsedLimit,
                total,
                pages: Math.ceil(total / parsedLimit)
            }
        };

        await cacheService.set(cacheKey, result, cacheService.TTL.CONTENT_LIST);
        return result;
    },

    // GET /content/featured - Tavsiya etilgan kontentlar — cached
    async getFeatured(request, reply) {
        const { age } = request.query;

        const cacheKey = `content:featured:${age || ''}`;
        const cached = await cacheService.get(cacheKey);
        if (cached) return cached;

        const query = { isActive: true, isFeatured: true };

        if (age) {
            const parsedAge = parseInt(age);
            if (isNaN(parsedAge) || parsedAge < 1 || parsedAge > 18) {
                return reply.status(400).send({ success: false, message: 'Yosh 1-18 orasida bo\'lishi kerak' });
            }
            query['ageRange.min'] = { $lte: parsedAge };
            query['ageRange.max'] = { $gte: parsedAge };
        }

        const contents = await Content.find(query)
            .sort({ order: 1 })
            .limit(10);

        const contentsWithUrls = contents.map(content => ({
            ...content.toObject(),
            thumbnailUrl: content.thumbnail || videoService.getThumbnailUrl(content.videoId),
            streamUrl: videoService.getStreamUrl(content.videoId)
        }));

        const result = { success: true, contents: contentsWithUrls };
        await cacheService.set(cacheKey, result, cacheService.TTL.FEATURED);
        return result;
    },

    // GET /content/categories - Kategoriyalar ro'yxati — cached
    async getCategories(request, reply) {
        const cacheKey = 'content:categories';
        const cached = await cacheService.get(cacheKey);
        if (cached) return cached;

        const categories = await Content.aggregate([
            { $match: { isActive: true } },
            {
                $group: {
                    _id: '$category',
                    count: { $sum: 1 },
                    types: { $addToSet: '$type' }
                }
            },
            { $sort: { count: -1 } }
        ]);

        const result = { success: true, categories };
        await cacheService.set(cacheKey, result, cacheService.TTL.CATEGORIES);
        return result;
    },

    // GET /content/:id - Bitta kontentni olish
    async getOne(request, reply) {
        const { id } = request.params;

        const content = await Content.findOne({ _id: id, isActive: true });

        if (!content) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        // Ko'rishlar sonini atomic oshirish (race condition oldini olish)
        await Content.updateOne({ _id: id }, { $inc: { views: 1 } });

        // Streaming URL qo'shish
        let streamUrl = null;
        if (content.videoId) {
            streamUrl = videoService.getStreamUrl(content.videoId);
        }

        return {
            success: true,
            content: {
                ...content.toObject(),
                streamUrl
            }
        };
    },

    // GET /content/:id/stream - Streaming URL olish (autentifikatsiya bilan)
    async getStreamUrl(request, reply) {
        const { id } = request.params;
        const { childId } = request.query;
        const { userId } = request.user;

        const content = await Content.findById(id);
        if (!content || !content.videoId) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        // Bola vaqt limitini tekshirish (ownership bilan)
        if (childId) {
            const child = await Child.findOne({
                _id: childId,
                parentId: userId,
                isActive: true
            });
            if (!child) {
                return reply.status(403).send({
                    success: false,
                    message: ERRORS.FORBIDDEN
                });
            }

            const today = new Date().toISOString().split('T')[0];
            const stats = await Activity.getDailyStats(childId, today);

            if (stats.totalDuration >= child.dailyLimit * 60) {
                return reply.status(403).send({
                    success: false,
                    message: 'Bugungi vaqt limiti tugadi'
                });
            }
        }

        return {
            success: true,
            streamUrl: videoService.getStreamUrl(content.videoId),
            thumbnail: videoService.getThumbnailUrl(content.videoId),
            content: {
                id: content._id,
                title: content.title,
                duration: content.duration
            }
        };
    },

    // POST /content/:id/activity - Faollik qayd etish
    async recordActivity(request, reply) {
        const { id } = request.params;
        const { childId, duration, action } = request.body;
        const { userId } = request.user;

        // Duration validation (0-86400 sekund = 24 soat)
        if (duration !== undefined && (typeof duration !== 'number' || duration < 0 || duration > 86400)) {
            return reply.status(400).send({
                success: false,
                message: 'Duration 0-86400 sekund orasida bo\'lishi kerak'
            });
        }

        // Child ownership tekshiruvi
        const child = await Child.findOne({
            _id: childId,
            parentId: userId,
            isActive: true
        });
        if (!child) {
            return reply.status(403).send({
                success: false,
                message: ERRORS.FORBIDDEN
            });
        }

        const content = await Content.findById(id);
        if (!content) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        const today = new Date().toISOString().split('T')[0];

        try {
            if (action === 'start') {
                await Activity.create({
                    childId,
                    contentId: content._id,
                    contentType: content.type,
                    contentTitle: content.title,
                    date: today,
                    startedAt: new Date(),
                    duration: 0
                });
            } else if (action === 'end' || action === 'update') {
                // Activity va Child ni ketma-ket yangilash (Atlas free tier uchun transaction siz)
                const updated = await Activity.findOneAndUpdate(
                    {
                        childId,
                        contentId: content._id,
                        date: today,
                        endedAt: null
                    },
                    {
                        $inc: { duration },
                        $set: action === 'end' ? { endedAt: new Date() } : {}
                    }
                );

                if (!updated) {
                    return reply.status(404).send({
                        success: false,
                        message: 'Faol sessiya topilmadi'
                    });
                }

                // [FIX CRIT-5] todayUsage — nested object, $inc to'g'ri fieldlarga qaratildi
                const durationMinutes = Math.round(duration / 60);
                const usageInc = { 'todayUsage.minutesUsed': durationMinutes };

                // Content turiga qarab tegishli counter ni oshirish
                if (content.type === 'cartoon' || content.type === 'video') {
                    usageInc['todayUsage.videosWatched'] = 1;
                } else if (content.type === 'game') {
                    usageInc['todayUsage.gamesPlayed'] = 1;
                } else if (content.type === 'story') {
                    usageInc['todayUsage.storiesRead'] = 1;
                }

                await Child.updateOne(
                    { _id: childId },
                    {
                        $inc: usageInc,
                        $set: { lastActive: new Date(), lastUsageDate: today }
                    }
                );

                // Push notification: vaqt limiti 80% ga yetganda
                try {
                    const updatedChild = await Child.findById(childId);
                    if (updatedChild && updatedChild.dailyLimit > 0) {
                        const usedSeconds = updatedChild.todayUsage || 0;
                        const limitSeconds = updatedChild.dailyLimit * 60;
                        const percentUsed = Math.round((usedSeconds / limitSeconds) * 100);
                        if (percentUsed >= 80 && percentUsed < 100) {
                            notificationService.notifyTimeLimitApproaching(
                                userId, updatedChild.name, percentUsed
                            ).catch(() => { });
                        }
                    }
                } catch (_notifErr) {
                    // Notification xatosi — asosiy flowni to'xtatmaymiz
                }
            }
        } catch (err) {
            request.log.error('Activity recording failed:', err);
            return reply.status(500).send({
                success: false,
                message: 'Faollikni qayd etishda xatolik'
            });
        }

        return { success: true };
    },

    // POST /content/:id/like - Like/unlike toggle
    // [FIX HIGH-1] Atomic operatsiyalar + manfiy likes oldini olish
    async like(request, reply) {
        const { id } = request.params;
        const { userId } = request.user;

        const content = await Content.findOne({ _id: id, isActive: true });
        if (!content) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        // Atomic: findOneAndDelete — agar mavjud bo'lsa o'chiradi
        const deletedLike = await ContentLike.findOneAndDelete({ userId, contentId: id });

        if (deletedLike) {
            // Unlike — likes ni kamaytirish (manfiy bo'lmasligini ta'minlash)
            await Content.updateOne(
                { _id: id, likes: { $gt: 0 } },
                { $inc: { likes: -1 } }
            );
            const updated = await Content.findById(id);
            return { success: true, liked: false, likes: Math.max(0, updated.likes) };
        }

        // Like qo'shish
        await ContentLike.create({ userId, contentId: id });
        await Content.updateOne({ _id: id }, { $inc: { likes: 1 } });
        const updated = await Content.findById(id);
        return { success: true, liked: true, likes: updated.likes };
    }
};
