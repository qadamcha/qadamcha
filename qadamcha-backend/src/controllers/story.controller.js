const Story = require('../models/Story');

// GET /stories — Barcha ertaklarni olish
exports.getAll = async (request, reply) => {
    try {
        const { type, language, age, page = 1, limit = 50 } = request.query;

        const query = { isActive: true };
        if (type) query.type = type;
        if (language) query.language = language;
        if (age) {
            const parsedAge = parseInt(age);
            if (isNaN(parsedAge) || parsedAge < 1 || parsedAge > 18) {
                return reply.status(400).send({ success: false, message: 'Yosh 1-18 orasida bo\'lishi kerak' });
            }
            query['ageRange.min'] = { $lte: parsedAge };
            query['ageRange.max'] = { $gte: parsedAge };
        }

        // [FIX MED] Pagination validatsiyasi
        const parsedPage = Math.max(1, parseInt(page) || 1);
        const parsedLimit = Math.min(100, Math.max(1, parseInt(limit) || 50));
        const skip = (parsedPage - 1) * parsedLimit;

        const [stories, total] = await Promise.all([
            Story.find(query)
                .sort({ order: 1, createdAt: -1 })
                .skip(skip)
                .limit(parsedLimit),
            Story.countDocuments(query)
        ]);

        return {
            success: true,
            stories,
            count: stories.length,
            total,
            page: parsedPage,
            totalPages: Math.ceil(total / parsedLimit)
        };
    } catch (error) {
        reply.code(500);
        return { success: false, message: 'Ertaklarni olishda xatolik' };
    }
};

// GET /stories/featured — Tavsiya etilgan ertaklar
exports.getFeatured = async (request, reply) => {
    try {
        const stories = await Story.find({ isActive: true, isFeatured: true })
            .sort({ order: 1, createdAt: -1 })
            .limit(10);

        return { success: true, stories, count: stories.length };
    } catch (error) {
        reply.code(500);
        return { success: false, message: 'Ertaklarni olishda xatolik' };
    }
};

// GET /stories/:id — Bitta ertakni olish
// [FIX CRIT-6] isActive tekshiruvi + atomic $inc (race condition fix)
exports.getOne = async (request, reply) => {
    try {
        const story = await Story.findOneAndUpdate(
            { _id: request.params.id, isActive: true },
            { $inc: { views: 1 } },
            { new: true }
        );

        if (!story) {
            reply.code(404);
            return { success: false, message: 'Ertak topilmadi' };
        }

        return { success: true, story };
    } catch (error) {
        reply.code(500);
        return { success: false, message: 'Ertakni olishda xatolik' };
    }
};
