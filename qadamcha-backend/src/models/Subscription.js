const mongoose = require('mongoose');

const subscriptionSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    plan: {
        type: String,
        enum: ['monthly', 'yearly', 'lifetime'],
        required: true
    },
    status: {
        type: String,
        enum: ['active', 'expired', 'cancelled', 'pending'],
        default: 'pending'
    },
    startDate: {
        type: Date,
        default: Date.now
    },
    endDate: {
        type: Date,
        required: true,
        index: true
    },
    maxDevices: {
        type: Number,
        default: 3
    },
    price: {
        type: Number,
        required: true
    },
    currency: {
        type: String,
        default: 'UZS'
    },

    // To'lov ma'lumotlari
    paymentMethod: {
        type: String,
        enum: ['payme', 'click', 'uzum', 'manual', 'trial']
    },
    transactionId: String,
    orderId: String,

    // Avtomatik yangilash
    autoRenew: {
        type: Boolean,
        default: false
    },

    // Ma'lumot
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    cancelledAt: Date,
    cancelReason: String,

}, {
    timestamps: true
});

// Indexes
subscriptionSchema.index({ userId: 1 });
subscriptionSchema.index({ endDate: 1 });
subscriptionSchema.index({ status: 1 });
subscriptionSchema.index({ userId: 1, status: 1 });

// Obuna faol yoki yo'qligini tekshirish
subscriptionSchema.methods.isValid = function () {
    return this.status === 'active' && this.endDate > new Date();
};

// Static: Foydalanuvchining faol obunasini olish
subscriptionSchema.statics.getActive = async function (userId) {
    return this.findOne({
        userId,
        status: 'active',
        endDate: { $gt: new Date() }
    }).sort({ endDate: -1 });
};

module.exports = mongoose.model('Subscription', subscriptionSchema);
