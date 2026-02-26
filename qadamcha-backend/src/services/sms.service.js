const crypto = require('crypto');
const fetch = require('node-fetch');
const FormData = require('form-data');
const config = require('../config/env');
const { logger } = require('../config/logger');
const { REDIS_KEYS } = require('../config/constants');

class SmsService {
    constructor() {
        this.baseUrl = config.ESKIZ_BASE_URL;
        this.tokenKey = REDIS_KEYS.ESKIZ_TOKEN;
        this.redis = null;
    }

    // Telefon raqamni maskirovka qilish (+998*****1234)
    _maskPhone(phone) {
        if (!phone || phone.length < 6) return '***';
        return phone.slice(0, 4) + '*'.repeat(phone.length - 8) + phone.slice(-4);
    }

    // Redis ni sozlash (app.js dan chaqiriladi)
    setRedis(redis) {
        this.redis = redis;
    }

    // Yangi token olish (Eskiz login)
    async _fetchNewToken() {
        const formData = new FormData();
        formData.append('email', config.ESKIZ_EMAIL);
        formData.append('password', config.ESKIZ_PASSWORD);

        const response = await fetch(`${this.baseUrl}/auth/login`, {
            method: 'POST',
            body: formData
        });

        const data = await response.json();

        if (data.data?.token) {
            logger.info('🔑 Eskiz: Yangi token olindi');
            // 29 kun cache (token 30 kun amal qiladi)
            if (this.redis) {
                await this.redis.setex(this.tokenKey, 29 * 24 * 60 * 60, data.data.token);
            }
            return data.data.token;
        }

        throw new Error('Eskiz token olishda xato: ' + JSON.stringify(data));
    }

    // Token olish (cache yoki yangi)
    async getToken() {
        if (!this.redis) {
            throw new Error('Redis not configured for SMS service');
        }

        // Cache dan olish
        const cached = await this.redis.get(this.tokenKey);
        if (cached) return cached;

        // Yangi token olish
        return this._fetchNewToken();
    }

    // Eski tokenni o'chirib yangi olish
    async _refreshToken() {
        if (this.redis) {
            await this.redis.del(this.tokenKey);
        }
        return this._fetchNewToken();
    }

    // 6 xonali kriptografik xavfsiz kod
    generateOtp() {
        return crypto.randomInt(100000, 999999).toString();
    }

    // SMS yuborish (ichki funksiya)
    async _sendSms(phone, message, token) {
        const formData = new FormData();
        formData.append('mobile_phone', this.formatPhone(phone));
        formData.append('message', message);
        formData.append('from', '4546');

        const response = await fetch(`${this.baseUrl}/message/sms/send`, {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${token}` },
            body: formData
        });

        return response.json();
    }

    // OTP yuborish
    async sendOtp(phone, code, purpose = 'register') {
        // Eskiz credentials tekshirish
        const eskizConfigured = config.ESKIZ_EMAIL && config.ESKIZ_PASSWORD
            && config.ESKIZ_EMAIL !== 'your_email@gmail.com'
            && config.ESKIZ_PASSWORD !== 'your_eskiz_api_password';

        // [FIX SEC-3] OTP kodni HECH QACHON logga yozmaslik
        // [FIX SEC-10] Telefon raqam faqat maskirovka qilingan holda loglanadi
        if (config.NODE_ENV === 'development') {
            logger.info(`📱 OTP sent to ${this._maskPhone(phone)} | purpose: ${purpose}`);
        } else {
            // Production: faqat maskirovka qilingan telefon raqam
            logger.info(`📱 OTP sent to ${this._maskPhone(phone)} | purpose: ${purpose}`);
        }

        // Eskiz sozlanmagan bo'lsa — faqat logga chiqarish
        if (!eskizConfigured) {
            logger.warn('⚠️ Eskiz sozlanmagan — OTP faqat logda');
            return { success: true, messageId: 'no-eskiz' };
        }

        // SMS matni (moderatsiyadan o'tgan shablonlar)
        const smsMessages = {
            'register': `Kodni hech kimga bermang! QADAMCHA ilovasiga ro'yxatdan o'tish uchun tasdiqlash kodi: ${code}`,
            'reset-pin': `Kodni hech kimga bermang! QADAMCHA ilovasida parolni qayta tiklash uchun tasdiqlash kodi: ${code}`,
        };
        const message = smsMessages[purpose] || smsMessages['register'];

        // 1. Token olish
        let token;
        try {
            token = await this.getToken();
        } catch (err) {
            logger.error({ err }, '❌ Token olishda xato');
            return { success: false, error: 'SMS xizmati vaqtincha ishlamayapti' };
        }

        // 2. SMS yuborish
        try {
            logger.info(`📤 SMS yuborish: ${this._maskPhone(phone)}`);

            let data = await this._sendSms(phone, message, token);
            logger.info({ response: data }, '📨 Eskiz javob');

            // ✅ Muvaffaqiyat
            if (data.status === 'waiting') {
                logger.info(`✅ SMS yuborildi! ID: ${data.id}`);
                return { success: true, messageId: data.id };
            }

            // ❌ Xato — token eski bo'lishi mumkin, yangilab qayta urinish
            if (data.status === 'error') {
                logger.info(`⚠️ Xato: ${data.message} — tokenni yangilab qayta urinish...`);

                // Tokenni yangilash
                const newToken = await this._refreshToken();

                // Qayta urinish
                data = await this._sendSms(phone, message, newToken);
                logger.info({ response: data }, '📨 Qayta urinish javob');

                if (data.status === 'waiting') {
                    logger.info(`✅ SMS qayta urinishda yuborildi! ID: ${data.id}`);
                    return { success: true, messageId: data.id };
                }

                logger.error(`❌ SMS yuborilmadi: ${data.message}`);
                return { success: false, error: data.message || 'SMS yuborib bo\'lmadi' };
            }

            // Kutilmagan javob
            logger.error({ response: data }, '❌ Kutilmagan javob');
            return { success: false, error: 'SMS kutilmagan javob' };
        } catch (error) {
            logger.error({ err: error }, '❌ SMS xatosi');
            return { success: false, error: 'SMS xizmati vaqtincha ishlamayapti' };
        }
    }

    // Telefon raqamni formatlash: +998901234567 -> 998901234567
    formatPhone(phone) {
        return phone.replace(/\D/g, '');
    }

    // SMS balansni tekshirish
    async checkBalance() {
        const token = await this.getToken();
        const response = await fetch(`${this.baseUrl}/user/get-limit`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        return response.json();
    }
}

// Singleton instance
module.exports = new SmsService();
