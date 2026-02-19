/**
 * OTP Rate Limiter Service
 * 
 * SMS tasdiqlash kodlari uchun rate limiting va xavfsizlik:
 * - 3 marta noto'g'ri kod = 5 daqiqaga bloklash
 * - Kod muddati = 60 soniya
 * - Qayta yuborish orasidagi minimal vaqt = Payme wait qiymati
 * 
 * In-memory store (Redis kerak emas).
 * Production uchun Redis ga o'tkazish mumkin.
 */

// ============= KONSTANTALAR =============

const MAX_VERIFY_ATTEMPTS = 3;          // Maksimal noto'g'ri urinishlar
const BLOCK_DURATION_MS = 5 * 60 * 1000; // 5 daqiqa bloklash
const CODE_EXPIRY_MS = 60 * 1000;        // 1 daqiqa kod muddati
const MIN_RESEND_GAP_MS = 60 * 1000;     // Minimal qayta yuborish intervali
const CLEANUP_INTERVAL_MS = 10 * 60 * 1000; // 10 daqiqada tozalash

// ============= IN-MEMORY STORE =============

/**
 * Store tuzilmasi:
 * verifyAttempts: Map<userId, { count, lastAttemptAt }>
 * blocks: Map<userId, { blockedUntil }>
 * codeSessions: Map<userId, { sentAt, token, expiresAt }>
 */
const verifyAttempts = new Map();
const blocks = new Map();
const codeSessions = new Map();

// Eskirgan yozuvlarni tozalash (memory leak oldini olish)
setInterval(() => {
    const now = Date.now();

    // Eskirgan bloklarni o'chirish
    for (const [userId, data] of blocks.entries()) {
        if (now > data.blockedUntil) {
            blocks.delete(userId);
        }
    }

    // 30 daqiqadan eski urinishlarni o'chirish
    const staleThreshold = now - 30 * 60 * 1000;
    for (const [userId, data] of verifyAttempts.entries()) {
        if (data.lastAttemptAt < staleThreshold) {
            verifyAttempts.delete(userId);
        }
    }

    // Eskirgan kod sessionlarni o'chirish
    for (const [userId, data] of codeSessions.entries()) {
        if (now > data.expiresAt + 5 * 60 * 1000) {
            codeSessions.delete(userId);
        }
    }
}, CLEANUP_INTERVAL_MS);

// ============= BLOKLASH =============

/**
 * Foydalanuvchi bloklangan yoki yo'qligini tekshirish
 * @param {string} userId
 * @returns {{ blocked: boolean, remainingSeconds?: number }}
 */
function isBlocked(userId) {
    const block = blocks.get(userId);
    if (!block) {
        return { blocked: false };
    }

    const now = Date.now();
    if (now >= block.blockedUntil) {
        // Blok muddati tugagan — tozalash
        blocks.delete(userId);
        verifyAttempts.delete(userId);
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
function blockUser(userId) {
    blocks.set(userId, {
        blockedUntil: Date.now() + BLOCK_DURATION_MS,
    });
}

// ============= VERIFY URINISHLARI =============

/**
 * Noto'g'ri verify urinishini qayd etish
 * @param {string} userId
 * @returns {{ attemptsLeft: number, blocked: boolean, remainingSeconds?: number }}
 */
function recordFailedAttempt(userId) {
    const existing = verifyAttempts.get(userId) || { count: 0 };

    existing.count += 1;
    existing.lastAttemptAt = Date.now();
    verifyAttempts.set(userId, existing);

    if (existing.count >= MAX_VERIFY_ATTEMPTS) {
        // Limitga yetdi — bloklash
        blockUser(userId);
        verifyAttempts.delete(userId);

        const blockInfo = isBlocked(userId);
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
function resetAttempts(userId) {
    verifyAttempts.delete(userId);
    blocks.delete(userId);
    codeSessions.delete(userId);
}

/**
 * Qolgan urinishlar sonini olish
 * @param {string} userId
 * @returns {number}
 */
function getAttemptsLeft(userId) {
    const existing = verifyAttempts.get(userId);
    if (!existing) return MAX_VERIFY_ATTEMPTS;
    return Math.max(0, MAX_VERIFY_ATTEMPTS - existing.count);
}

// ============= KOD SESSIYASI =============

/**
 * SMS kod yuborilganini qayd etish
 * @param {string} userId
 * @param {string} token - karta tokeni
 */
function recordCodeSent(userId, token) {
    codeSessions.set(userId, {
        sentAt: Date.now(),
        token,
        expiresAt: Date.now() + CODE_EXPIRY_MS,
    });
}

/**
 * Kod muddati o'tganmi tekshirish
 * @param {string} userId
 * @returns {{ expired: boolean, remainingSeconds?: number }}
 */
function isCodeExpired(userId) {
    const session = codeSessions.get(userId);
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
 * @returns {{ canResend: boolean, waitSeconds?: number }}
 */
function canResendCode(userId) {
    const session = codeSessions.get(userId);
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
        activeBlocks: blocks.size,
        activeSessions: codeSessions.size,
        trackingAttempts: verifyAttempts.size,
    };
}

module.exports = {
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
