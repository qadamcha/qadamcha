const mongoose = require('mongoose');

/**
 * Payme Subscribe API Transaction Model
 * 
 * Receipt holatlari (Subscribe API):
 *   0  = yaratilgan (created)
 *   4  = to'langan (paid)
 *   5  = hold (pending confirmation)
 *   21 = bekor qilish navbatda (cancel queued)
 *   50 = bekor qilingan (cancelled)
 */
const paymeTransactionSchema = new mongoose.Schema({
    // Payme receipt ID
    receiptId: {
        type: String,
        unique: true,
        sparse: true,
    },

    // Ichki buyurtma ID (Subscription)
    orderId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Subscription',
        required: true,
    },

    // Foydalanuvchi
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },

    // Receipt holati (Payme Subscribe API)
    state: {
        type: Number,
        enum: [0, 4, 5, 21, 50],
        default: 0,
    },

    // Summa (tiyinda)
    amount: {
        type: Number,
        required: true,
    },

    // Maskirovka qilingan karta raqami (860006******6311)
    cardNumber: {
        type: String,
        default: null,
    },

    // Yaratilgan vaqt
    createTime: {
        type: Number,
        default: () => Date.now(),
    },

    // To'langan vaqt
    performTime: {
        type: Number,
        default: 0,
    },

    // Bekor qilingan vaqt
    cancelTime: {
        type: Number,
        default: 0,
    },

    // Bekor qilish sababi
    reason: {
        type: Number,
        default: null,
    },
}, {
    timestamps: true,
});

// Indexes
paymeTransactionSchema.index({ receiptId: 1 });
paymeTransactionSchema.index({ orderId: 1 });
paymeTransactionSchema.index({ userId: 1 });
paymeTransactionSchema.index({ state: 1 });
paymeTransactionSchema.index({ createTime: 1 });

module.exports = mongoose.model('PaymeTransaction', paymeTransactionSchema);
