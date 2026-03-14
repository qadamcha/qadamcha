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
    type: { type: String, enum: ['ozbek', 'jahon', 'islomiy'], default: 'ozbek' },
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

// Qadamcha backend bilan umumiy collectionlardan o'qish (faqat statistika uchun)
const User = mongoose.model('User', new mongoose.Schema({}, { strict: false, collection: 'users' }));
const ChildModel = mongoose.model('ChildDashboard', new mongoose.Schema({}, { strict: false, collection: 'children' }));
const Subscription = mongoose.model('Subscription', new mongoose.Schema({}, { strict: false, collection: 'subscriptions' }));
const Activity = mongoose.model('Activity', new mongoose.Schema({}, { strict: false, collection: 'activities' }));
const WeeklyStats = mongoose.model('WeeklyStatsDashboard', new mongoose.Schema({}, { strict: false, collection: 'weeklystats' }));

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
    const [total, talimiy, ozbek, jahon, featured] = await Promise.all([
        Content.countDocuments({ isActive: true }),
        Content.countDocuments({ type: 'talimiy', isActive: true }),
        Content.countDocuments({ type: 'ozbek', isActive: true }),
        Content.countDocuments({ type: 'jahon', isActive: true }),
        Content.countDocuments({ isFeatured: true, isActive: true }),
    ]);

    res.json({
        success: true,
        stats: { total, talimiy, ozbek, jahon, featured }
    });
}));

// GET - Dashboard statistika (User/Child/Subscription)
app.get('/api/dashboard/stats', asyncHandler(async (req, res) => {
    const [totalUsers, totalChildren, totalStories, totalContents, activeSubscriptions] = await Promise.all([
        User.countDocuments(),
        ChildModel.countDocuments(),
        Story.countDocuments(),
        Content.countDocuments(),
        Subscription.countDocuments({ status: 'active' }),
    ]);

    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    const newUsersThisWeek = await User.countDocuments({ createdAt: { $gte: weekAgo } });

    // Foydalanuvchilar + bolalar
    const users = await User.find().sort({ createdAt: -1 }).select('phone name role isActive lastLoginAt createdAt').lean();
    const children = await ChildModel.find().select('parentId name age gender dailyLimit todayUsage lastActive createdAt').lean();
    const usersWithChildren = users.map(u => ({
        ...u,
        children: children.filter(c => String(c.parentId) === String(u._id))
    }));

    // Obunalar (to'liq ma'lumot, userId populate)
    const subscriptions = await Subscription.find().sort({ createdAt: -1 }).lean();
    const subsWithUser = subscriptions.map(s => {
        const user = users.find(u => String(u._id) === String(s.userId));
        return { ...s, userName: user?.name || '-', userPhone: user?.phone || '-' };
    });

    res.json({
        success: true,
        dashboard: {
            totalUsers, totalChildren, totalStories, totalContents,
            activeSubscriptions, newUsersThisWeek,
            users: usersWithChildren,
            subscriptions: subsWithUser
        }
    });
}));

// GET - Foydalanish statistikasi (line chart uchun)
app.get('/api/dashboard/usage-stats', asyncHandler(async (req, res) => {
    const { period = '30' } = req.query; // kunlar soni
    const days = parseInt(period) || 30;

    // WeeklyStats dan barcha bolalarning ma'lumotlarini olish
    // Yangi schema: har bir doc da weeks[] array bor
    const allDocs = await WeeklyStats.find().lean();

    // dailyMinutes ni kunlarga yoyish
    const dailyUsage = {};
    const now = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    for (const doc of allDocs) {
        const weeks = doc.weeks || [];
        for (const ws of weeks) {
            if (!ws.weekNumber || !ws.dailyMinutes) continue;
            
            // weekNumber dan hafta boshlanish sanasini olish
            const [yearStr, weekStr] = ws.weekNumber.split('-W');
            const year = parseInt(yearStr);
            const weekNum = parseInt(weekStr);
            if (!year || !weekNum) continue;

            // ISO hafta → Dushanba sanasi
            const jan1 = new Date(year, 0, 1);
            const daysToMonday = (weekNum - 1) * 7 - (jan1.getDay() === 0 ? 6 : jan1.getDay() - 1);
            const mondayDate = new Date(year, 0, 1 + daysToMonday);

            // Har bir kun uchun (Du=0, Se=1 ... Ya=6)
            for (let d = 0; d < 7; d++) {
                const dayDate = new Date(mondayDate);
                dayDate.setDate(mondayDate.getDate() + d);
                
                if (dayDate >= startDate && dayDate <= now) {
                    const key = dayDate.toISOString().slice(0, 10);
                    const mins = (ws.dailyMinutes[d] || 0);
                    if (mins > 0) {
                        if (!dailyUsage[key]) dailyUsage[key] = { totalMinutes: 0, sessions: 0 };
                        dailyUsage[key].totalMinutes += mins;
                        dailyUsage[key].sessions += 1;
                    }
                }
            }
        }
    }

    // Child todayUsage dan bugungi ma'lumotni ham qo'shish
    const children = await ChildModel.find().select('todayUsage lastUsageDate').lean();
    const today = now.toISOString().slice(0, 10);
    for (const child of children) {
        if (child.todayUsage && child.todayUsage.minutesUsed > 0) {
            const key = child.lastUsageDate || today;
            if (!dailyUsage[key]) dailyUsage[key] = { totalMinutes: 0, sessions: 0 };
            dailyUsage[key].totalMinutes += child.todayUsage.minutesUsed || 0;
            dailyUsage[key].sessions += 1;
        }
    }

    // Natijani massivga aylantirib, sanalar bo'yicha tartiblash
    const chartData = [];
    for (let i = 0; i < days; i++) {
        const d = new Date(startDate);
        d.setDate(d.getDate() + i);
        const key = d.toISOString().slice(0, 10);
        chartData.push({
            date: key,
            label: d.toLocaleDateString('uz', { day: '2-digit', month: 'short' }),
            minutes: dailyUsage[key]?.totalMinutes || 0,
            sessions: dailyUsage[key]?.sessions || 0
        });
    }

    // O'rtacha hisoblash
    const totalMinutes = chartData.reduce((s, d) => s + d.minutes, 0);
    const totalSessions = chartData.reduce((s, d) => s + d.sessions, 0);
    const activeDays = chartData.filter(d => d.minutes > 0).length;

    const last7 = chartData.slice(-7);
    const avg7 = last7.reduce((s, d) => s + d.minutes, 0) / 7;

    const last30 = chartData.slice(-30);
    const avg30 = last30.reduce((s, d) => s + d.minutes, 0) / Math.min(30, last30.length || 1);

    res.json({
        success: true,
        usageStats: {
            chartData,
            summary: {
                totalMinutes, totalSessions, activeDays,
                avgDaily: Math.round(totalMinutes / (activeDays || 1)),
                avgWeekly: Math.round(avg7),
                avgMonthly: Math.round(avg30)
            }
        }
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

// PUT - Ertakni tahrirlash
app.put('/api/stories/:id', asyncHandler(async (req, res) => {
    const { title, type, storyText, ageMin, ageMax, thumbnail, isFeatured, isActive, language } = req.body;

    const updateData = {};
    if (title !== undefined) updateData.title = title;
    if (type !== undefined) updateData.type = type;
    if (storyText !== undefined) updateData.storyText = storyText;
    if (ageMin !== undefined || ageMax !== undefined) {
        updateData.ageRange = {};
        if (ageMin !== undefined) updateData.ageRange.min = parseInt(ageMin);
        if (ageMax !== undefined) updateData.ageRange.max = parseInt(ageMax);
    }
    if (thumbnail !== undefined) updateData.thumbnail = thumbnail;
    if (isFeatured !== undefined) updateData.isFeatured = isFeatured === 'true' || isFeatured === true;
    if (isActive !== undefined) updateData.isActive = isActive === 'true' || isActive === true;
    if (language !== undefined) updateData.language = language;

    const story = await Story.findByIdAndUpdate(
        req.params.id, updateData, { new: true, runValidators: true }
    );

    if (!story) {
        return res.status(404).json({ success: false, message: 'Ertak topilmadi' });
    }

    res.json({ success: true, message: 'Ertak yangilandi!', story });
}));

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
