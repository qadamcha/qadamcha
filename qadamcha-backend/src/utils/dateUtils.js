/**
 * Date Utilities — O'zbekiston vaqt zonasi (UTC+5)
 * 
 * Barcha "bugun" hisob-kitoblari UTC+5 da amalga oshiriladi.
 * App (Flutter) ham xuddi shu vaqt zonasini ishlatadi:
 *   DateTime.now().toUtc().add(Duration(hours: 5))
 * 
 * Bu backend va app o'rtasida kun almashish sinxronligini ta'minlaydi.
 */

const UZ_OFFSET_HOURS = 5;

// ═══════════════════════════════════════════════════════════════════
// 🧪 TEST MODE — Test tugagach TEST_MODE = false qilib qo'ying!
// Har 5 daqiqada "kun" almashadi, har 35 daqiqada "hafta" almashadi
// App (local_monitoring_service.dart) da ham xuddi shu flag bor
// ═══════════════════════════════════════════════════════════════════
const TEST_MODE = true;
const TEST_DAY_DURATION_MS = 5 * 60 * 1000; // 5 daqiqa = 1 "kun"

/**
 * O'zbekiston vaqtida hozirgi Date objektini qaytaradi
 * @returns {Date}
 */
function nowUzbekistan() {
    if (TEST_MODE) {
        return _virtualNow();
    }
    return new Date(Date.now() + UZ_OFFSET_HOURS * 60 * 60 * 1000);
}

/**
 * O'zbekiston vaqtida bugungi sanani "YYYY-MM-DD" formatida qaytaradi
 * @returns {string}
 */
function todayUzbekistan() {
    if (TEST_MODE) {
        return _virtualToday();
    }
    return nowUzbekistan().toISOString().split('T')[0];
}

// ─── Test helpers ────────────────────────────────────────────────────

/**
 * Virtual "bugun" — har 5 daqiqada yangi kun
 * Formula: virtualDayNumber = floor(epoch / 5min)
 * Base date: 2026-01-01 + virtualDayNumber kunlar
 * App da ham xuddi SHU formula ishlatiladi
 */
function _virtualToday() {
    const epoch = Date.now();
    const virtualDayNumber = Math.floor(epoch / TEST_DAY_DURATION_MS);
    // Base date dan virtualDayNumber kun qo'shish
    const base = new Date(2026, 0, 1); // Jan 1, 2026
    base.setDate(base.getDate() + (virtualDayNumber % 365));
    const result = base.toISOString().split('T')[0];
    console.log(`🧪 [TEST] virtualDay #${virtualDayNumber} → ${result} (next change in ${_msUntilNextDay()}s)`);
    return result;
}

/**
 * Virtual "now" — sana virtual, soat real
 */
function _virtualNow() {
    const epoch = Date.now();
    const virtualDayNumber = Math.floor(epoch / TEST_DAY_DURATION_MS);
    const base = new Date(2026, 0, 1);
    base.setDate(base.getDate() + (virtualDayNumber % 365));
    // Soat/daqiqani real vaqtdan olish
    const real = new Date(epoch + UZ_OFFSET_HOURS * 60 * 60 * 1000);
    base.setHours(real.getUTCHours(), real.getUTCMinutes(), real.getUTCSeconds());
    return base;
}

/**
 * Keyingi "kun" almashishigacha qolgan soniyalar
 */
function _msUntilNextDay() {
    const epoch = Date.now();
    const remaining = TEST_DAY_DURATION_MS - (epoch % TEST_DAY_DURATION_MS);
    return Math.round(remaining / 1000);
}

module.exports = { nowUzbekistan, todayUzbekistan, UZ_OFFSET_HOURS, TEST_MODE };
