const { Type } = require('@sinclair/typebox');
const devicesController = require('../controllers/devices.controller');

const LinkSchema = Type.Object({
    familyCode: Type.String({ minLength: 6, maxLength: 6 }),
    childId: Type.String({ minLength: 1 }),
    deviceId: Type.String({ minLength: 1 }),
    deviceName: Type.Optional(Type.String()),
    deviceType: Type.Optional(Type.Union([
        Type.Literal('android'),
        Type.Literal('ios')
    ]))
});

module.exports = async function (fastify) {

    // GET /devices (autentifikatsiya bilan)
    fastify.get('/', {
        preHandler: [fastify.authenticate]
    }, devicesController.getAll);

    // POST /devices/generate-code (autentifikatsiya bilan)
    fastify.post('/generate-code', {
        preHandler: [fastify.authenticate]
    }, devicesController.generateFamilyCode);

    // POST /devices/link (autentifikatsiyasiz - bola qurilmasi uchun)
    fastify.post('/link', {
        schema: { body: LinkSchema }
    }, devicesController.linkDevice);

    // PUT /devices/:id (autentifikatsiya bilan)
    fastify.put('/:id', {
        preHandler: [fastify.authenticate]
    }, devicesController.update);

    // DELETE /devices/:id (autentifikatsiya bilan)
    fastify.delete('/:id', {
        preHandler: [fastify.authenticate]
    }, devicesController.delete);

    // POST /devices/heartbeat (autentifikatsiya bilan)
    fastify.post('/heartbeat', {
        preHandler: [fastify.authenticate]
    }, devicesController.heartbeat);
};
