const { Type } = require('@sinclair/typebox');
const userController = require('../controllers/user.controller');

const UpdateProfileSchema = Type.Object({
    name: Type.Optional(Type.String({ minLength: 2, maxLength: 50 })),
    avatar: Type.Optional(Type.String())
});

const ChangePinSchema = Type.Object({
    currentPin: Type.String({ minLength: 4, maxLength: 6, pattern: '^[0-9]+$' }),
    newPin: Type.String({ minLength: 4, maxLength: 6, pattern: '^[0-9]+$' })
});

module.exports = async function (fastify) {

    // GET /user/profile — Profil olish
    fastify.get('/profile', {
        preHandler: [fastify.authenticate]
    }, userController.getProfile);

    // PUT /user/profile — Profil yangilash
    fastify.put('/profile', {
        preHandler: [fastify.authenticate],
        schema: { body: UpdateProfileSchema }
    }, userController.updateProfile);

    // PUT /user/pin — PIN o'zgartirish
    fastify.put('/pin', {
        preHandler: [fastify.authenticate],
        schema: { body: ChangePinSchema }
    }, userController.changePin);

    // DELETE /user/account — Akkountni o'chirish
    fastify.delete('/account', {
        preHandler: [fastify.authenticate]
    }, userController.deleteAccount);
};
