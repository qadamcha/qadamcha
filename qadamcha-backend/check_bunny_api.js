const fetch = require('node-fetch');
const config = require('./src/config/env');

const LIBRARY_ID = '596058';
const API_KEY = '38f6bf65-641d-43bf-a517d5ee28d0-0dc4-4974'; // From .env

async function checkVideo(videoId) {
    const url = `https://video.bunnycdn.com/library/${LIBRARY_ID}/videos/${videoId}`;
    console.log('Fetching:', url);

    try {
        const response = await fetch(url, {
            headers: {
                'Accept': 'application/json',
                'AccessKey': API_KEY
            }
        });

        if (!response.ok) {
            console.error('Error:', response.status, response.statusText);
            const text = await response.text();
            console.error('Body:', text);
            return;
        }

        const data = await response.json();
        console.log('FULL DATA:', JSON.stringify(data, null, 2));

        // Try to construct URL manually to see if it works
        // Note: The API doesn't return the full CDN hostname usually, but we can verify status.
        // If status is not 3 or 4, it won't play.

    } catch (e) {
        console.error('Exception:', e);
    }
}

// Get ID from DB first
const mongoose = require('mongoose');
const { Content } = require('./src/models');

async function run() {
    await mongoose.connect(config.MONGODB_URI);
    const content = await Content.findOne({ isActive: true, videoId: { $ne: null } });
    if (content) {
        console.log('Checking videoId from DB:', content.videoId);
        await checkVideo(content.videoId);
    } else {
        console.log('No video found in DB');
    }
    process.exit();
}

run();
