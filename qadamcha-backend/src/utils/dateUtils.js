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

/**
 * O'zbekiston vaqtida hozirgi Date objektini qaytaradi
 * @returns {Date}
 */
function nowUzbekistan() {
    return new Date(Date.now() + UZ_OFFSET_HOURS * 60 * 60 * 1000);
}

/**
 * O'zbekiston vaqtida bugungi sanani "YYYY-MM-DD" formatida qaytaradi
 * @returns {string}
 */
function todayUzbekistan() {
    return nowUzbekistan().toISOString().split('T')[0];
}

module.exports = { nowUzbekistan, todayUzbekistan, UZ_OFFSET_HOURS };
