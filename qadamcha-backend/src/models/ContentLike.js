const mongoose = require('mongoose');

const contentLikeSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    contentId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Content',
        required: true
    },
}, {
    timestamps: true
});

// Har bir user har bir content ga faqat 1 ta like
contentLikeSchema.index({ userId: 1, contentId: 1 }, { unique: true });

module.exports = mongoose.model('ContentLike', contentLikeSchema);
