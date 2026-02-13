const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
    phone: {
        type: String,
        required: [true, 'Telefon raqam majburiy'],
        unique: true
    },
    pin: {
        type: String,
        minlength: [4, 'PIN kamida 4 ta raqam bo\'lishi kerak'],
        maxlength: [6, 'PIN 6 ta raqamdan oshmasligi kerak']
    },
    name: {
        type: String,
        trim: true,
        minlength: [2, 'Ism kamida 2 ta belgi bo\'lishi kerak'],
        maxlength: [50, 'Ism 50 ta belgidan oshmasligi kerak']
    },
    role: {
        type: String,
        enum: ['parent', 'child', 'admin'],
        default: 'parent'
    },
    parentId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    avatar: String,
    isActive: {
        type: Boolean,
        default: true
    },
    lastLoginAt: Date,
}, {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true }
});

// Indexes (phone index already created by unique: true)
userSchema.index({ parentId: 1 });
userSchema.index({ createdAt: -1 });

// Virtual - bolalar
userSchema.virtual('children', {
    ref: 'Child',
    localField: '_id',
    foreignField: 'parentId'
});

// PIN ni compare qilish
userSchema.methods.comparePin = async function (pin) {
    if (!this.pin) return false;
    return bcrypt.compare(pin, this.pin);
};

// PIN ni hash qilish (save dan oldin)
userSchema.pre('save', async function (next) {
    if (this.isModified('pin') && this.pin) {
        this.pin = await bcrypt.hash(this.pin, 12);
    }
    next();
});

// JSON ga o'girganda PIN ni yashirish
userSchema.methods.toJSON = function () {
    const obj = this.toObject();
    delete obj.pin;
    return obj;
};

module.exports = mongoose.model('User', userSchema);
