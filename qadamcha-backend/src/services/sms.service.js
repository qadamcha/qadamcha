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

    // 6 xonali tasodifiy kod
    generateOtp() {
        return Math.floor(100000 + Math.random() * 900000).toString();
    }

    // OTP yuborish
    async sendOtp(phone, code) {
        const token = await this.getToken();

        // Terminalda kodni ko'rsatish (development uchun)
        console.log('\n' + '='.repeat(50));
        console.log('📱 OTP CODE FOR', phone);
        console.log('🔐 CODE:', code);
        console.log('📋 MODE:', this.isProduction ? 'PRODUCTION' : 'DEVELOPMENT');
        console.log('='.repeat(50) + '\n');

        // Xabar tanlash
        let message;
        if (this.isProduction) {
            // Production: haqiqiy OTP xabari
            message = `Qadamcha: Tasdiqlash kodingiz: ${code}. 5 daqiqa amal qiladi.`;
        } else {
            // Development: test xabari (Eskiz test mode uchun)
            message = 'Bu Eskiz dan test';
        }

        const formData = new FormData();
        formData.append('mobile_phone', this.formatPhone(phone));
        formData.append('message', message);

        // Production da sender nickname qo'shish
        if (this.isProduction) {
            formData.append('from', '4546'); // Yoki ro'yxatdan o'tgan nickname
        }

        try {
            const response = await fetch(`${this.baseUrl}/message/sms/send`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`
                },
                body: formData
            });

            const data = await response.json();

            if (data.status === 'waiting' || data.id) {
                console.log('✅ SMS yuborildi:', data.id);
                return {
                    success: true,
                    messageId: data.id
                };
            }

            // Dev mode da xato bo'lsa ham davom etamiz
            if (!this.isProduction) {
                console.warn('⚠️ SMS (dev mode):', data.message || 'Test message sent');
                return {
                    success: true,
                    messageId: 'dev-mode',
                    note: 'Development mode - check terminal for OTP'
                };
            }

            throw new Error(data.message || 'SMS yuborishda xato');
        } catch (error) {
            if (!this.isProduction) {
                console.warn('⚠️ SMS xatosi (dev mode davom etadi):', error.message);
                return {
                    success: true,
                    messageId: 'dev-mode-error',
                    note: 'Development mode - check terminal for OTP'
                };
            }
            throw error;
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
