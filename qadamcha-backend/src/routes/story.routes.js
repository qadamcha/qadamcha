const storyController = require('../controllers/story.controller');

module.exports = async function (fastify) {

    // GET /stories - Ochiq endpoint (autentifikatsiyasiz)
    fastify.get('/', storyController.getAll);

    // GET /stories/featured
    fastify.get('/featured', storyController.getFeatured);

    // GET /stories/:id
    fastify.get('/:id', storyController.getOne);
};
