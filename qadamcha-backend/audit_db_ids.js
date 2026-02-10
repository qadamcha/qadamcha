const mongoose = require('mongoose');
const { Content } = require('./src/models');
const config = require('./src/config/env');

async function audit() {
    try {
        await mongoose.connect(config.MONGODB_URI);
        const contents = await Content.find({});

        for (const c of contents) {
            console.log(`Checking: ${c.title} (${c.videoId}) [Length: ${c.videoId ? c.videoId.length : 0}]`);
            if (c.videoId && c.videoId.length === 35) {
                const fullGuid = c.videoId + '2'; // Based on my search result it was missing '2'
                console.log(`  -> Fixing to: ${fullGuid}`);
                await Content.updateOne({ _id: c._id }, { $set: { videoId: fullGuid } });
            }
        }
    } catch (e) {
        console.error(e);
    }
    process.exit();
}

audit();
