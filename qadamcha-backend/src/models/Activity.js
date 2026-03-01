const mongoose = require('mongoose');

const activitySchema = new mongoose.Schema({
    childId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Child',
        required: true,
        unique: true  // Har bir childId uchun FAQAT 1 ta doc
    },

    // So'nggi 5 ta faoliyat (FIFO)
    contentIds: {
        type: [String],   // Content._id lari
        default: []
    },
    contentTitles: {
        type: [String],   // Video nomlari (contentIds bilan index mos)
        default: []
    },
    durations: {
        type: [Number],   // Soniyalarda (contentIds bilan index mos)
        default: []
    },

    // Jami davomiylik (stats uchun)
    totalDuration: {
        type: Number,
        default: 0
    },

}, {
    timestamps: true
});

// Index
activitySchema.index({ childId: 1 }, { unique: true });

module.exports = mongoose.model('Activity', activitySchema);
