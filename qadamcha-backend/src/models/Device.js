const mongoose = require('mongoose');
const crypto = require('crypto');

const deviceSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    childId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Child'
    },
    deviceId: {
        type: String,
        required: [true, 'Device ID majburiy'],
        unique: true
    },
    deviceName: {
        type: String,
        default: 'Unknown Device'
    },
    deviceType: {
        type: String,
        enum: ['android', 'ios'],
        default: 'android'
    },
    mode: {
        type: String,
        enum: ['parent', 'child'],
        default: 'parent'
    },

    // Oila kodi (qurilma ulash uchun)
    familyCode: {
        type: String
    },
    familyCodeExpires: Date,

    // Tokens
    refreshToken: String,
    fcmToken: String, // Firebase Cloud Messaging

    // Status
    isActive: {
        type: Boolean,
        default: true
    },
    lastSeen: {
        type: Date,
        default: Date.now
    },

    // Device info
    osVersion: String,
    appVersion: String,

}, {
    timestamps: true
});

// Indexes
deviceSchema.index({ userId: 1 });
deviceSchema.index({ familyCode: 1 });
deviceSchema.index({ deviceId: 1 }, { unique: true });
deviceSchema.index({ userId: 1, isActive: 1 });

// 6 xonali oila kodi generatsiya (crypto-secure + uniqueness check)
deviceSchema.statics.generateFamilyCode = async function () {
    const maxAttempts = 5;
    for (let i = 0; i < maxAttempts; i++) {
        const code = (crypto.randomInt(100000, 999999)).toString();
        const existing = await this.findOne({
            familyCode: code,
            familyCodeExpires: { $gt: new Date() }
        });
        if (!existing) return code;
    }
    throw new Error('Oila kodi generatsiya qilib bo\'lmadi');
};

module.exports = mongoose.model('Device', deviceSchema);
