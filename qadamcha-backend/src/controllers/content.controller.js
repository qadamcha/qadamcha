const mongoose = require('mongoose');
const { Content, Activity, Child } = require('../models');
const videoService = require('../services/video.service');
const { ERRORS, CONTENT_TYPES } = require('../config/constants');

const VALID_CONTENT_TYPES = Object.values(CONTENT_TYPES);

module.exports = {

    // GET /content - Barcha kontentlar (filtrlash bilan)
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
        const parsedLimit = Math.min(100, Math.max(1, parseInt(limit) || 20));

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

        return {
            success: true,
            contents: contentsWithUrls,
            pagination: {
                page: parsedPage,
                limit: parsedLimit,
                total,
                pages: Math.ceil(total / parsedLimit)
            }
        };
    },

    // GET /content/featured - Tavsiya etilgan kontentlar
    async getFeatured(request, reply) {
        const { age } = request.query;

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
                // Activity + Child atomic update (transaction)
                const session = await mongoose.startSession();
                session.startTransaction();

                try {
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
                        },
                        { session }
                    );

                    if (!updated) {
                        await session.abortTransaction();
                        session.endSession();
                        return reply.status(404).send({
                            success: false,
                            message: 'Faol sessiya topilmadi'
                        });
                    }

                    await Child.updateOne(
                        { _id: childId },
                        {
                            $inc: { todayUsage: duration },
                            $set: { lastActive: new Date(), lastUsageDate: today }
                        },
                        { session }
                    );

                    await session.commitTransaction();
                    session.endSession();
                } catch (txErr) {
                    await session.abortTransaction();
                    session.endSession();
                    throw txErr;
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
