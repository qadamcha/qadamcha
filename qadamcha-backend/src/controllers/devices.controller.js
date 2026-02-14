const { Device, Child } = require('../models');
const config = require('../config/env');
const { ERRORS, SUCCESS } = require('../config/constants');

module.exports = {

    // GET /devices - Foydalanuvchi qurilmalari
    async getAll(request, reply) {
        const { userId } = request.user;

        const devices = await Device.find({ userId, isActive: true })
            .populate('childId', 'name age')
            .sort({ lastSeen: -1 });

        return {
            success: true,
            devices,
            maxDevices: config.MAX_DEVICES
        };
    },

    // POST /devices/generate-code - Oila kodini yaratish
    async generateFamilyCode(request, reply) {
        const { userId, deviceId } = request.user;

        const device = await Device.findOne({ userId, deviceId, isActive: true });
        if (!device) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        // Yangi oila kodi (crypto-secure)
        const familyCode = await Device.generateFamilyCode();
        const expires = new Date(Date.now() + 10 * 60 * 1000); // 10 daqiqa

        device.familyCode = familyCode;
        device.familyCodeExpires = expires;
        await device.save();

        return {
            success: true,
            familyCode,
            expiresAt: expires,
            message: 'Oila kodi yaratildi (10 daqiqa amal qiladi)'
        };
    },

    // POST /devices/link - Qurilmani ulash (bola qurilmasi tomonidan)
    async linkDevice(request, reply) {
        const { familyCode, childId, deviceId, deviceName, deviceType } = request.body;

        // Oila kodini tekshirish
        const parentDevice = await Device.findOne({
            familyCode,
            familyCodeExpires: { $gt: new Date() },
            isActive: true
        });

        if (!parentDevice) {
            return reply.status(400).send({
                success: false,
                message: 'Kod noto\'g\'ri yoki muddati tugagan'
            });
        }

        // Bola mavjudligini tekshirish
        const child = await Child.findOne({
            _id: childId,
            parentId: parentDevice.userId,
            isActive: true
        });

        if (!child) {
            return reply.status(400).send({
                success: false,
                message: 'Bola topilmadi'
            });
        }

        // Qurilma limiti
        const deviceCount = await Device.countDocuments({
            userId: parentDevice.userId,
            isActive: true
        });

        if (deviceCount >= config.MAX_DEVICES) {
            return reply.status(400).send({
                success: false,
                message: `Maksimal ${config.MAX_DEVICES} ta qurilma ulash mumkin`
            });
        }

        // Yangi qurilma yaratish (bola rejimi)
        const newDevice = await Device.create({
            userId: parentDevice.userId,
            childId: child._id,
            deviceId,
            deviceName: deviceName || 'Bola qurilmasi',
            deviceType: deviceType || 'android',
            mode: 'child'
        });

        // Oila kodini o'chirish
        parentDevice.familyCode = null;
        parentDevice.familyCodeExpires = null;
        await parentDevice.save();

        return {
            success: true,
            message: SUCCESS.DEVICE_LINKED,
            device: newDevice,
            child: {
                id: child._id,
                name: child.name,
                age: child.age,
                dailyLimit: child.dailyLimit
            }
        };
    },

    // PUT /devices/:id - Qurilmani yangilash
    async update(request, reply) {
        const { userId } = request.user;
        const { id } = request.params;
        const { deviceName, childId } = request.body;

        const updates = {};
        if (deviceName) updates.deviceName = deviceName;

        // childId bo'lsa — ownership tekshirish
        if (childId) {
            const child = await Child.findOne({
                _id: childId,
                parentId: userId,
                isActive: true
            });
            if (!child) {
                return reply.status(403).send({
                    success: false,
                    message: ERRORS.FORBIDDEN
                });
            }
            updates.childId = childId;
        }

        const device = await Device.findOneAndUpdate(
            { _id: id, userId, isActive: true },
            { $set: updates },
            { new: true }
        );

        if (!device) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        return { success: true, message: SUCCESS.UPDATED, device };
    },

    // DELETE /devices/:id - Qurilmani o'chirish
    async delete(request, reply) {
        const { userId } = request.user;
        const { id } = request.params;

        const device = await Device.findOneAndUpdate(
            { _id: id, userId },
            {
                isActive: false,
                refreshToken: null,
                familyCode: null
            },
            { new: true }
        );

        if (!device) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        return { success: true, message: SUCCESS.DELETED };
    },

    // PUT /devices/fcm-token - FCM tokenni saqlash
    async updateFcmToken(request, reply) {
        const { deviceId } = request.user;
        const { fcmToken } = request.body;

        if (!fcmToken) {
            return reply.status(400).send({
                success: false,
                message: 'fcmToken majburiy'
            });
        }

        const result = await Device.updateOne(
            { deviceId, isActive: true },
            { fcmToken }
        );

        if (result.matchedCount === 0) {
            return reply.status(404).send({
                success: false,
                message: ERRORS.NOT_FOUND
            });
        }

        return { success: true, message: 'FCM token yangilandi' };
    },

    // POST /devices/:id/heartbeat - Qurilma online statusini yangilash
    async heartbeat(request, reply) {
        const { deviceId } = request.user;

        const result = await Device.updateOne(
            { deviceId, isActive: true },
            { lastSeen: new Date() }
        );

        if (result.matchedCount === 0) {
            return reply.status(404).send({
                success: false,
                message: 'Qurilma topilmadi yoki faol emas'
            });
        }

        return { success: true };
    }
};
