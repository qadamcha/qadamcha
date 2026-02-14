const mongoose = require('mongoose');

const paymeTransactionSchema = new mongoose.Schema({
    paymeId: {
        type: String,
        unique: true,
        sparse: true
    },
    orderId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Subscription',
        required: true
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    // Payme state machine:
    // 1 = created, 2 = performed (paid)
    // -1 = cancelled before perform, -2 = cancelled after perform
    state: {
        type: Number,
        enum: [1, 2, -1, -2],
        default: 1
    },
    amount: {
        type: Number,
        required: true
    },
    createTime: {
        type: Number,
        required: true
    },
    performTime: {
        type: Number,
        default: 0
    },
    cancelTime: {
        type: Number,
        default: 0
    },
    reason: {
        type: Number,
        default: null
    }
}, {
    timestamps: true
});

paymeTransactionSchema.index({ paymeId: 1 });
paymeTransactionSchema.index({ orderId: 1 });
paymeTransactionSchema.index({ createTime: 1 });

module.exports = mongoose.model('PaymeTransaction', paymeTransactionSchema);
