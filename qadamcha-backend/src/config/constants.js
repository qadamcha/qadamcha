// API Versioning
const API_VERSION = 'v1';
const API_PREFIX = `/api/${API_VERSION}`;

// OTP Constants
const OTP_LENGTH = 6;
const OTP_EXPIRES_MINUTES = 5;
const MAX_OTP_ATTEMPTS = 3;
const OTP_BLOCK_MINUTES = 10;

// Token Prefixes (for Redis keys)
const REDIS_KEYS = {
    OTP: 'otp:',
    OTP_ATTEMPTS: 'otp_attempts:',
    VERIFIED: 'verified:',
    SESSION: 'session:',
    ESKIZ_TOKEN: 'eskiz:token',
    CACHE: 'cache:',
    BLACKLIST: 'blacklist:',
};

// User Roles
const ROLES = {
    PARENT: 'parent',
    CHILD: 'child',
};

// Device Types
const DEVICE_TYPES = {
    ANDROID: 'android',
    IOS: 'ios',
};

// Device Modes
const DEVICE_MODES = {
    PARENT: 'parent',
    CHILD: 'child',
};

// Content Types
const CONTENT_TYPES = {
    CARTOON: 'cartoon',
    GAME: 'game',
    STORY: 'story',
    QUEST: 'quest',
};

// Subscription Status
const SUBSCRIPTION_STATUS = {
    ACTIVE: 'active',
    EXPIRED: 'expired',
    CANCELLED: 'cancelled',
};

// Payment Providers
const PAYMENT_PROVIDERS = {
    PAYME: 'payme',
    CLICK: 'click',
    UZUM: 'uzum',
};

// Error Messages (O'zbek tilida)
const ERRORS = {
    PHONE_REQUIRED: 'Telefon raqam kiritilmagan',
    PHONE_INVALID: 'Telefon raqam noto\'g\'ri formatda',
    OTP_INVALID: 'Tasdiqlash kodi noto\'g\'ri',
    OTP_EXPIRED: 'Tasdiqlash kodi muddati tugagan',
    OTP_TOO_MANY: 'Juda ko\'p urinish. Keyinroq qayta urinib ko\'ring',
    USER_NOT_FOUND: 'Foydalanuvchi topilmadi',
    USER_EXISTS: 'Bu raqam allaqachon ro\'yxatdan o\'tgan',
    PIN_INVALID: 'PIN kod noto\'g\'ri',
    TOKEN_INVALID: 'Token noto\'g\'ri yoki muddati tugagan',
    TOKEN_REQUIRED: 'Autentifikatsiya talab qilinadi',
    DEVICE_LIMIT: 'Maksimal qurilma soniga yetdingiz',
    SUBSCRIPTION_REQUIRED: 'Obuna talab qilinadi',
    SUBSCRIPTION_EXPIRED: 'Obuna muddati tugagan',
    INTERNAL_ERROR: 'Ichki server xatosi',
    NOT_FOUND: 'Topilmadi',
    FORBIDDEN: 'Ruxsat yo\'q',
};

// Success Messages (O'zbek tilida)
const SUCCESS = {
    OTP_SENT: 'Tasdiqlash kodi yuborildi',
    OTP_VERIFIED: 'Telefon tasdiqlandi',
    REGISTERED: 'Ro\'yxatdan o\'tdingiz',
    LOGGED_IN: 'Tizimga kirdingiz',
    LOGGED_OUT: 'Tizimdan chiqdingiz',
    UPDATED: 'Muvaffaqiyatli yangilandi',
    DELETED: 'Muvaffaqiyatli o\'chirildi',
    DEVICE_LINKED: 'Qurilma ulandi',
};

module.exports = {
    API_VERSION,
    API_PREFIX,
    OTP_LENGTH,
    OTP_EXPIRES_MINUTES,
    MAX_OTP_ATTEMPTS,
    OTP_BLOCK_MINUTES,
    REDIS_KEYS,
    ROLES,
    DEVICE_TYPES,
    DEVICE_MODES,
    CONTENT_TYPES,
    SUBSCRIPTION_STATUS,
    PAYMENT_PROVIDERS,
    ERRORS,
    SUCCESS,
};
