/**
 * Validator Middleware
 * Markazlashtirilgan validatsiya middleware
 */

const { ERRORS } = require('../config/constants');

/**
 * Telefon raqamni tekshirish
 * Format: +998XXXXXXXXX
 */
function validatePhone(phone) {
    if (!phone) {
        return { valid: false, message: ERRORS.PHONE_REQUIRED };
    }

    const phoneRegex = /^\+998[0-9]{9}$/;
    if (!phoneRegex.test(phone)) {
        return { valid: false, message: ERRORS.PHONE_INVALID };
    }

    return { valid: true };
}

/**
 * PIN kod tekshirish
 * 4-6 raqam
 */
function validatePin(pin) {
    if (!pin) {
        return { valid: false, message: 'PIN kiritilmagan' };
    }

    if (!/^[0-9]{4,6}$/.test(pin)) {
        return { valid: false, message: 'PIN 4-6 raqam bo\'lishi kerak' };
    }

    return { valid: true };
}

/**
 * MongoDB ObjectId tekshirish
 */
function validateObjectId(id) {
    if (!id) {
        return { valid: false, message: 'ID kiritilmagan' };
    }

    const objectIdRegex = /^[0-9a-fA-F]{24}$/;
    if (!objectIdRegex.test(id)) {
        return { valid: false, message: 'Noto\'g\'ri ID formati' };
    }

    return { valid: true };
}

/**
 * Pagination parametrlarini tekshirish
 */
function validatePagination(page, limit) {
    const pageNum = parseInt(page) || 1;
    const limitNum = parseInt(limit) || 20;

    return {
        page: Math.max(1, pageNum),
        limit: Math.min(100, Math.max(1, limitNum)) // Max 100
    };
}

/**
 * Validation error response helper
 */
function sendValidationError(reply, message) {
    return reply.status(400).send({
        success: false,
        message,
        code: 'VALIDATION_ERROR'
    });
}

/**
 * Request body validator factory
 * TypeBox schema asosida custom validator yaratish
 */
function createValidator(schema) {
    return async (request, reply) => {
        const errors = [];

        for (const [key, rules] of Object.entries(schema)) {
            const value = request.body[key];

            if (rules.required && (value === undefined || value === null || value === '')) {
                errors.push(`${key} majburiy`);
                continue;
            }

            if (value !== undefined && rules.type === 'phone') {
                const result = validatePhone(value);
                if (!result.valid) errors.push(result.message);
            }

            if (value !== undefined && rules.type === 'pin') {
                const result = validatePin(value);
                if (!result.valid) errors.push(result.message);
            }

            if (value !== undefined && rules.type === 'objectId') {
                const result = validateObjectId(value);
                if (!result.valid) errors.push(result.message);
            }

            if (value !== undefined && rules.minLength && value.length < rules.minLength) {
                errors.push(`${key} kamida ${rules.minLength} belgi bo'lishi kerak`);
            }

            if (value !== undefined && rules.maxLength && value.length > rules.maxLength) {
                errors.push(`${key} ${rules.maxLength} belgidan oshmasligi kerak`);
            }
        }

        if (errors.length > 0) {
            return sendValidationError(reply, errors.join('; '));
        }
    };
}

/**
 * Sanitize string (XSS prevention)
 */
function sanitizeString(str) {
    if (typeof str !== 'string') return str;
    return str
        .replace(/[<>]/g, '') // Remove < and >
        .trim();
}

/**
 * Sanitize request body
 */
function sanitizeBody(request, reply, done) {
    if (request.body && typeof request.body === 'object') {
        for (const [key, value] of Object.entries(request.body)) {
            if (typeof value === 'string') {
                request.body[key] = sanitizeString(value);
            }
        }
    }
    done();
}

module.exports = {
    validatePhone,
    validatePin,
    validateObjectId,
    validatePagination,
    sendValidationError,
    createValidator,
    sanitizeString,
    sanitizeBody
};
