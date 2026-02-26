/**
 * User Controller
 * Foydalanuvchi profili boshqaruvi
 */

const { User, Child, Device, Subscription } = require('../models');
const bcrypt = require('bcryptjs');

module.exports = {

    // GET /user/profile — Profil olish
    async getProfile(request, reply) {
        const { userId } = request.user;

        const user = await User.findById(userId).select('-pin');

        if (!user) {
            return reply.status(404).send({
                success: false,
                message: 'Foydalanuvchi topilmadi'
            });
        }

        // Qo'shimcha ma'lumotlar
        const [childrenCount, devicesCount, subscription] = await Promise.all([
            Child.countDocuments({ parentId: userId, isActive: true }),
            Device.countDocuments({ userId, isActive: true }),
            Subscription.getActive(userId)
        ]);

        return {
            success: true,
            user: {
                id: user._id,
                phone: user.phone,
                name: user.name,
                role: user.role,
                avatar: user.avatar,
                createdAt: user.createdAt
            },
            stats: {
                childrenCount,
                devicesCount,
                hasSubscription: !!subscription,
                subscriptionPlan: subscription?.plan || null,
                subscriptionEndDate: subscription?.endDate || null
            }
        };
    },

    // PUT /user/profile — Profil yangilash
    async updateProfile(request, reply) {
        const { userId } = request.user;
        const { name, avatar } = request.body;

        const updateData = {};
        if (name !== undefined) updateData.name = name;
        if (avatar !== undefined) updateData.avatar = avatar;

        if (Object.keys(updateData).length === 0) {
            return reply.status(400).send({
                success: false,
                message: 'Yangilash uchun ma\'lumot kiritilmagan'
            });
        }

        const user = await User.findByIdAndUpdate(
            userId,
            updateData,
            { new: true, runValidators: true }
        ).select('-pin');

        if (!user) {
            return reply.status(404).send({
                success: false,
                message: 'Foydalanuvchi topilmadi'
            });
        }

        return {
            success: true,
            message: 'Profil yangilandi',
            user: {
                id: user._id,
                phone: user.phone,
                name: user.name,
                role: user.role,
                avatar: user.avatar
            }
        };
    },

    // PUT /user/pin — PIN o'zgartirish
    async changePin(request, reply) {
        const { userId } = request.user;
        const { currentPin, newPin } = request.body;

        const user = await User.findById(userId);
        if (!user) {
            return reply.status(404).send({
                success: false,
                message: 'Foydalanuvchi topilmadi'
            });
        }

        // Joriy PIN tekshirish
        const isMatch = await user.comparePin(currentPin);
        if (!isMatch) {
            return reply.status(400).send({
                success: false,
                message: 'Joriy PIN noto\'g\'ri'
            });
        }

        // Yangi PIN saqlash (pre-save hook hash qiladi)
        user.pin = newPin;
        await user.save();

        return {
            success: true,
            message: 'PIN muvaffaqiyatli o\'zgartirildi'
        };
    },

    // DELETE /user/profile - Hisobni o'chirish
    // [FIX MED-7] Aktiv obuna va pending to'lovlarni tekshirish
    async deleteAccount(request, reply) {
        const { userId } = request.user;

        // Aktiv obunani tekshirish
        const activeSubscription = await Subscription.getActive(userId);
        if (activeSubscription) {
            return reply.status(400).send({
                success: false,
                message: 'Aktiv obunangiz bor. Avval obunani bekor qiling'
            });
        }

        // Pending to'lovni tekshirish
        const pendingSubscription = await Subscription.findOne({
            userId, status: { $in: ['pending', 'processing'] }
        });
        if (pendingSubscription) {
            return reply.status(400).send({
                success: false,
                message: 'Kutilayotgan to\'lov mavjud. Avval to\'lovni yakunlang yoki bekor qiling'
            });
        }

        const user = await User.findById(userId);
        if (!user) {
            return reply.status(404).send({
                success: false,
                message: 'Foydalanuvchi topilmadi'
            });
        }

        // Soft delete
        user.isActive = false;
        await user.save();

        // Bolalar va qurilmalarni deaktivatsiya
        await Promise.all([
            Child.updateMany({ parentId: userId }, { isActive: false }),
            Device.updateMany({ userId }, { isActive: false })
        ]);

        return {
            success: true,
            message: 'Akkount o\'chirildi'
        };
    }
};
