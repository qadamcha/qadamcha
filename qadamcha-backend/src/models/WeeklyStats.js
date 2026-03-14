const mongoose = require('mongoose');

// Haftalik ma'lumot (weeks[] ichidagi element)
const weekEntrySchema = new mongoose.Schema({
    weekNumber: { type: String, required: true },  // "2026-W11"
    dailyMinutes: {
        type: [Number],
        default: [0, 0, 0, 0, 0, 0, 0]  // Du-Ya
    },
    totalMinutes: { type: Number, default: 0 },
    totalSessions: { type: Number, default: 0 }
}, { _id: false });

// Har bir bola uchun FAQAT 1 ta document
const weeklyStatsSchema = new mongoose.Schema({
    childId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Child',
        required: true,
        unique: true  // Har bir bola uchun 1 ta doc
    },
    weeks: {
        type: [weekEntrySchema],
        default: [],
        validate: {
            validator: v => v.length <= 15,
            message: 'Max 15 ta hafta saqlanadi'
        }
    }
}, {
    timestamps: true
});

// Index
weeklyStatsSchema.index({ childId: 1 }, { unique: true });

module.exports = mongoose.model('WeeklyStats', weeklyStatsSchema);
