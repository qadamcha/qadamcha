const mongoose = require('mongoose');

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

// 6 xonali oila kodi generatsiya
deviceSchema.statics.generateFamilyCode = function () {
    return Math.floor(100000 + Math.random() * 900000).toString();
};

module.exports = mongoose.model('Device', deviceSchema);
