/**
 * Middlewares Index
 * Barcha middlewarelarni export qilish
 */

const { registerLogger } = require('./logger.middleware');
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

    // Validators
    validatePhone,
    validatePin,
    validateObjectId,
    validatePagination,
    sendValidationError,
    createValidator,
    sanitizeBody
};
