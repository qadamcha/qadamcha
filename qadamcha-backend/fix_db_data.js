const mongoose = require('mongoose');
const { Content } = require('./src/models');
const config = require('./src/config/env');

async function fixDb() {
    try {
        await mongoose.connect(config.MONGODB_URI);
        console.log('Connected to DB');

        const result = await Content.updateOne(
            { videoId: '899fc577-5a1c-4547-824e-c0c294b528d' },
            { $set: { videoId: '899fc577-5a1c-4547-824e-c0c294b528d2' } }
        );
        console.log('Update Result:', result);

    } catch (e) {
        console.error(e);
    }
    process.exit();
}

fixDb();
