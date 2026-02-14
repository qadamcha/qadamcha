const crypto = require('crypto');
const fetch = require('node-fetch');
const FormData = require('form-data');
const config = require('../config/env');
const { REDIS_KEYS } = require('../config/constants');

class SmsService {
    constructor() {
        this.baseUrl = config.ESKIZ_BASE_URL;
        this.tokenKey = REDIS_KEYS.ESKIZ_TOKEN;
        this.redis = null;

        // Environment mode
        this.isProduction = config.NODE_ENV === 'production';
    }

    // Redis ni sozlash (app.js dan chaqiriladi)
    setRedis(redis) {
        this.redis = redis;
    }

    // Token olish / yangilash
    async getToken() {
        if (!this.redis) {
            throw new Error('Redis not configured for SMS service');
        }

        // Cache dan olish
        const cached = await this.redis.get(this.tokenKey);
        if (cached) return cached;

        // Yangi token olish
        const formData = new FormData();
        formData.append('email', config.ESKIZ_EMAIL);
        formData.append('password', config.ESKIZ_PASSWORD);

        const response = await fetch(`${this.baseUrl}/auth/login`, {
            method: 'POST',
            body: formData
        });

        const data = await response.json();

        if (data.data?.token) {
            // 29 kun cache (token 30 kun amal qiladi)
            await this.redis.setex(this.tokenKey, 29 * 24 * 60 * 60, data.data.token);
            return data.data.token;
        }

        throw new Error('Eskiz token olishda xato: ' + JSON.stringify(data));
    }

    // 6 xonali kriptografik xavfsiz kod
    generateOtp() {
        return crypto.randomInt(100000, 999999).toString();
    }

    // OTP yuborish
    async sendOtp(phone, code) {
        // Terminalda kodni ko'rsatish (development yoki Eskiz sozlanmagan bo'lsa)
        const eskizConfigured = config.ESKIZ_EMAIL && config.ESKIZ_PASSWORD
            && config.ESKIZ_EMAIL !== 'your_email@gmail.com'
            && config.ESKIZ_PASSWORD !== 'your_eskiz_api_password';

        // OTP kodni har doim logga chiqarish (test va debug uchun)
        console.log('\n' + '='.repeat(50));
        console.log('📱 OTP CODE FOR', phone);
        console.log('🔐 CODE:', code);
        console.log('='.repeat(50) + '\n');

        // Eskiz sozlanmagan bo'lsa — faqat logga chiqarib qaytarish
        if (!eskizConfigured) {
            console.warn('⚠️ Eskiz sozlanmagan — OTP faqat logda ko\'rinadi');
            return { success: true, messageId: 'no-eskiz', note: 'Eskiz sozlanmagan — logda OTP ni ko\'ring' };
        }

        let token;
        try {
            token = await this.getToken();
        } catch (err) {
            console.error('❌ Eskiz token olishda xato:', err.message);
            if (!this.isProduction) {
                return { success: true, messageId: 'dev-mode-no-token', note: 'Token olinmadi — terminalda OTP ni ko\'ring' };
            }
            return { success: false, error: 'SMS xizmati vaqtincha ishlamayapti' };
        }

        const message = this.isProduction
            ? `Qadamcha: Tasdiqlash kodingiz: ${code}. 5 daqiqa amal qiladi.`
            : 'Bu Eskiz dan test';

        const formData = new FormData();
        formData.append('mobile_phone', this.formatPhone(phone));
        formData.append('message', message);

        if (this.isProduction) {
            formData.append('from', '4546');
        }

        try {
            const response = await fetch(`${this.baseUrl}/message/sms/send`, {
                method: 'POST',
                headers: { 'Authorization': `Bearer ${token}` },
                body: formData
            });

            const data = await response.json();

            if (data.status === 'waiting' || data.id) {
                console.log('✅ SMS yuborildi:', data.id);
                return { success: true, messageId: data.id };
            }

            if (!this.isProduction) {
                console.warn('⚠️ SMS (dev mode):', data.message || 'Test message sent');
                return { success: true, messageId: 'dev-mode', note: 'Development mode - terminalda OTP ni ko\'ring' };
            }

            console.error('❌ SMS yuborilmadi:', data.message);
            return { success: false, error: 'SMS yuborib bo\'lmadi. Keyinroq urinib ko\'ring.' };
        } catch (error) {
            console.error('❌ SMS xatosi:', error.message);
            if (!this.isProduction) {
                return { success: true, messageId: 'dev-mode-error', note: 'Development mode - terminalda OTP ni ko\'ring' };
            }
            return { success: false, error: 'SMS xizmati vaqtincha ishlamayapti' };
        }
    }

    // Telefon raqamni formatlash
    formatPhone(phone) {
        // +998901234567 -> 998901234567
        return phone.replace(/\D/g, '');
    }

    // SMS balansni tekshirish
    async checkBalance() {
        const token = await this.getToken();

        const response = await fetch(`${this.baseUrl}/user/get-limit`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        return response.json();
    }
}

// Singleton instance
module.exports = new SmsService();
