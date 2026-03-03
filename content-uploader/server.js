const express = require('express');
const mongoose = require('mongoose');
const path = require('path');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 4000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));
app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE']
}));

// MongoDB Content Schema (Multfilm/Video)
const contentSchema = new mongoose.Schema({
    title: { type: String, required: true, trim: true, maxlength: 100 },
    type: { type: String, enum: ['cartoon', 'game', 'story', 'quest', 'talimiy', 'ozbek', 'jahon'], required: true },
    series: { type: String, trim: true, maxlength: 100 },
    category: { type: String },
    description: { type: String, maxlength: 500 },
    ageRange: {
        min: { type: Number, default: 3, min: 1 },
        max: { type: Number, default: 12, max: 18 }
    },
    videoId: String,
    duration: Number,
    thumbnail: String,
    tags: [String],
    language: { type: String, default: 'uz' },
    order: { type: Number, default: 0 },
    isFeatured: { type: Boolean, default: false },
    isActive: { type: Boolean, default: true },
    views: { type: Number, default: 0 },
    likes: { type: Number, default: 0 }
}, { timestamps: true });

const Content = mongoose.model('Content', contentSchema);

// MongoDB Story Schema (Ertak)
const storySchema = new mongoose.Schema({
    title: { type: String, required: true, trim: true, maxlength: 200 },
    type: { type: String, enum: ['ertak', 'masal', 'hikoya', 'she\'r'], default: 'ertak' },
    storyText: { type: String, required: true },
    ageRange: {
        min: { type: Number, default: 3, min: 1 },
        max: { type: Number, default: 12, max: 18 }
    },
    thumbnail: String,
    language: { type: String, default: 'uz' },
    order: { type: Number, default: 0 },
    isFeatured: { type: Boolean, default: false },
    isActive: { type: Boolean, default: true },
    views: { type: Number, default: 0 },
    likes: { type: Number, default: 0 }
}, { timestamps: true });

const Story = mongoose.model('Story', storySchema);

// Error handler middleware
function asyncHandler(fn) {
    return (req, res, next) => {
        Promise.resolve(fn(req, res, next)).catch(next);
    };
}

// Routes
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// ==========================================
// CONTENT (Multfilm/Video) API
// ==========================================

// GET - Barcha kontentlarni olish (filter bilan)
app.get('/api/contents', asyncHandler(async (req, res) => {
    const { type, category, isFeatured, isActive, page = 1, limit = 50 } = req.query;

    const filter = {};
    if (type) filter.type = type;
    if (category) filter.category = category;
    if (isFeatured !== undefined) filter.isFeatured = isFeatured === 'true';
    if (isActive !== undefined) filter.isActive = isActive === 'true';

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [contents, total] = await Promise.all([
        Content.find(filter).sort({ order: 1, createdAt: -1 }).skip(skip).limit(parseInt(limit)),
        Content.countDocuments(filter)
    ]);

    res.json({
        success: true,
        contents,
        count: contents.length,
        total,
        page: parseInt(page),
        totalPages: Math.ceil(total / parseInt(limit))
    });
}));

// GET - Bitta kontentni olish
app.get('/api/contents/:id', asyncHandler(async (req, res) => {
    const content = await Content.findById(req.params.id);
    if (!content) {
        return res.status(404).json({ success: false, message: 'Kontent topilmadi' });
    }
    res.json({ success: true, content });
}));

// GET - Bunny.net dan video ma'lumotlarini olish
app.get('/api/bunny/:videoId', asyncHandler(async (req, res) => {
    const { videoId } = req.params;
    const libraryId = process.env.BUNNY_LIBRARY_ID;
    const apiKey = process.env.BUNNY_API_KEY;
    const cdnHost = process.env.BUNNY_CDN_HOST;

    if (!libraryId || !apiKey) {
        return res.status(400).json({ success: false, message: 'Bunny.net sozlamalari topilmadi' });
    }

    const response = await fetch(`https://video.bunnycdn.com/library/${libraryId}/videos/${videoId}`, {
        headers: {
            'Accept': 'application/json',
            'AccessKey': apiKey
        }
    });

    if (!response.ok) {
        return res.status(404).json({ success: false, message: 'Video topilmadi' });
    }

    const video = await response.json();

    res.json({
        success: true,
        video: {
            title: video.title,
            duration: video.length,
            thumbnail: `https://${cdnHost}/${videoId}/thumbnail.jpg`,
            status: video.status === 4 ? 'ready' : 'processing'
        }
    });
}));

// POST - Bunny.net video sinxronlash (auto-import)
app.post('/api/bunny/sync/:videoId', asyncHandler(async (req, res) => {
    const { videoId } = req.params;
    const { type = 'cartoon', category, language = 'uz' } = req.body;
    const libraryId = process.env.BUNNY_LIBRARY_ID;
    const apiKey = process.env.BUNNY_API_KEY;
    const cdnHost = process.env.BUNNY_CDN_HOST;

    if (!libraryId || !apiKey) {
        return res.status(400).json({ success: false, message: 'Bunny.net sozlamalari topilmadi' });
    }

    // Bunny.net dan video ma'lumotlarini olish
    const response = await fetch(`https://video.bunnycdn.com/library/${libraryId}/videos/${videoId}`, {
        headers: { 'Accept': 'application/json', 'AccessKey': apiKey }
    });

    if (!response.ok) {
        return res.status(404).json({ success: false, message: 'Video Bunny.net da topilmadi' });
    }

    const video = await response.json();

    // Mavjud kontentni tekshirish
    let content = await Content.findOne({ videoId });

    if (content) {
        // Yangilash
        content.title = video.title;
        content.duration = video.length;
        content.thumbnail = `https://${cdnHost}/${videoId}/thumbnail.jpg`;
        await content.save();

        return res.json({
            success: true,
            message: 'Kontent yangilandi',
            content,
            action: 'updated'
        });
    }

    // Yangi kontent yaratish
    content = await Content.create({
        title: video.title,
        type,
        category: category || type,
        videoId,
        duration: video.length || 0,
        thumbnail: `https://${cdnHost}/${videoId}/thumbnail.jpg`,
        language,
    });

    res.json({
        success: true,
        message: 'Kontent Bunny.net dan sinxronlandi!',
        content,
        action: 'created'
    });
}));

// GET - Barcha seriyalar ro'yxatini olish (distinct)
app.get('/api/series', asyncHandler(async (req, res) => {
    const seriesList = await Content.distinct('series', { series: { $ne: null, $ne: '' } });
    res.json({ success: true, series: seriesList.filter(Boolean).sort() });
}));

// POST - Yangi kontent qo'shish
app.post('/api/contents', asyncHandler(async (req, res) => {
    const { title, type, series, category, description, ageMin, ageMax, videoId, duration, thumbnail, tags, isFeatured, language } = req.body;

    // Validatsiya
    if (!title || !type) {
        return res.status(400).json({
            success: false,
            message: 'title va type majburiy maydonlar'
        });
    }

    const content = await Content.create({
        title,
        type,
        series: series || undefined,
        category,
        description,
        ageRange: { min: parseInt(ageMin) || 3, max: parseInt(ageMax) || 12 },
        videoId,
        duration: parseInt(duration) || 0,
        thumbnail,
        tags: tags ? (Array.isArray(tags) ? tags : tags.split(',').map(t => t.trim())) : [],
        isFeatured: isFeatured === 'true' || isFeatured === true,
        language: language || 'uz'
    });

    res.json({ success: true, message: 'Kontent muvaffaqiyatli qo\'shildi!', content });
}));

// PUT - Kontentni tahrirlash
app.put('/api/contents/:id', asyncHandler(async (req, res) => {
    const { title, type, series, category, description, ageMin, ageMax, videoId, duration, thumbnail, tags, isFeatured, isActive, language, order } = req.body;

    const updateData = {};
    if (title !== undefined) updateData.title = title;
    if (type !== undefined) updateData.type = type;
    if (category !== undefined) updateData.category = category;
    if (series !== undefined) updateData.series = series;
    if (description !== undefined) updateData.description = description;
    if (ageMin !== undefined || ageMax !== undefined) {
        updateData.ageRange = {};
        if (ageMin !== undefined) updateData.ageRange.min = parseInt(ageMin);
        if (ageMax !== undefined) updateData.ageRange.max = parseInt(ageMax);
    }
    if (videoId !== undefined) updateData.videoId = videoId;
    if (duration !== undefined) updateData.duration = parseInt(duration);
    if (thumbnail !== undefined) updateData.thumbnail = thumbnail;
    if (tags !== undefined) updateData.tags = Array.isArray(tags) ? tags : tags.split(',').map(t => t.trim());
    if (isFeatured !== undefined) updateData.isFeatured = isFeatured === 'true' || isFeatured === true;
    if (isActive !== undefined) updateData.isActive = isActive === 'true' || isActive === true;
    if (language !== undefined) updateData.language = language;
    if (order !== undefined) updateData.order = parseInt(order);

    const content = await Content.findByIdAndUpdate(
        req.params.id,
        updateData,
        { new: true, runValidators: true }
    );

    if (!content) {
        return res.status(404).json({ success: false, message: 'Kontent topilmadi' });
    }

    res.json({ success: true, message: 'Kontent yangilandi!', content });
}));

// DELETE - Kontentni o'chirish
app.delete('/api/contents/:id', asyncHandler(async (req, res) => {
    const content = await Content.findByIdAndDelete(req.params.id);
    if (!content) {
        return res.status(404).json({ success: false, message: 'Kontent topilmadi' });
    }
    res.json({ success: true, message: 'O\'chirildi!' });
}));

// GET - Statistika
app.get('/api/stats', asyncHandler(async (req, res) => {
    const [total, cartoons, games, stories, quests, featured] = await Promise.all([
        Content.countDocuments({ isActive: true }),
        Content.countDocuments({ type: 'cartoon', isActive: true }),
        Content.countDocuments({ type: 'game', isActive: true }),
        Content.countDocuments({ type: 'story', isActive: true }),
        Content.countDocuments({ type: 'quest', isActive: true }),
        Content.countDocuments({ isFeatured: true, isActive: true }),
    ]);

    res.json({
        success: true,
        stats: { total, cartoons, games, stories, quests, featured }
    });
}));

// Global error handler
app.use((err, req, res, _next) => {
    console.error('❌ Xato:', err.message);

    if (err.name === 'ValidationError') {
        return res.status(400).json({ success: false, message: err.message });
    }

    if (err.name === 'CastError') {
        return res.status(400).json({ success: false, message: 'Noto\'g\'ri ID format' });
    }

    res.status(500).json({ success: false, message: 'Ichki server xatosi' });
});

// ==========================================
// STORY (Ertak) API
// ==========================================

// GET - Barcha ertaklarni olish
app.get('/api/stories', async (req, res) => {
    try {
        const stories = await Story.find().sort({ createdAt: -1 });
        res.json({ success: true, stories, count: stories.length });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// POST - Yangi ertak qo'shish
app.post('/api/stories', async (req, res) => {
    try {
        const { title, type, storyText, ageMin, ageMax, thumbnail, isFeatured, language } = req.body;

        const story = await Story.create({
            title,
            type: type || 'ertak',
            storyText,
            ageRange: { min: parseInt(ageMin) || 3, max: parseInt(ageMax) || 12 },
            thumbnail,
            isFeatured: isFeatured === 'true' || isFeatured === true,
            language: language || 'uz'
        });

        res.json({ success: true, message: 'Ertak muvaffaqiyatli qo\'shildi!', story });
    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
});

// DELETE - Ertakni o'chirish
app.delete('/api/stories/:id', async (req, res) => {
    try {
        await Story.findByIdAndDelete(req.params.id);
        res.json({ success: true, message: 'O\'chirildi!' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// MongoDB ulanish va server ishga tushirish
async function start() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ MongoDB ulandi');

        app.listen(PORT, () => {
            console.log(`\n🚀 Content Uploader ishlayapti: http://localhost:${PORT}\n`);
        });
    } catch (error) {
        console.error('❌ Xato:', error.message);
        process.exit(1);
    }
}

start();
