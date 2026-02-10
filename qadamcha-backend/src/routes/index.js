module.exports = async function (fastify) {
    // Auth Routes
    fastify.register(require('./auth.routes'), { prefix: '/auth' });

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
};
