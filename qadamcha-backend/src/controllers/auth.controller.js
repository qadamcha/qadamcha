const crypto = require('crypto');
const { User, Device } = require('../models');
const smsService = require('../services/sms.service');
const blacklistService = require('../services/blacklist.service');
const config = require('../config/env');
const { REDIS_KEYS, ERRORS, SUCCESS } = require('../config/constants');

module.exports = {

    // POST /auth/send-otp
    async sendOtp(request, reply) {
        const { phone } = request.body;
        const redis = this.redis;

        // Rate limit check (test phone faqat development da bypass)
        const attemptsKey = `${REDIS_KEYS.OTP_ATTEMPTS}${phone}`;
        const isTestBypass = config.NODE_ENV !== 'production' && phone === config.TEST_PHONE;
        if (!isTestBypass) {
            const attempts = await redis.get(attemptsKey);

            if (attempts && parseInt(attempts) >= 3) {
                return reply.status(429).send({
                    success: false,
                    message: ERRORS.OTP_TOO_MANY
                });
            }
        }

        // Generate OTP
        const code = smsService.generateOtp();

        // Store OTP in Redis (5 minutes)
        const otpKey = `${REDIS_KEYS.OTP}${phone}`;
        await redis.setex(otpKey, config.OTP_EXPIRES, code);

        // Increment attempts
        await redis.incr(attemptsKey);
        await redis.expire(attemptsKey, 600); // 10 min block

        // Send SMS
        try {
            await smsService.sendOtp(phone, code);
        } catch (err) {
            request.log.error('SMS sending failed:', err);
            // Production da xato qaytarish — foydalanuvchini xabardor qilish
            if (config.NODE_ENV === 'production') {
                // OTP ni Redis dan tozalash — yuborilmagan kod ishlatilmasin
                await redis.del(otpKey);
                return reply.status(503).send({
                    success: false,
                    message: 'SMS xizmati vaqtincha ishlamayapti. Keyinroq urinib ko\'ring.'
                });
            }
        }

        // Dev modeda kodni ko'rsatish
        const response = { success: true, message: SUCCESS.OTP_SENT };
        if (config.NODE_ENV !== 'production') {
            response.code = code; // Faqat development uchun!
        }

        return response;
    },

    // POST /auth/verify-otp
    async verifyOtp(request, reply) {
        const { phone, code } = request.body;
        const redis = this.redis;

        const otpKey = `${REDIS_KEYS.OTP}${phone}`;
        const savedCode = await redis.get(otpKey);

        if (!savedCode || savedCode !== code) {
            return reply.status(400).send({
                success: false,
                message: ERRORS.OTP_INVALID
            });
        }

        // Delete OTP
        await redis.del(otpKey);
        await redis.del(`${REDIS_KEYS.OTP_ATTEMPTS}${phone}`);

        // Create verified token (10 minutes)
        const verifiedToken = crypto.randomBytes(32).toString('hex');
        await redis.setex(`${REDIS_KEYS.VERIFIED}${phone}`, 600, verifiedToken);

        // Check if user exists
        const user = await User.findOne({ phone });

        return {
            success: true,
            isNewUser: !user,
            verifiedToken,
            message: user ? 'Kirish uchun PIN kiriting' : 'Ro\'yxatdan o\'ting'
        };
    },

    // POST /auth/register
    async register(request, reply) {
        const { phone, name, pin } = request.body;
        const redis = this.redis;

        // Check if verified
        const verified = await redis.get(`${REDIS_KEYS.VERIFIED}${phone}`);
        if (!verified) {
            return reply.status(400).send({
                success: false,
                message: 'Avval telefon raqamni tasdiqlang'
            });
        }

        // Check existing user
        const existing = await User.findOne({ phone });
        if (existing) {
            return reply.status(400).send({
                success: false,
                message: ERRORS.USER_EXISTS
            });
        }

        // Create user
        const user = await User.create({
            phone,
            name,
            pin,
            role: 'parent'
        });

        await redis.del(`${REDIS_KEYS.VERIFIED}${phone}`);

        return {
            success: true,
            message: SUCCESS.REGISTERED,
            userId: user._id
        };
    },

    // POST /auth/reset-pin
    async resetPin(request, reply) {
        const { phone, newPin } = request.body;
        const redis = this.redis;

        // Check if phone is verified
        const verified = await redis.get(`${REDIS_KEYS.VERIFIED}${phone}`);
        if (!verified) {
            return reply.status(400).send({
                success: false,
                message: 'Avval telefon raqamni tasdiqlang'
            });
        }

        // Find user
        const user = await User.findOne({ phone });
        if (!user) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.USER_NOT_FOUND
            });
        }

        // Update PIN
        user.pin = newPin;
        await user.save();

        // Clear verified token
        await redis.del(`${REDIS_KEYS.VERIFIED}${phone}`);

        return {
            success: true,
            message: 'PIN kod muvaffaqiyatli yangilandi'
        };
    },

    // POST /auth/login
    async login(request, reply) {
        const { phone, pin, deviceId, deviceName, deviceType } = request.body;

        const user = await User.findOne({ phone });
        if (!user) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.USER_NOT_FOUND
            });
        }

        const isValid = await user.comparePin(pin);
        if (!isValid) {
            return reply.status(401).send({
                success: false,
                message: ERRORS.PIN_INVALID
            });
        }

        // Device check
        let device = await Device.findOne({ deviceId });

        if (!device) {
            // Check device limit
            const deviceCount = await Device.countDocuments({
                userId: user._id,
                isActive: true
            });

            if (deviceCount >= config.MAX_DEVICES) {
                return reply.status(400).send({
                    success: false,
                    message: `${ERRORS.DEVICE_LIMIT} (${config.MAX_DEVICES} ta)`
                });
            }

            device = await Device.create({
                userId: user._id,
                deviceId,
                deviceName: deviceName || 'Unknown Device',
                deviceType: deviceType || 'android',
                mode: 'parent'
            });
        }

        // Generate tokens with JTI
        const jti = crypto.randomUUID();
        const tokenFamily = crypto.randomUUID();

        const accessToken = await reply.jwtSign(
            {
                userId: user._id.toString(),
                role: user.role,
                deviceId,
                jti
            },
            { expiresIn: config.JWT_ACCESS_EXPIRES }
        );

        const refreshToken = await reply.jwtSign(
            {
                userId: user._id.toString(),
                deviceId,
                type: 'refresh',
                tokenFamily,
                version: 0
            },
            { expiresIn: config.JWT_REFRESH_EXPIRES }
        );

        // Update device with token family
        device.refreshToken = refreshToken;
        device.tokenFamily = tokenFamily;
        device.refreshTokenVersion = 0;
        device.lastSeen = new Date();
        await device.save();

        return {
            success: true,
            accessToken,
            refreshToken,
            user: {
                id: user._id,
                name: user.name,
                phone: user.phone,
                role: user.role
            }
        };
    },

    // POST /auth/refresh — Token Rotation
    async refresh(request, reply) {
        const { refreshToken } = request.body;

        try {
            const decoded = await request.jwtVerify({
                onlyCookie: false,
                token: refreshToken
            });

            if (decoded.type !== 'refresh') {
                throw new Error('Invalid token type');
            }

            const device = await Device.findOne({
                deviceId: decoded.deviceId,
                refreshToken,
                isActive: true
            });

            if (!device) {
                // Reuse detection — eski token ishlatilgan, sessiyani bekor qilish
                if (decoded.tokenFamily) {
                    await Device.updateOne(
                        { tokenFamily: decoded.tokenFamily },
                        { refreshToken: null, isActive: false }
                    );
                }
                return reply.status(401).send({
                    success: false,
                    message: ERRORS.TOKEN_INVALID
                });
            }

            const user = await User.findById(decoded.userId);
            if (!user) {
                return reply.status(401).send({
                    success: false,
                    message: ERRORS.USER_NOT_FOUND
                });
            }

            // Yangi JTI va access token
            const newJti = crypto.randomUUID();
            const accessToken = await reply.jwtSign(
                {
                    userId: user._id.toString(),
                    role: user.role,
                    deviceId: decoded.deviceId,
                    jti: newJti
                },
                { expiresIn: config.JWT_ACCESS_EXPIRES }
            );

            // Yangi refresh token (rotation)
            const newVersion = (decoded.version || 0) + 1;
            const newRefreshToken = await reply.jwtSign(
                {
                    userId: user._id.toString(),
                    deviceId: decoded.deviceId,
                    type: 'refresh',
                    tokenFamily: device.tokenFamily,
                    version: newVersion
                },
                { expiresIn: config.JWT_REFRESH_EXPIRES }
            );

            // Device da yangi refresh token saqlash
            device.refreshToken = newRefreshToken;
            device.refreshTokenVersion = newVersion;
            device.lastSeen = new Date();
            await device.save();

            return {
                success: true,
                accessToken,
                refreshToken: newRefreshToken
            };

        } catch (err) {
            return reply.status(401).send({
                success: false,
                message: ERRORS.TOKEN_INVALID
            });
        }
    },

    // POST /auth/verify-pin
    async verifyPin(request, reply) {
        const { pin } = request.body;
        const { userId } = request.user;

        const user = await User.findById(userId);
        if (!user) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.USER_NOT_FOUND
            });
        }

        const isValid = await user.comparePin(pin);
        if (!isValid) {
            return reply.status(401).send({
                success: false,
                message: ERRORS.PIN_INVALID
            });
        }

        return {
            success: true,
            message: 'PIN verified'
        };
    },

    // POST /auth/logout
    async logout(request, reply) {
        const { userId, deviceId, jti, exp } = request.user;

        // Access token ni blacklist ga qo'shish
        if (jti && exp) {
            const ttl = exp - Math.floor(Date.now() / 1000);
            if (ttl > 0) {
                await blacklistService.add(jti, ttl);
            }
        }

        const result = await Device.updateOne(
            { deviceId, userId },
            {
                refreshToken: null,
                isActive: false,
                lastSeen: new Date()
            }
        );

        if (result.matchedCount === 0) {
            return reply.status(403).send({
                success: false,
                message: ERRORS.FORBIDDEN
            });
        }

        return {
            success: true,
            message: SUCCESS.LOGGED_OUT
        };
    }
};
