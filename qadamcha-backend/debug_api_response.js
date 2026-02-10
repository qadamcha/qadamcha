const fetch = require('node-fetch');

async function checkApi() {
    try {
        const response = await fetch('http://localhost:3000/api/v1/content?limit=5');
        const data = await response.json();

        console.log('--- API RESPONSE ---');
        console.log('Success:', data.success);
        if (data.contents) {
            console.log('Total contents:', data.contents.length);
            data.contents.forEach((c, i) => {
                console.log(`\n[${i}] ${c.title}`);
                console.log(`    ID: ${c._id}`);
                console.log(`    VideoID: ${c.videoId}`);
                console.log(`    Thumbnail: ${c.thumbnailUrl}`);
                console.log(`    Stream: ${c.streamUrl}`);
            });
        }
        console.log('--- END ---');
    } catch (error) {
        console.error('API Error:', error.message);
    }
}

checkApi();
