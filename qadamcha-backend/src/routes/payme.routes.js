const paymeController = require('../controllers/payme.controller');

module.exports = async function (fastify) {
    // Payme Merchant API webhook
    // Payme o'zi Basic Auth yuboradi — auth middleware kerak emas
    fastify.post('/', {
        config: {
            rateLimit: {
                max: 50,
                timeWindow: '1 minute'
            }
        }
    }, paymeController.handle);
};
