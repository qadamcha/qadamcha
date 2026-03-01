const mongoose = require('mongoose');

const activitySchema = new mongoose.Schema({
    childId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Child',
        required: true
    },

    // Kunlik activity — max 5 ta element (FIFO)
    contentIds: {
        type: [String],   // Content._id lari
        default: []
    },
    durations: {
        type: [Number],   // Soniyalarda, contentIds bilan index mos
        default: []
    },

    // Jami davomiylik (stats uchun — tez hisoblash)
    totalDuration: {
        type: Number,
        default: 0
    },

    // Sana
    date: {
        type: String  // "2026-03-02" format
    },

}, {
    timestamps: true
});

// Compound indexes
activitySchema.index({ childId: 1, date: 1 }, { unique: true });
activitySchema.index({ childId: 1, createdAt: -1 });

// Kunlik statistika olish
activitySchema.statics.getDailyStats = async function (childId, date) {
    const activity = await this.findOne({ childId, date });

    if (!activity) {
        return { totalDuration: 0, count: 0 };
    }

    return {
        totalDuration: activity.totalDuration || 0,
        count: activity.contentIds.length
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
            $project: {
                date: 1,
                totalDuration: 1,
                sessions: { $size: '$contentIds' }
            }
        },
        { $sort: { date: 1 } }
    ]);
};

module.exports = mongoose.model('Activity', activitySchema);
