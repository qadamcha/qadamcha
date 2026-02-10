/**
 * Crypto Utilities
 * Kriptografik yordamchi funksiyalar
 */

const crypto = require('crypto');

/**
 * Kuchli random secret generatsiya qilish
 * @param {number} length - Secret uzunligi (bytes)
 * @returns {string} Hex formatda secret
 */
function generateSecret(length = 32) {
    return crypto.randomBytes(length).toString('hex');
}

/**
 * URL-safe random string generatsiya
 * @param {number} length - String uzunligi
 * @returns {string} URL-safe random string
 */
function generateUrlSafeToken(length = 32) {
    return crypto.randomBytes(length)
        .toString('base64')
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=/g, '');
}

/**
 * String ni hash qilish (SHA-256)
 * @param {string} data - Hash qilinadigan ma'lumot
 * @returns {string} Hash
 */
function hashSha256(data) {
    return crypto.createHash('sha256').update(data).digest('hex');
}

/**
 * HMAC yaratish
 * @param {string} data - Ma'lumot
 * @param {string} secret - Secret key
 * @returns {string} HMAC
 */
function createHmac(data, secret) {
    return crypto.createHmac('sha256', secret).update(data).digest('hex');
}

/**
 * Ikki stringni xavfsiz taqqoslash (timing attack'dan himoya)
 * @param {string} a - Birinchi string
 * @param {string} b - Ikkinchi string
 * @returns {boolean} Teng yoki yo'q
 */
function secureCompare(a, b) {
    if (typeof a !== 'string' || typeof b !== 'string') {
        return false;
    }

    const bufA = Buffer.from(a);
    const bufB = Buffer.from(b);

    if (bufA.length !== bufB.length) {
        return false;
    }

    return crypto.timingSafeEqual(bufA, bufB);
}

/**
 * UUID v4 generatsiya
 * @returns {string} UUID
 */
function generateUuid() {
    return crypto.randomUUID();
}

/**
 * Parolni hash qilish uchun key derivation (PBKDF2)
 * Bunday faqat agar bcrypt ishlatilmasa
 */
function deriveKey(password, salt, iterations = 100000) {
    return new Promise((resolve, reject) => {
        crypto.pbkdf2(password, salt, iterations, 64, 'sha512', (err, derivedKey) => {
            if (err) reject(err);
            else resolve(derivedKey.toString('hex'));
        });
    });
}

/**
 * Random salt generatsiya
 */
function generateSalt(length = 16) {
    return crypto.randomBytes(length).toString('hex');
}

module.exports = {
    generateSecret,
    generateUrlSafeToken,
    hashSha256,
    createHmac,
    secureCompare,
    generateUuid,
    deriveKey,
    generateSalt
};
