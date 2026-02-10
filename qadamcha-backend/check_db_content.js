const mongoose = require('mongoose');
const { Content } = require('./src/models');
const config = require('./src/config/env');

async function checkDb() {
    try {
        await mongoose.connect(config.MONGODB_URI);
        console.log('Connected to DB');

        const count = await Content.countDocuments({});
        console.log('Total documents:', count);

        const activeCount = await Content.countDocuments({ isActive: true });
        console.log('Active documents:', activeCount);

        const contents = await Content.find({}).limit(5);
        contents.forEach(c => {
            console.log(`Title: ${c.title}, Active: ${c.isActive}, VideoID: ${c.videoId}, Thumb: ${c.thumbnail}`);
        });

    } catch (e) {
        console.error(e);
    }
    process.exit();
}

checkDb();
