const express = require('express');
const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 4000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// MongoDB Content Schema
const contentSchema = new mongoose.Schema({
    title: { type: String, required: true, trim: true, maxlength: 100 },
    type: { type: String, enum: ['cartoon', 'game', 'story', 'quest'], required: true },
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

// Routes
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// GET - Barcha kontentlarni olish
app.get('/api/contents', async (req, res) => {
    try {
        const contents = await Content.find().sort({ createdAt: -1 });
        res.json({ success: true, contents, count: contents.length });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// GET - Bunny.net dan video ma'lumotlarini olish
app.get('/api/bunny/:videoId', async (req, res) => {
    const { videoId } = req.params;
    const libraryId = process.env.BUNNY_LIBRARY_ID;
    const apiKey = process.env.BUNNY_API_KEY;
    const cdnHost = process.env.BUNNY_CDN_HOST;

    if (!libraryId || !apiKey) {
        return res.status(400).json({ success: false, message: 'Bunny.net sozlamalari topilmadi' });
    }

    try {
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
                duration: video.length, // sekundlarda
                thumbnail: `https://${cdnHost}/${videoId}/thumbnail.jpg`,
                status: video.status === 4 ? 'ready' : 'processing'
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// POST - Yangi kontent qo'shish
app.post('/api/contents', async (req, res) => {
    try {
        const { title, type, category, description, ageMin, ageMax, videoId, duration, thumbnail, tags, isFeatured, language } = req.body;

        const content = await Content.create({
            title,
            type,
            category,
            description,
            ageRange: { min: parseInt(ageMin) || 3, max: parseInt(ageMax) || 12 },
            videoId,
            duration: parseInt(duration) || 0,
            thumbnail,
            tags: tags ? tags.split(',').map(t => t.trim()) : [],
            isFeatured: isFeatured === 'true' || isFeatured === true,
            language: language || 'uz'
        });

        res.json({ success: true, message: 'Kontent muvaffaqiyatli qo\'shildi!', content });
    } catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
});

// DELETE - Kontentni o'chirish
app.delete('/api/contents/:id', async (req, res) => {
    try {
        await Content.findByIdAndDelete(req.params.id);
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
