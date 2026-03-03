const { Child } = require('../models');
const { todayUzbekistan } = require('../utils/dateUtils');

/**
 * Daily Reset Middleware — todayUsage kunlik lazy reset
 * 
 * Har bir GET /children so'rovida lastUsageDate tekshiriladi.
 * Agar bugungi sana emas — todayUsage avtomatik reset qilinadi.
 * 
 * Afzalliklari (cron job o'rniga):
 * - Serverless platformalarda (Railway, Vercel) ishonchli ishlaydi
 * - Cron job'ga bog'liq emas
 * - Faqat kerak paytda ishlaydi (lazy evaluation)
 */
async function dailyResetMiddleware(request, reply) {
    try {
        const { userId } = request.user;
        if (!userId) return;

        const today = todayUzbekistan();

        // Bugungi sana bilan mos kelmaydigan bolalarni topib, reset qilish
        await Child.updateMany(
            {
                parentId: userId,
                isActive: true,
                $or: [
                    { lastUsageDate: { $ne: today } },
                    { lastUsageDate: { $exists: false } }
                ]
            },
            {
                $set: {
                    'todayUsage.minutesUsed': 0,
                    'todayUsage.videosWatched': 0,
                    'todayUsage.gamesPlayed': 0,
                    'todayUsage.storiesRead': 0,
                    lastUsageDate: today
                }
            }
        );
    } catch (err) {
        // Reset xatosi so'rovni to'xtatmasin — graceful fallback
        request.log.error('Daily reset middleware error:', err.message);
    }
}

module.exports = { dailyResetMiddleware };
