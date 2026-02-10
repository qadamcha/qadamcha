const mongoose = require('mongoose');

const activitySchema = new mongoose.Schema({
    childId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Child',
        required: true,
        index: true
    },
    contentId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Content'
    },

    // Kontent ma'lumotlari (denormalized for quick access)
    contentType: String,
    contentTitle: String,

    // Vaqt
    duration: {
        type: Number,
        default: 0 // sekundlarda
    },
    date: {
        type: String,  // "2026-02-09" format
        index: true
    },
    startedAt: Date,
    endedAt: Date,

    // Session info
    deviceId: String,

}, {
    timestamps: true
});

// Compound indexes
activitySchema.index({ childId: 1, date: 1 });
activitySchema.index({ childId: 1, createdAt: -1 });
activitySchema.index({ date: 1, childId: 1 });

// Kunlik statistika olish
activitySchema.statics.getDailyStats = async function (childId, date) {
    const activities = await this.find({ childId, date });

    const totalDuration = activities.reduce((sum, a) => sum + (a.duration || 0), 0);
    const byType = activities.reduce((acc, a) => {
        acc[a.contentType] = (acc[a.contentType] || 0) + (a.duration || 0);
        return acc;
    }, {});

    return {
        totalDuration,
        byType,
        count: activities.length
    };
};

// Haftalik statistika
activitySchema.statics.getWeeklyStats = async function (childId) {
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

    return this.aggregate([
        {
            $match: {
                childId: new mongoose.Types.ObjectId(childId),
                createdAt: { $gte: oneWeekAgo }
            }
        },
        {
            $group: {
                _id: '$date',
                totalDuration: { $sum: '$duration' },
                sessions: { $sum: 1 }
            }
        },
        { $sort: { _id: 1 } }
    ]);
};

module.exports = mongoose.model('Activity', activitySchema);
