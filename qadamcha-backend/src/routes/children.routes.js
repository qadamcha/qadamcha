const { Type } = require('@sinclair/typebox');
const childrenController = require('../controllers/children.controller');

const ChildSchema = Type.Object({
    name: Type.String({ minLength: 2, maxLength: 30 }),
    age: Type.Integer({ minimum: 1, maximum: 18 }),
    gender: Type.Optional(Type.Union([
        Type.Literal('male'),
        Type.Literal('female')
    ])),
    dailyLimit: Type.Optional(Type.Integer({ minimum: 5, maximum: 480 }))
});

const UpdateChildSchema = Type.Object({
    name: Type.Optional(Type.String({ minLength: 2, maxLength: 30 })),
    age: Type.Optional(Type.Integer({ minimum: 1, maximum: 18 })),
    gender: Type.Optional(Type.Union([
        Type.Literal('male'),
        Type.Literal('female')
    ])),
    avatar: Type.Optional(Type.String({ maxLength: 500 })),
    dailyLimit: Type.Optional(Type.Integer({ minimum: 5, maximum: 480 })),
    weekdayLimit: Type.Optional(Type.Integer({ minimum: 5, maximum: 480 })),
    weekendLimit: Type.Optional(Type.Integer({ minimum: 5, maximum: 480 }))
});

const LimitSchema = Type.Object({
    dailyLimit: Type.Optional(Type.Integer({ minimum: 5, maximum: 480 })),
    weekdayLimit: Type.Optional(Type.Integer({ minimum: 5, maximum: 480 })),
    weekendLimit: Type.Optional(Type.Integer({ minimum: 5, maximum: 480 }))
});

module.exports = async function (fastify) {

    // Barcha routelar autentifikatsiya talab qiladi
    fastify.addHook('preHandler', fastify.authenticate);

    // GET /children
    fastify.get('/', childrenController.getAll);

    // GET /children/:id
    fastify.get('/:id', childrenController.getOne);

    // POST /children
    fastify.post('/', {
        schema: { body: ChildSchema }
    }, childrenController.create);

    // PUT /children/:id
    fastify.put('/:id', {
        schema: { body: UpdateChildSchema }
    }, childrenController.update);

    // DELETE /children/:id
    fastify.delete('/:id', childrenController.delete);

    // POST /children/:id/limit
    fastify.post('/:id/limit', {
        schema: { body: LimitSchema }
    }, childrenController.setLimit);

    // GET /children/:id/activities
    fastify.get('/:id/activities', childrenController.getActivities);
};
