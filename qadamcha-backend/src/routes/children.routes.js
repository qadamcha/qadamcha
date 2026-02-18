const { Type } = require('@sinclair/typebox');
const childrenController = require('../controllers/children.controller');
const { dailyResetMiddleware } = require('../middlewares/daily-reset.middleware');

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
    weekdayMinutes: Type.Optional(Type.Integer({ minimum: 5, maximum: 480 })),
    weekdayLimit: Type.Optional(Type.Integer({ minimum: 5, maximum: 480 })),
    weekendMinutes: Type.Optional(Type.Integer({ minimum: 5, maximum: 480 })),
    weekendLimit: Type.Optional(Type.Integer({ minimum: 5, maximum: 480 }))
});

const SettingsSchema = Type.Object({
    allowGames: Type.Optional(Type.Boolean()),
    allowVideos: Type.Optional(Type.Boolean()),
    allowStories: Type.Optional(Type.Boolean()),
    safeMode: Type.Optional(Type.Boolean())
});

module.exports = async function (fastify) {

    // Barcha routelar autentifikatsiya talab qiladi
    fastify.addHook('preHandler', fastify.authenticate);

    // GET /children (daily reset middleware bilan)
    fastify.get('/', { preHandler: dailyResetMiddleware }, childrenController.getAll);

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

    // PATCH /children/:id/limits — Flutter app'dan keladi
    fastify.patch('/:id/limits', {
        schema: { body: LimitSchema }
    }, childrenController.setLimit);

    // POST /children/:id/limit — backward compatibility
    fastify.post('/:id/limit', {
        schema: { body: LimitSchema }
    }, childrenController.setLimit);

    // PATCH /children/:id/settings — Bolaning sozlamalari
    fastify.patch('/:id/settings', {
        schema: { body: SettingsSchema }
    }, childrenController.updateSettings);

    // GET /children/:id/activities
    fastify.get('/:id/activities', childrenController.getActivities);

    // GET /children/:id/stats/weekly
    fastify.get('/:id/stats/weekly', childrenController.getWeeklyStatsEndpoint);

    // POST /children/:id/activity — Faoliyatni yozish (vaqt tracking)
    fastify.post('/:id/activity', childrenController.recordActivity);
};
