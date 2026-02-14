/**
 * Middlewares Index
 * Barcha middlewarelarni export qilish
 */

const { registerLogger } = require('./logger.middleware');
const { registerAuth } = require('./auth.middleware');
const {
    validatePhone,
    validatePin,
    validateObjectId,
    validatePagination,
    sendValidationError,
    createValidator,
    sanitizeBody
} = require('./validator.middleware');

module.exports = {
    // Logger
    registerLogger,

    // Auth
    registerAuth,

    // Validators
    validatePhone,
    validatePin,
    validateObjectId,
    validatePagination,
    sendValidationError,
    createValidator,
    sanitizeBody
};
