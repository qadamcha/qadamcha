const { Type } = require('@sinclair/typebox');
const aiController = require('../controllers/ai.controller');

const ChatSchema = Type.Object({
    message: Type.String({ minLength: 3, maxLength: 500 }),
    childId: Type.Optional(Type.String())
});

module.exports = async function (fastify) {

    // Barcha AI routelar autentifikatsiya talab qiladi
    fastify.addHook('preHandler', fastify.authenticate);

    // POST /ai/chat
    fastify.post('/chat', {
        schema: { body: ChatSchema }
    }, aiController.chat);

    // GET /ai/tips
    fastify.get('/tips', aiController.getTips);

    // GET /ai/status
    fastify.get('/status', aiController.getStatus);
};
