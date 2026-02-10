const fetch = require('node-fetch');
const config = require('./src/config/env');

async function findVideo() {
    const libraryId = config.BUNNY_STREAM_LIBRARY_ID || 596058;
    const apiKey = config.BUNNY_STREAM_API_KEY || '38f6bf65-641d-43bf-a517d5ee28d0-0dc4-4974';

    try {
        const response = await fetch(`https://video.bunnycdn.com/library/${libraryId}/videos?search=IMG_8153.MOV`, {
            headers: {
                'Accept': 'application/json',
                'AccessKey': apiKey
            }
        });

        const data = await response.json();
        if (data.items && data.items.length > 0) {
            console.log('GUID_FOUND:', data.items[0].guid);
        } else {
            console.log('NOT FOUND');
        }
    } catch (e) {
        console.error(e);
    }
}

findVideo();
