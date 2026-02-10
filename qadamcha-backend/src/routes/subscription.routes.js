const { Type } = require('@sinclair/typebox');
const subscriptionController = require('../controllers/subscription.controller');

const CreateSchema = Type.Object({
    plan: Type.Union([
        Type.Literal('monthly'),
        Type.Literal('yearly'),
        Type.Literal('lifetime')
    ])
});

const ActivateSchema = Type.Object({
    orderId: Type.String({ minLength: 1 }),
    transactionId: Type.String({ minLength: 1 }),
    paymentMethod: Type.Union([
        Type.Literal('payme'),
        Type.Literal('click'),
        Type.Literal('uzum')
    ])
});

module.exports = async function (fastify) {

    // GET /subscription/plans - Ochiq endpoint
    fastify.get('/plans', subscriptionController.getPlans);

    // Qolgan barcha routelar autentifikatsiya talab qiladi

    // GET /subscription
    fastify.get('/', {
        preHandler: [fastify.authenticate]
    }, subscriptionController.getCurrent);

    // POST /subscription/create
    fastify.post('/create', {
        preHandler: [fastify.authenticate],
        schema: { body: CreateSchema }
    }, subscriptionController.create);

    // POST /subscription/activate
    fastify.post('/activate', {
        schema: { body: ActivateSchema }
    }, subscriptionController.activate);

    // POST /subscription/cancel
    fastify.post('/cancel', {
        preHandler: [fastify.authenticate]
    }, subscriptionController.cancel);

    // GET /subscription/history
    fastify.get('/history', {
        preHandler: [fastify.authenticate]
    }, subscriptionController.getHistory);
};
