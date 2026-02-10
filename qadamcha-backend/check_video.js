const mongoose = require('mongoose');
const { Content } = require('./src/models');
const config = require('./src/config/env');

async function check() {
    await mongoose.connect(config.MONGODB_URI);
    console.log('Connected to DB');

    const content = await Content.findOne({ isActive: true, videoId: { $ne: null } });
    if (content) {
        console.log('Found content:', content.title);
        console.log('Video ID:', content.videoId);
        const url = `https://${config.BUNNY_CDN_HOST}/${content.videoId}/playlist.m3u8`;
        console.log('Stream URL:', url);
    } else {
        console.log('No content found');
    }
    process.exit();
}

check();
