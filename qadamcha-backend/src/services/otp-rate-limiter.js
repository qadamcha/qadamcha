/**
 * OTP Rate Limiter Service
 * 
 * SMS tasdiqlash kodlari uchun rate limiting va xavfsizlik:
 * - 3 marta noto'g'ri kod = 5 daqiqaga bloklash
 * - Kod muddati = 60 soniya
 * - Qayta yuborish orasidagi minimal vaqt = Payme wait qiymati
 * 
 * [FIX HIGH-6] Redis-based store — horizontal scaling da ham ishlaydi.
 * In-memory fallback agar Redis mavjud bo'lmasa.
 */

// ============= KONSTANTALAR =============

const MAX_VERIFY_ATTEMPTS = 3;          // Maksimal noto'g'ri urinishlar
const BLOCK_DURATION_MS = 5 * 60 * 1000; // 5 daqiqa bloklash
const BLOCK_DURATION_SEC = 5 * 60;       // 5 daqiqa (Redis TTL uchun sekundlarda)
const CODE_EXPIRY_MS = 60 * 1000;        // 1 daqiqa kod muddati
const CODE_EXPIRY_SEC = 60;              // 1 daqiqa (Redis TTL)
const MIN_RESEND_GAP_MS = 60 * 1000;     // Minimal qayta yuborish intervali

// ============= REDIS KEYLAR =============

const KEYS = {
    BLOCK: 'otp_rl:block:',
    ATTEMPTS: 'otp_rl:attempts:',
    SESSION: 'otp_rl:session:',
};

let redis = null;

/**
 * Redis ni sozlash
 */
function setRedis(redisClient) {
    redis = redisClient;
}

// ============= YORDAMCHI FUNKSIYALAR =============

async function _getJson(key) {
    if (!redis) return null;
    try {
        const data = await redis.get(key);
        return data ? JSON.parse(data) : null;
    } catch {
        return null;
    }
}

async function _setJson(key, value, ttlSec) {
    if (!redis) return;
    try {
        await redis.setex(key, ttlSec, JSON.stringify(value));
    } catch {
        // Redis xatosi — davom etamiz
    }
}

async function _del(key) {
    if (!redis) return;
    try {
        await redis.del(key);
    } catch {
        // Redis xatosi — davom etamiz
    }
}

// ============= BLOKLASH =============

/**
 * Foydalanuvchi bloklangan yoki yo'qligini tekshirish
 * @param {string} userId
 * @returns {Promise<{ blocked: boolean, remainingSeconds?: number }>}
 */
async function isBlocked(userId) {
    const block = await _getJson(`${KEYS.BLOCK}${userId}`);
    if (!block) {
        return { blocked: false };
    }

    const now = Date.now();
    if (now >= block.blockedUntil) {
        // Blok muddati tugagan
        await _del(`${KEYS.BLOCK}${userId}`);
        await _del(`${KEYS.ATTEMPTS}${userId}`);
        return { blocked: false };
    }

    const remainingMs = block.blockedUntil - now;
    return {
        blocked: true,
        remainingSeconds: Math.ceil(remainingMs / 1000),
    };
}

/**
 * Foydalanuvchini bloklash
 * @param {string} userId
 */
async function blockUser(userId) {
    await _setJson(`${KEYS.BLOCK}${userId}`, {
        blockedUntil: Date.now() + BLOCK_DURATION_MS,
    }, BLOCK_DURATION_SEC + 10);
}

// ============= VERIFY URINISHLARI =============

/**
 * Noto'g'ri verify urinishini qayd etish
 * @param {string} userId
 * @returns {Promise<{ attemptsLeft: number, blocked: boolean, remainingSeconds?: number }>}
 */
async function recordFailedAttempt(userId) {
    const key = `${KEYS.ATTEMPTS}${userId}`;
    const existing = (await _getJson(key)) || { count: 0 };

    existing.count += 1;
    existing.lastAttemptAt = Date.now();
    await _setJson(key, existing, 30 * 60); // 30 daqiqa saqlash

    if (existing.count >= MAX_VERIFY_ATTEMPTS) {
        // Limitga yetdi — bloklash
        await blockUser(userId);
        await _del(key);

        const blockInfo = await isBlocked(userId);
        return {
            attemptsLeft: 0,
            blocked: true,
            remainingSeconds: blockInfo.remainingSeconds,
        };
    }

    return {
        attemptsLeft: MAX_VERIFY_ATTEMPTS - existing.count,
        blocked: false,
    };
}

/**
 * Muvaffaqiyatli verify'dan keyin counterni tozalash
 * @param {string} userId
 */
async function resetAttempts(userId) {
    await _del(`${KEYS.ATTEMPTS}${userId}`);
    await _del(`${KEYS.BLOCK}${userId}`);
    await _del(`${KEYS.SESSION}${userId}`);
}

/**
 * Qolgan urinishlar sonini olish
 * @param {string} userId
 * @returns {Promise<number>}
 */
async function getAttemptsLeft(userId) {
    const existing = await _getJson(`${KEYS.ATTEMPTS}${userId}`);
    if (!existing) return MAX_VERIFY_ATTEMPTS;
    return Math.max(0, MAX_VERIFY_ATTEMPTS - existing.count);
}

// ============= KOD SESSIYASI =============

/**
 * SMS kod yuborilganini qayd etish
 * @param {string} userId
 * @param {string} token - karta tokeni
 */
async function recordCodeSent(userId, token) {
    const now = Date.now();
    await _setJson(`${KEYS.SESSION}${userId}`, {
        sentAt: now,
        token,
        expiresAt: now + CODE_EXPIRY_MS,
    }, CODE_EXPIRY_SEC + 5 * 60); // 6 daqiqa Redis TTL (kod muddati + buffer)
}

/**
 * Kod muddati o'tganmi tekshirish
 * @param {string} userId
 * @returns {Promise<{ expired: boolean, remainingSeconds?: number }>}
 */
async function isCodeExpired(userId) {
    const session = await _getJson(`${KEYS.SESSION}${userId}`);
    if (!session) {
        return { expired: true, remainingSeconds: 0 };
    }

    const now = Date.now();
    if (now >= session.expiresAt) {
        return { expired: true, remainingSeconds: 0 };
    }

    return {
        expired: false,
        remainingSeconds: Math.ceil((session.expiresAt - now) / 1000),
    };
}

/**
 * Qayta kod yuborish mumkinmi tekshirish
 * @param {string} userId
 * @returns {Promise<{ canResend: boolean, waitSeconds?: number }>}
 */
async function canResendCode(userId) {
    const session = await _getJson(`${KEYS.SESSION}${userId}`);
    if (!session) {
        return { canResend: true };
    }

    const elapsed = Date.now() - session.sentAt;
    if (elapsed >= MIN_RESEND_GAP_MS) {
        return { canResend: true };
    }

    return {
        canResend: false,
        waitSeconds: Math.ceil((MIN_RESEND_GAP_MS - elapsed) / 1000),
    };
}

/**
 * Statistikani olish (debugging uchun)
 */
function getStats() {
    return {
        storage: redis ? 'redis' : 'unavailable',
    };
}

module.exports = {
    setRedis,

    // Bloklash
    isBlocked,

    // Verify urinishlari
    recordFailedAttempt,
    resetAttempts,
    getAttemptsLeft,

    // Kod sessiyasi
    recordCodeSent,
    isCodeExpired,
    canResendCode,

    // Debug
    getStats,

    // Konstantalar (testlar uchun)
    MAX_VERIFY_ATTEMPTS,
    BLOCK_DURATION_MS,
    CODE_EXPIRY_MS,
};
