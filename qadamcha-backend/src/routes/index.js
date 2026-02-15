module.exports = async function (fastify) {
    // Auth Routes
    fastify.register(require('./auth.routes'), { prefix: '/auth' });

    // User Routes
    fastify.register(require('./user.routes'), { prefix: '/user' });

    // Children Routes
    fastify.register(require('./children.routes'), { prefix: '/children' });

    // Devices Routes
    fastify.register(require('./devices.routes'), { prefix: '/devices' });

    // Content Routes
    fastify.register(require('./content.routes'), { prefix: '/content' });

    // Subscription Routes
    fastify.register(require('./subscription.routes'), { prefix: '/subscription' });

    // AI Routes
    fastify.register(require('./ai.routes'), { prefix: '/ai' });

    // Payme Subscribe API (karta + to'lov endpointlar)
    fastify.register(require('./payme.routes'), { prefix: '/payme' });

    // Story Routes
    fastify.register(require('./story.routes'), { prefix: '/stories' });
};

