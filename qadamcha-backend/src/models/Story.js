const mongoose = require('mongoose');

const storySchema = new mongoose.Schema({
    title: {
        type: String,
        required: [true, 'Ertak nomi majburiy'],
        trim: true,
        maxlength: 200
    },
    type: {
        type: String,
        enum: ['jahon', 'ozbek', 'islomiy'],
        default: 'ozbek'
    },
    storyText: {
        type: String,
        required: [true, 'Ertak matni majburiy']
    },

    // Yosh chegarasi
    ageRange: {
        min: { type: Number, default: 3, min: 1 },
        max: { type: Number, default: 12, max: 18 }
    },

    thumbnail: String,
    language: {
        type: String,
        default: 'uz'
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
storySchema.index({ type: 1, isActive: 1 });
storySchema.index({ 'ageRange.min': 1, 'ageRange.max': 1 });
storySchema.index({ language: 1 });
storySchema.index({ isFeatured: 1, isActive: 1 });

// Yosh bo'yicha ertak olish
storySchema.statics.getForAge = function (age, type = null) {
    const query = {
        isActive: true,
        'ageRange.min': { $lte: age },
        'ageRange.max': { $gte: age }
    };

    if (type) query.type = type;

    return this.find(query).sort({ order: 1, createdAt: -1 });
};

module.exports = mongoose.model('Story', storySchema);
