/**
 * Plugins Index
 * Barcha pluginlarni export qilish
 */

const { registerSwagger } = require('./swagger.plugin');
const { initSentry, captureException, sentryErrorHandler } = require('./sentry.plugin');

module.exports = {
    registerSwagger,
    initSentry,
    captureException,
    sentryErrorHandler,
};
