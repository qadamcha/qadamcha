const mongoose = require('mongoose');

const contentSchema = new mongoose.Schema({
    title: {
        type: String,
        required: [true, 'Kontent nomi majburiy'],
        trim: true,
        maxlength: 100
    },
    type: {
        type: String,
        enum: ['cartoon', 'game', 'story', 'quest'],
        required: true
    },
    category: {
        type: String
    },
    description: {
        type: String,
        maxlength: 500
    },

    // Yosh chegarasi
    ageRange: {
        min: { type: Number, default: 3, min: 1 },
        max: { type: Number, default: 12, max: 18 }
    },

    // Video ma'lumotlari (Bunny.net)
    videoId: String,        // Bunny.net video ID
    duration: Number,       // sekundlarda
    thumbnail: String,      // Thumbnail URL

    // Qo'shimcha meta
    tags: [String],
    language: {
        type: String,
        default: 'uz' // O'zbek
    },

    // Tartib va ko'rsatish
    order: {
        type: Number,
        default: 0
    },
    isFeatured: {
        type: Boolean,
        default: false
    },
    isActive: {
        type: Boolean,
        default: true
    },

    // Statistika
    views: {
        type: Number,
        default: 0
    },
    likes: {
        type: Number,
        default: 0
    },

}, {
    timestamps: true
});

// Indexes
contentSchema.index({ type: 1, isActive: 1 });
contentSchema.index({ 'ageRange.min': 1, 'ageRange.max': 1 });
contentSchema.index({ category: 1 });
contentSchema.index({ isFeatured: 1, isActive: 1 });
contentSchema.index({ order: 1 });

// Yosh bo'yicha kontent olish
contentSchema.statics.getForAge = function (age, type = null) {
    const query = {
        isActive: true,
        'ageRange.min': { $lte: age },
        'ageRange.max': { $gte: age }
    };

    if (type) query.type = type;

    return this.find(query).sort({ order: 1, createdAt: -1 });
};

module.exports = mongoose.model('Content', contentSchema);
