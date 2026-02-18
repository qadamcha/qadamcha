const { Type } = require('@sinclair/typebox');
const aiController = require('../controllers/ai.controller');

const HistoryItemSchema = Type.Object({
    role: Type.Union([Type.Literal('user'), Type.Literal('model')]),
    text: Type.String({ minLength: 1 })
});

const ChatSchema = Type.Object({
    message: Type.String({ minLength: 3, maxLength: 2000 }),
    childId: Type.Optional(Type.String()),
    history: Type.Optional(Type.Array(HistoryItemSchema, { maxItems: 100 }))
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
