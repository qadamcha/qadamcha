const Story = require('../models/Story');

// GET /stories — Barcha ertaklarni olish
exports.getAll = async (request, reply) => {
    try {
        const { type, language, age, page = 1, limit = 50 } = request.query;

        const query = { isActive: true };
        if (type) query.type = type;
        if (language) query.language = language;
        if (age) {
            query['ageRange.min'] = { $lte: parseInt(age) };
            query['ageRange.max'] = { $gte: parseInt(age) };
        }

        const skip = (parseInt(page) - 1) * parseInt(limit);

        const [stories, total] = await Promise.all([
            Story.find(query)
                .sort({ order: 1, createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            Story.countDocuments(query)
        ]);

        return {
            success: true,
            stories,
            count: stories.length,
            total,
            page: parseInt(page),
            totalPages: Math.ceil(total / parseInt(limit))
        };
    } catch (error) {
        reply.code(500);
        return { success: false, message: error.message };
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
        return { success: false, message: error.message };
    }
};

// GET /stories/:id — Bitta ertakni olish
exports.getOne = async (request, reply) => {
    try {
        const story = await Story.findById(request.params.id);

        if (!story) {
            reply.code(404);
            return { success: false, message: 'Ertak topilmadi' };
        }

        // Ko'rishlar sonini oshirish
        story.views += 1;
        await story.save();

        return { success: true, story };
    } catch (error) {
        reply.code(500);
        return { success: false, message: error.message };
    }
};
