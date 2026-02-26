const crypto = require('crypto');
const { User, Device } = require('../models');
const smsService = require('../services/sms.service');
const blacklistService = require('../services/blacklist.service');
const config = require('../config/env');
const { REDIS_KEYS, ERRORS, SUCCESS } = require('../config/constants');

module.exports = {

    // POST /auth/send-otp
    async sendOtp(request, reply) {
        const { phone, purpose } = request.body;
        const redis = this.redis;

        // Rate limit check
        // [FIX SEC-2] Test phone faqat STRICT development da bypass
        const attemptsKey = `${REDIS_KEYS.OTP_ATTEMPTS}${phone}`;
        const isTestBypass = config.NODE_ENV === 'development' && config.TEST_PHONE && phone === config.TEST_PHONE;
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
            const smsResult = await smsService.sendOtp(phone, code, purpose || 'register');

            // SMS yuborilmagan bo'lsa — OTPni o'chirish va xato qaytarish
            if (!smsResult.success) {
                await redis.del(otpKey);
                return reply.status(503).send({
                    success: false,
                    message: smsResult.error || 'SMS xizmati vaqtincha ishlamayapti'
                });
            }
        } catch (err) {
            request.log.error('SMS sending failed:', err);
            await redis.del(otpKey);
            return reply.status(503).send({
                success: false,
                message: 'SMS xizmati vaqtincha ishlamayapti. Keyinroq urinib ko\'ring.'
            });
        }

        // [FIX SEC-1] OTP kodi hech qachon API responseda qaytarilmaydi
        // OTP faqat SMS orqali yuboriladi — bu backdoor edi
        return { success: true, message: SUCCESS.OTP_SENT };
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
        const { phone, name, pin, verifiedToken } = request.body;
        const redis = this.redis;

        // [FIX CRIT-4] verifiedToken ni tekshirish — soxta ro'yxatdan o'tishning oldini oladi
        const savedToken = await redis.get(`${REDIS_KEYS.VERIFIED}${phone}`);
        if (!savedToken || savedToken !== verifiedToken) {
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
            user: {
                id: user._id,
                phone: user.phone,
                name: user.name,
                role: user.role,
                createdAt: user.createdAt,
            }
        };
    },

    // POST /auth/reset-pin
    async resetPin(request, reply) {
        const { phone, newPin, verifiedToken } = request.body;
        const redis = this.redis;

        // [FIX CRIT-4] verifiedToken ni tekshirish
        const savedToken = await redis.get(`${REDIS_KEYS.VERIFIED}${phone}`);
        if (!savedToken || savedToken !== verifiedToken) {
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

        // Device check — avval deviceId bo'yicha qidirish
        let device = await Device.findOne({ deviceId });
        let deviceMode = 'parent';

        if (!device) {
            // Yangi qurilma — yaratish
            const existingDevices = await Device.countDocuments({
                userId: user._id,
                isActive: true
            });

            if (existingDevices >= config.MAX_DEVICES) {
                return reply.status(400).send({
                    success: false,
                    message: `${ERRORS.DEVICE_LIMIT} (${config.MAX_DEVICES} ta)`
                });
            }

            if (existingDevices > 0) {
                deviceMode = 'child';
            }

            device = await Device.create({
                userId: user._id,
                deviceId,
                deviceName: deviceName || 'Unknown Device',
                deviceType: deviceType || 'android',
                mode: deviceMode
            });
        } else if (device.userId.toString() !== user._id.toString()) {
            // Qurilma boshqa userga tegishli — yangi userga o'tkazish (re-register)
            const existingDevices = await Device.countDocuments({
                userId: user._id,
                isActive: true
            });

            if (existingDevices > 0) {
                deviceMode = 'child';
            }

            device.userId = user._id;
            device.mode = deviceMode;
            device.isActive = true;
            device.status = 'active';
            if (deviceName) device.deviceName = deviceName;
            if (deviceType) device.deviceType = deviceType;
        } else {
            // Mavjud qurilma — shu userga tegishli
            deviceMode = device.mode;

            if (deviceName && device.deviceName === 'Unknown Device') {
                device.deviceName = deviceName;
            }
            if (deviceType && device.deviceType !== deviceType) {
                device.deviceType = deviceType;
            }
            if (!device.isActive) {
                device.isActive = true;
                device.status = 'active';
            }
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

        // [FIX SEC-8] Refresh tokenni hash qilib saqlash — DB dump himoyasi
        const refreshTokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');
        device.refreshToken = refreshTokenHash;
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
            },
            deviceMode
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

            // [FIX SEC-8] Refresh token hash bilan solishtirish
            const incomingHash = crypto.createHash('sha256').update(refreshToken).digest('hex');
            const device = await Device.findOne({
                deviceId: decoded.deviceId,
                refreshToken: incomingHash,
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

            // [FIX SEC-8] Yangi refresh tokenni hash qilib saqlash
            const newRefreshHash = crypto.createHash('sha256').update(newRefreshToken).digest('hex');
            device.refreshToken = newRefreshHash;
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
    },

    // PUT /auth/profile - Profilni yangilash
    async updateProfile(request, reply) {
        const { userId } = request.user;
        const { name } = request.body;

        const user = await User.findById(userId);
        if (!user) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.USER_NOT_FOUND
            });
        }

        if (name) user.name = name;
        await user.save();

        return {
            success: true,
            message: 'Profil yangilandi',
            user: {
                id: user._id,
                phone: user.phone,
                name: user.name,
                role: user.role,
                createdAt: user.createdAt,
            }
        };
    }
};
