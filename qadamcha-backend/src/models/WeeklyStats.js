const mongoose = require('mongoose');

const weeklyStatsSchema = new mongoose.Schema({
    childId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Child',
        required: true
    },
    weekNumber: {
        type: String,  // "2026-W11"
        required: true
    },
    year: {
        type: Number,
        required: true
    },
    dailyMinutes: {
        type: [Number],  // [Du, Se, Ch, Pa, Ju, Sh, Ya] — 7 ta element
        default: [0, 0, 0, 0, 0, 0, 0],
        validate: {
            validator: v => v.length === 7,
            message: 'dailyMinutes 7 ta element bo\'lishi kerak'
        }
    },
    totalMinutes: {
        type: Number,
        default: 0
    },
    totalSessions: {
        type: Number,
        default: 0
    }
}, {
    timestamps: true
});

// Unique index: har bir bola uchun har haftada faqat 1 ta doc
weeklyStatsSchema.index({ childId: 1, weekNumber: 1 }, { unique: true });
// Tez qidirish uchun
weeklyStatsSchema.index({ weekNumber: -1 });

module.exports = mongoose.model('WeeklyStats', weeklyStatsSchema);
