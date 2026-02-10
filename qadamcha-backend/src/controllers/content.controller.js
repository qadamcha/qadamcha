const { Content, Activity, Child } = require('../models');
const videoService = require('../services/video.service');
const { ERRORS } = require('../config/constants');

module.exports = {

    // GET /content - Barcha kontentlar (filtrlash bilan)
    async getAll(request, reply) {
        const { type, category, age, page = 1, limit = 20 } = request.query;

        const query = { isActive: true };

        if (type) query.type = type;
        if (category) query.category = category;
        if (age) {
            query['ageRange.min'] = { $lte: parseInt(age) };
            query['ageRange.max'] = { $gte: parseInt(age) };
        }

        const skip = (parseInt(page) - 1) * parseInt(limit);

        const [contents, total] = await Promise.all([
            Content.find(query)
                .sort({ order: 1, createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            Content.countDocuments(query)
        ]);

        const contentsWithUrls = contents.map(content => ({
            ...content.toObject(),
            thumbnailUrl: content.thumbnail || videoService.getThumbnailUrl(content.videoId),
            streamUrl: videoService.getStreamUrl(content.videoId)
        }));

        return {
            success: true,
            contents: contentsWithUrls,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                pages: Math.ceil(total / limit)
            }
        };
    },

    // GET /content/featured - Tavsiya etilgan kontentlar
    async getFeatured(request, reply) {
        const { age } = request.query;

        const query = { isActive: true, isFeatured: true };

        if (age) {
            query['ageRange.min'] = { $lte: parseInt(age) };
            query['ageRange.max'] = { $gte: parseInt(age) };
        }

        const contents = await Content.find(query)
            .sort({ order: 1 })
            .limit(10);

        const contentsWithUrls = contents.map(content => ({
            ...content.toObject(),
            thumbnailUrl: content.thumbnail || videoService.getThumbnailUrl(content.videoId),
            streamUrl: videoService.getStreamUrl(content.videoId)
        }));

        return { success: true, contents: contentsWithUrls };
    },

    // GET /content/categories - Kategoriyalar ro'yxati
    async getCategories(request, reply) {
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

        return { success: true, categories };
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

        // Ko'rishlar sonini oshirish
        content.views += 1;
        await content.save();

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

        const content = await Content.findById(id);
        if (!content || !content.videoId) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        // Bola vaqt limitini tekshirish
        if (childId) {
            const child = await Child.findById(childId);
            if (child) {
                const today = new Date().toISOString().split('T')[0];
                const stats = await Activity.getDailyStats(childId, today);

                if (stats.totalDuration >= child.dailyLimit * 60) {
                    return reply.status(403).send({
                        success: false,
                        message: 'Bugungi vaqt limiti tugadi'
                    });
                }
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

        const content = await Content.findById(id);
        if (!content) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        const today = new Date().toISOString().split('T')[0];

        if (action === 'start') {
            // Yangi sessiya boshlash
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
            // Oxirgi sessiyani yangilash
            await Activity.findOneAndUpdate(
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

            // Bola statistikasini yangilash
            await Child.updateOne(
                { _id: childId },
                {
                    $inc: { todayUsage: duration },
                    $set: { lastActive: new Date(), lastUsageDate: today }
                }
            );
        }

        return { success: true };
    },

    // POST /content/:id/like - Like qo'shish
    async like(request, reply) {
        const { id } = request.params;

        const content = await Content.findByIdAndUpdate(
            id,
            { $inc: { likes: 1 } },
            { new: true }
        );

        if (!content) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        return { success: true, likes: content.likes };
    }
};
