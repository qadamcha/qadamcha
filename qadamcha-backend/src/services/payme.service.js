/**
 * Payme Subscribe API Service
 * 
 * Payme Subscribe API bilan HTTP aloqa (JSON-RPC 2.0).
 * Barcha karta va chek operatsiyalari shu yerdan amalga oshiriladi.
 * 
 * API URL: https://checkout.test.paycom.uz/api (test)
 *          https://checkout.paycom.uz/api (production)
 * 
 * XAVFSIZLIK:
 * - cards.* metodlari uchun X-Auth: faqat MERCHANT_ID
 * - receipts.* metodlari uchun X-Auth: MERCHANT_ID:KEY
 * - Karta raqamlari hech qachon serverda saqlanmaydi
 * - Faqat tokenlar ishlatiladi
 */

const axios = require('axios');
const config = require('../config/env');

// ============= INTERNAL HELPERS =============

/**
 * Payme API ga JSON-RPC 2.0 so'rov yuborish
 * 
 * Rasmiy dokumentatsiya bo'yicha:
 * - cards.* metodlari: X-Auth faqat MERCHANT_ID (Paycom ID kassa)
 * - receipts.* metodlari: X-Auth = MERCHANT_ID:PAYME_KEY (ID:Password)
 * 
 * @param {string} method - API metod nomi (masalan: 'cards.create')
 * @param {object} params - Metod parametrlari
 * @returns {Promise<object>} - API javobi
 */
async function _callPayme(method, params = {}) {
    // Auth header — metodga qarab farq qiladi
    let authHeader;
    if (method.startsWith('cards.')) {
        // cards.* — faqat Paycom ID (kassani aniqlash uchun)
        authHeader = config.PAYME_MERCHANT_ID;
    } else {
        // receipts.* — ID:KEY (to'liq avtorizatsiya)
        authHeader = `${config.PAYME_MERCHANT_ID}:${config.PAYME_KEY}`;
    }

    const payload = {
        id: Date.now(),
        method,
        params,
    };

    try {
        const response = await axios.post(config.PAYME_API_URL, payload, {
            headers: {
                'Content-Type': 'application/json',
                'X-Auth': authHeader,
                'Cache-Control': 'no-cache',
            },
            timeout: 30000, // 30 soniya timeout (to'lov uchun ko'proq vaqt)
        });

        const data = response.data;

        // Payme xato qaytargan bo'lsa
        if (data.error) {
            const errorMsg = _getPaymeErrorMessage(data.error.code) || data.error.message || 'Payme xatosi';
            const errorDetail = data.error.data ? ` [${data.error.data}]` : '';

            const err = new Error(errorMsg + errorDetail);
            err.code = data.error.code;
            err.paymeData = data.error.data;
            err._isPaymeError = true; // Payme xatosini aniq belgilash
            throw err;
        }

        return data.result;
    } catch (error) {
        // Payme xatosi — qayta throw
        if (error._isPaymeError) {
            throw error;
        }

        // Axios xatosi (network, timeout)
        const networkError = new Error(
            error.response?.data?.error?.message || error.message || 'Payme bilan aloqa xatosi'
        );
        networkError.code = error.response?.status || -1;
        throw networkError;
    }
}

/**
 * Payme xato kodlarini o'zbekcha xabarga aylantirish
 * 
 * Rasmiy xato kodlari:
 * https://developer.help.paycom.uz/protokol-subscribe-api
 */
function _getPaymeErrorMessage(code) {
    const errors = {
        // Avtorizatsiya xatolari
        '-32504': 'Payme avtorizatsiya xatosi (ID yoki Key noto\'g\'ri/serverda topilmadi)',
        '-32600': 'Noto\'g\'ri so\'rov formati',
        '-32601': 'Metod topilmadi',
        '-32602': 'Noto\'g\'ri parametrlar',
        '-32603': 'Ichki server xatosi',

        // Karta xatolari
        '-31300': 'Karta raqami noto\'g\'ri',
        '-31301': 'Karta muddati o\'tgan',
        '-31302': 'Karta topilmadi',
        '-31303': 'Karta saqlash xizmati ruxsat etilmagan (yoki karta bloklangan)',
        '-31304': 'SMS kod noto\'g\'ri',
        '-31305': 'SMS kod muddati o\'tgan',
        '-31306': 'SMS kodini qayta yuborish uchun kutib turing',

        // To'lov xatolari
        '-31001': 'Summada xatolik',
        '-31003': 'To\'lov amalga oshirilmaydi',
        '-31007': 'Tranzaksiya allaqachon amalga oshirilgan',
        '-31008': 'Kartada mablag\' yetarli emas',
        '-31050': 'Chek topilmadi',
        '-31051': 'Chek holatida xatolik',
        '-31052': 'Operatsiya ruxsat etilmagan',
        '-31060': 'Chek allaqachon to\'langan',
        '-31099': 'Chek bekor qilingan',
    };
    return errors[String(code)] || null;
}

// ============= CARD METHODS =============

/**
 * Karta tokenini yaratish
 * 
 * Rasmiy API: cards.create
 * Parametrlar: { card: { number, expire }, save: boolean }
 * Javob: { card: { number, expire, token, recurrent, verify } }
 * 
 * @param {string} cardNumber - Karta raqami (16 raqam)
 * @param {string} expire - Amal qilish muddati (MMYY formatda, masalan: "0399")
 * @returns {Promise<{token: string, card: object}>}
 */
async function createCardToken(cardNumber, expire) {
    const result = await _callPayme('cards.create', {
        card: {
            number: cardNumber,
            expire,
        },
        save: true,
    });

    return {
        token: result.card.token,
        card: {
            number: result.card.number, // Maskirovka qilingan (860006******6311)
            expire: result.card.expire,
            type: result.card.type,      // Karta turi (humo, uzcard)
            recurrent: result.card.recurrent,
            verify: result.card.verify,  // false — hali tasdiqlanmagan
        },
    };
}

/**
 * SMS tasdiqlash kodini so'rash
 * 
 * Rasmiy API: cards.get_verify_code
 * Parametrlar: { token }
 * Javob: { sent, phone, wait }
 * 
 * @param {string} token - Karta tokeni
 * @returns {Promise<{sent: boolean, phone: string, wait: number}>}
 */
async function getVerifyCode(token) {
    const result = await _callPayme('cards.get_verify_code', {
        token,
    });

    return {
        sent: result.sent,
        phone: result.phone, // Maskirovka qilingan telefon raqami
        wait: result.wait,   // SMS qayta yuborish uchun kutish vaqti (soniya)
    };
}

/**
 * Kartani SMS kod bilan tasdiqlash
 * 
 * Rasmiy API: cards.verify
 * Parametrlar: { token, code }
 * Javob: { card: { number, expire, token, recurrent, verify } }
 * 
 * @param {string} token - Karta tokeni
 * @param {string} code - SMS kod (6 raqam)
 * @returns {Promise<{verified: boolean, card: object}>}
 */
async function verifyCard(token, code) {
    const result = await _callPayme('cards.verify', {
        token,
        code,
    });

    return {
        verified: result.card.verify,
        card: {
            number: result.card.number,
            expire: result.card.expire,
            token: result.card.token,
            recurrent: result.card.recurrent,
            type: result.card.type,
        },
    };
}

/**
 * Karta tokenini tekshirish
 * 
 * Rasmiy API: cards.check
 * Parametrlar: { token }
 * 
 * @param {string} token - Karta tokeni
 * @returns {Promise<{verified: boolean, card: object}>}
 */
async function checkCard(token) {
    const result = await _callPayme('cards.check', {
        token,
    });

    return {
        verified: result.card.verify,
        card: {
            number: result.card.number,
            expire: result.card.expire,
            type: result.card.type,
            recurrent: result.card.recurrent,
        },
    };
}

/**
 * Karta tokenini o'chirish
 * 
 * Rasmiy API: cards.remove
 * Parametrlar: { token }
 * 
 * @param {string} token - Karta tokeni
 * @returns {Promise<{success: boolean}>}
 */
async function removeCard(token) {
    const result = await _callPayme('cards.remove', {
        token,
    });

    return {
        success: result.success,
    };
}

// ============= RECEIPT METHODS =============

/**
 * Chek (receipt) yaratish
 * 
 * Rasmiy API: receipts.create
 * Parametrlar: { amount, account: { order_id }, description }
 * Javob: { receipt: { _id, state, ... } }
 * 
 * MUHIM: Summa tiyinda ko'rsatiladi (1 so'm = 100 tiyin)
 * 
 * @param {number} amount - Summa (tiyinda, masalan: 4900000 = 49000 so'm)
 * @param {string} orderId - Buyurtma ID (Subscription _id)
 * @returns {Promise<{receiptId: string, state: number}>}
 */
async function createReceipt(amount, orderId) {
    const result = await _callPayme('receipts.create', {
        amount,
        account: {
            order_id: orderId,
        },
        description: 'Qadamcha obuna to\'lovi',
    });

    // Rasmiy javob formati: result.receipt._id
    return {
        receiptId: result.receipt._id,
        state: result.receipt.state, // 0 = yaratilgan
    };
}

/**
 * Chekni to'lash (karta tokeni bilan)
 * 
 * Rasmiy API: receipts.pay
 * Parametrlar: { id, token, payer: { phone } }
 * Javob: { receipt: { _id, state, ... } }
 * 
 * @param {string} receiptId - Chek ID
 * @param {string} token - Tasdiqlangan karta tokeni
 * @param {object} payer - To'lovchi ma'lumotlari (ixtiyoriy)
 * @returns {Promise<{receiptId: string, state: number}>}
 */
async function payReceipt(receiptId, token, payer = {}) {
    const params = {
        id: receiptId,
        token,
    };

    // Rasmiy docs bo'yicha payer ma'lumotlari
    if (payer.phone || payer.email || payer.name) {
        params.payer = {};
        if (payer.phone) params.payer.phone = payer.phone;
        if (payer.email) params.payer.email = payer.email;
        if (payer.name) params.payer.name = payer.name;
    }

    const result = await _callPayme('receipts.pay', params);

    // Rasmiy javob formati: result.receipt._id
    return {
        receiptId: result.receipt._id,
        state: result.receipt.state, // 4 = to'langan
    };
}

/**
 * Chekni bekor qilish
 * 
 * Rasmiy API: receipts.cancel
 * Parametrlar: { id }
 * Javob: { receipt: { _id, state, ... } }
 * 
 * @param {string} receiptId - Chek ID
 * @returns {Promise<{receiptId: string, state: number}>}
 */
async function cancelReceipt(receiptId) {
    const result = await _callPayme('receipts.cancel', {
        id: receiptId,
    });

    return {
        receiptId: result.receipt._id,
        state: result.receipt.state, // 50 = bekor qilingan
    };
}

/**
 * Chek holatini tekshirish
 * 
 * Rasmiy API: receipts.check
 * Parametrlar: { id }
 * Javob: { receipt: { _id, state, ... } }
 * 
 * @param {string} receiptId - Chek ID
 * @returns {Promise<{receiptId: string, state: number}>}
 */
async function checkReceipt(receiptId) {
    const result = await _callPayme('receipts.check', {
        id: receiptId,
    });

    return {
        receiptId: result.receipt._id,
        state: result.receipt.state,
    };
}

module.exports = {
    createCardToken,
    getVerifyCode,
    verifyCard,
    checkCard,
    removeCard,
    createReceipt,
    payReceipt,
    cancelReceipt,
    checkReceipt,
};
