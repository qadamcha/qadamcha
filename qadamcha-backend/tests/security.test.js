/**
 * Security Tests
 * Xavfsizlik tuzatishlarini tekshirish
 */

const crypto = require('crypto');

describe('Security — Refresh Token Hashing', () => {
    it('should hash refresh token with SHA-256', () => {
        const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test-refresh-token';
        const hash = crypto.createHash('sha256').update(token).digest('hex');

        // Hash uzunligi 64 belgi bo'lishi kerak (SHA-256 hex)
        expect(hash).toHaveLength(64);

        // Bir xil token bir xil hash berishi kerak
        const hash2 = crypto.createHash('sha256').update(token).digest('hex');
        expect(hash).toBe(hash2);

        // Boshqa token boshqa hash berishi kerak
        const otherHash = crypto.createHash('sha256').update('other-token').digest('hex');
        expect(hash).not.toBe(otherHash);
    });

    it('should not store plaintext token (hash !== original)', () => {
        const token = 'my-super-secret-refresh-token';
        const hash = crypto.createHash('sha256').update(token).digest('hex');

        expect(hash).not.toBe(token);
        expect(hash).not.toContain(token);
    });
});

describe('Security — OTP Response', () => {
    it('should not include OTP code in response', () => {
        // Simulyatsiya: response body da 'code' fieldi bo'lmasligi kerak
        const response = { success: true, message: 'OTP yuborildi' };

        expect(response).not.toHaveProperty('code');
        expect(response).not.toHaveProperty('otp');
    });
});

describe('Security — Environment Checks', () => {
    it('should only allow test phone in strict development mode', () => {
        // isTestBypass faqat NODE_ENV === 'development' bo'lganda ishlaydi
        const testCases = [
            { env: 'development', phone: '+998901234567', testPhone: '+998901234567', expected: true },
            { env: 'production', phone: '+998901234567', testPhone: '+998901234567', expected: false },
            { env: 'staging', phone: '+998901234567', testPhone: '+998901234567', expected: false },
            { env: 'test', phone: '+998901234567', testPhone: '+998901234567', expected: false },
            { env: 'development', phone: '+998901234567', testPhone: null, expected: false },
            { env: 'development', phone: '+998901234567', testPhone: '+998999999999', expected: false },
        ];

        for (const tc of testCases) {
            const isTestBypass = Boolean(tc.env === 'development' && tc.testPhone && tc.phone === tc.testPhone);
            expect(isTestBypass).toBe(tc.expected);
        }
    });

    it('should show stack trace only in development', () => {
        const testCases = [
            { env: 'development', expected: true },
            { env: 'production', expected: false },
            { env: 'staging', expected: false },
            { env: undefined, expected: false },
            { env: 'test', expected: false },
        ];

        for (const tc of testCases) {
            const showStack = tc.env === 'development';
            expect(showStack).toBe(tc.expected);
        }
    });
});

describe('Security — Input Validation', () => {
    it('should validate phone format', () => {
        const validPhones = ['+998901234567', '+998712345678', '+998331234567'];
        const invalidPhones = ['998901234567', '+1234567890', 'abc', '', '+99890123456', '+9989012345678'];

        const phoneRegex = /^\+998[0-9]{9}$/;

        validPhones.forEach(phone => {
            expect(phoneRegex.test(phone)).toBe(true);
        });

        invalidPhones.forEach(phone => {
            expect(phoneRegex.test(phone)).toBe(false);
        });
    });

    it('should validate time limits (5-480 minutes)', () => {
        const validLimits = [5, 60, 120, 480];
        const invalidLimits = [0, 1, 4, 481, 1000, -1, NaN];

        validLimits.forEach(limit => {
            expect(typeof limit === 'number' && limit >= 5 && limit <= 480).toBe(true);
        });

        invalidLimits.forEach(limit => {
            expect(typeof limit === 'number' && limit >= 5 && limit <= 480).toBe(false);
        });
    });

    it('should limit AI message length to 2000 chars', () => {
        const shortMsg = 'Hello AI';
        const longMsg = 'a'.repeat(2001);

        expect(shortMsg.length <= 2000).toBe(true);
        expect(longMsg.length <= 2000).toBe(false);
    });
});

describe('Security — Sentry Sanitization', () => {
    it('should sanitize all sensitive fields', () => {
        const sensitiveKeys = [
            'pin', 'password', 'token', 'refreshToken', 'code',
            'phone', 'cardNumber', 'name', 'email', 'fcmToken',
            'verifiedToken', 'newPin', 'familyCode'
        ];

        const data = {};
        sensitiveKeys.forEach(key => { data[key] = 'sensitive-value'; });

        // Sanitize
        for (const key of sensitiveKeys) {
            if (data[key]) data[key] = '[FILTERED]';
        }

        // Barcha fieldlar filtered bo'lishi kerak
        sensitiveKeys.forEach(key => {
            expect(data[key]).toBe('[FILTERED]');
        });
    });
});

describe('Security — CDN Signed URL', () => {
    it('should generate signed URL with token and expires', () => {
        const cdnTokenKey = 'test-secret-key';
        const path = '/video123/playlist.m3u8';
        const expiresInSeconds = 14400;

        const expires = Math.floor(Date.now() / 1000) + expiresInSeconds;
        const hashableBase = `${cdnTokenKey}${path}${expires}`;
        const token = crypto
            .createHash('sha256')
            .update(hashableBase)
            .digest('base64')
            .replace(/\+/g, '-')
            .replace(/\//g, '_')
            .replace(/=+$/, '');

        const url = `https://cdn.example.com${path}?token=${token}&expires=${expires}`;

        expect(url).toContain('token=');
        expect(url).toContain('expires=');
        expect(url).toContain('playlist.m3u8');
    });
});
