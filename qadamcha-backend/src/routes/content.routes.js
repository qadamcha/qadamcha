const { Type } = require('@sinclair/typebox');
const contentController = require('../controllers/content.controller');

const ActivitySchema = Type.Object({
    childId: Type.String({ minLength: 1 }),
    duration: Type.Optional(Type.Integer({ minimum: 0 })),
    action: Type.Union([
        Type.Literal('start'),
        Type.Literal('update'),
        Type.Literal('end')
    ])
});

// Rate limitlar (test uchun o'chirilgan, keyinroq qattiqlashtirish kerak)
const writeRateLimit = {};
const likeRateLimit = {};

module.exports = async function (fastify) {

    // GET /content - Ochiq endpoint (autentifikatsiyasiz)
    fastify.get('/', contentController.getAll);

    // GET /content/featured
    fastify.get('/featured', contentController.getFeatured);

    // GET /content/categories
    fastify.get('/categories', contentController.getCategories);

    // GET /content/:id
    fastify.get('/:id', contentController.getOne);

    // GET /content/:id/stream (autentifikatsiya bilan)
    fastify.get('/:id/stream', {
        preHandler: [fastify.authenticate]
    }, contentController.getStreamUrl);

    // POST /content/:id/activity (autentifikatsiya bilan)
    fastify.post('/:id/activity', {
        preHandler: [fastify.authenticate],
        schema: { body: ActivitySchema },
        ...writeRateLimit
    }, contentController.recordActivity);

    // POST /content/:id/like (autentifikatsiya bilan)
    fastify.post('/:id/like', {
        preHandler: [fastify.authenticate],
        ...likeRateLimit
    }, contentController.like);
};
