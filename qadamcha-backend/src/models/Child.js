const mongoose = require('mongoose');

const childSchema = new mongoose.Schema({
    parentId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: [true, 'Ota-ona ID majburiy']
    },
    name: {
        type: String,
        required: [true, 'Bola ismi majburiy'],
        trim: true,
        minlength: [2, 'Ism kamida 2 ta belgi'],
        maxlength: [30, 'Ism 30 ta belgidan oshmasin']
    },
    age: {
        type: Number,
        required: [true, 'Yosh majburiy'],
        min: [1, 'Yosh 1 dan katta bo\'lishi kerak'],
        max: [18, 'Yosh 18 dan kichik bo\'lishi kerak']
    },
    gender: {
        type: String,
        enum: ['male', 'female']
    },
    avatar: String,

    // Vaqt chegaralari
    dailyLimit: {
        type: Number,
        default: 60,  // daqiqalarda
        min: 5,
        max: 480 // 8 soat
    },
    weekdayLimit: {
        type: Number,
        default: 60
    },
    weekendLimit: {
        type: Number,
        default: 120
    },

    // Joriy statistika
    currentUsage: {
        type: Number,
        default: 0
    },
    todayUsage: {
        minutesUsed: { type: Number, default: 0 },
        videosWatched: { type: Number, default: 0 },
        gamesPlayed: { type: Number, default: 0 },
        storiesRead: { type: Number, default: 0 },
    },
    lastUsageDate: String, // "2026-02-09"
    lastActive: Date,

    // Sozlamalar
    settings: {
        allowedCategories: [String],
        blockedContent: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Content' }],
        autoStop: { type: Boolean, default: true }, // Limit tugaganda to'xtatish
        notifications: { type: Boolean, default: true }
    },

    isActive: {
        type: Boolean,
        default: true
    },
}, {
    timestamps: true
});

// Indexes
childSchema.index({ parentId: 1 });
childSchema.index({ parentId: 1, isActive: 1 });

// Virtual - bugungi qolgan vaqt
childSchema.virtual('remainingTime').get(function () {
    return Math.max(0, this.dailyLimit - (this.todayUsage?.minutesUsed || 0));
});

// Kunlik statistikani yangilash
childSchema.methods.resetDailyUsage = function () {
    const today = new Date().toISOString().split('T')[0];
    if (this.lastUsageDate !== today) {
        this.todayUsage = { minutesUsed: 0, videosWatched: 0, gamesPlayed: 0, storiesRead: 0 };
        this.lastUsageDate = today;
    }
};

module.exports = mongoose.model('Child', childSchema);
