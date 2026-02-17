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
    async sendOtp(phone, code, purpose = 'register') {
        // Eskiz credentials tekshirish
        const eskizConfigured = config.ESKIZ_EMAIL && config.ESKIZ_PASSWORD
            && config.ESKIZ_EMAIL !== 'your_email@gmail.com'
            && config.ESKIZ_PASSWORD !== 'your_eskiz_api_password';

        // OTP kodni har doim logga chiqarish (debug uchun)
        console.log('\n' + '='.repeat(50));
        console.log('📱 OTP CODE FOR', phone);
        console.log('🔐 CODE:', code);
        console.log('📋 PURPOSE:', purpose);
        console.log('🌍 ENV:', config.NODE_ENV);
        console.log('🔧 ESKIZ CONFIGURED:', eskizConfigured);
        console.log('='.repeat(50) + '\n');

        // Eskiz sozlanmagan bo'lsa — faqat logga chiqarib qaytarish
        if (!eskizConfigured) {
            console.warn('⚠️ Eskiz sozlanmagan — OTP faqat logda ko\'rinadi');
            return { success: true, messageId: 'no-eskiz', note: 'Eskiz sozlanmagan — logda OTP ni ko\'ring' };
        }

        // 1. Token olish
        let token;
        try {
            token = await this.getToken();
            console.log('🔑 Eskiz token olindi ✓');
        } catch (err) {
            console.error('❌ Eskiz token olishda xato:', err.message);
            return { success: false, error: 'SMS xizmati vaqtincha ishlamayapti' };
        }

        // 2. SMS matnini tayyorlash
        const smsMessages = {
            'register': `Kodni hech kimga bermang! QADAMCHA ilovasiga ro'yxatdan o'tish uchun tasdiqlash kodi: ${code}`,
            'reset-pin': `Kodni hech kimga bermang! QADAMCHA ilovasida parolni qayta tiklash uchun tasdiqlash kodi: ${code}`,
        };

        const realMessage = smsMessages[purpose] || smsMessages['register'];

        // 3. SMS yuborish funksiyasi
        const doSend = async (msg, authToken) => {
            const fd = new FormData();
            fd.append('mobile_phone', this.formatPhone(phone));
            fd.append('message', msg);
            fd.append('from', '4546');

            const resp = await fetch(`${this.baseUrl}/message/sms/send`, {
                method: 'POST',
                headers: { 'Authorization': `Bearer ${authToken}` },
                body: fd
            });
            return resp.json();
        };

        console.log('📤 SMS yuborish:', {
            to: this.formatPhone(phone),
            message: realMessage,
            from: '4546',
        });

        // 4. Eskiz API ga yuborish
        try {
            let data = await doSend(realMessage, token);
            console.log('📨 Eskiz javob:', JSON.stringify(data, null, 2));

            // ✅ Muvaffaqiyat
            if (data.status === 'waiting') {
                console.log('✅ SMS muvaffaqiyatli yuborildi! ID:', data.id);
                return { success: true, messageId: data.id };
            }

            // ❌ Error tekshirish
            if (data.status === 'error') {
                // Eskiz hali test rejimda — test matni bilan qayta urinish
                if (data.message && data.message.includes('тест')) {
                    console.log('⚠️ Eskiz hali TEST rejimda — test matni bilan qayta yuborish...');
                    console.log('📌 OTP kod faqat TERMINALDA ko\'rinadi: ' + code);

                    const testData = await doSend('Bu Eskiz dan test', token);
                    console.log('📨 Test SMS javob:', JSON.stringify(testData, null, 2));

                    if (testData.status === 'waiting') {
                        console.log('✅ Test SMS yuborildi (OTP kodi SMS da emas, terminalda!)');
                        return { success: true, messageId: testData.id, note: 'Eskiz test rejim — OTP faqat terminalda' };
                    }
                }

                // Token yaroqsiz
                if (data.message && (data.message.includes('token') || data.message.includes('auth'))) {
                    console.log('🔄 Token yaroqsiz — yangilab qayta yuborish...');
                    if (this.redis) await this.redis.del(this.tokenKey);
                    const newToken = await this.getToken();
                    data = await doSend(realMessage, newToken);
                    console.log('📨 Qayta urinish javob:', JSON.stringify(data, null, 2));

                    if (data.status === 'waiting') {
                        console.log('✅ SMS qayta urinishda yuborildi! ID:', data.id);
                        return { success: true, messageId: data.id };
                    }
                }

                console.error('❌ SMS yuborilmadi:', data.message);
                return { success: false, error: data.message || 'SMS yuborib bo\'lmadi' };
            }

            // Kutilmagan javob
            console.error('❌ Kutilmagan Eskiz javob:', JSON.stringify(data));
            return { success: false, error: 'SMS xizmati kutilmagan javob qaytardi' };
        } catch (error) {
            console.error('❌ SMS xatosi:', error.message);
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
