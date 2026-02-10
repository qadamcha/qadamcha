const mongoose = require('mongoose');
const Content = require('./src/models/Content');
const config = require('./src/config/env');

// ------------------------------------------------------------------
// 🎬 VIDEO MA'LUMOTLARINI SHU YERGA KIRITING
// ------------------------------------------------------------------
const videosToUpload = [
    {
        title: "Video Nomi",
        type: "cartoon", // Variantlar: cartoon, game, story, quest
        category: "Kategoriya nomi", // Masalan: Ta'lim, Ertak, Ingliz tili
        description: "Video haqida qisqacha ma'lumot",
        ageRange: { min: 3, max: 7 }, // Yosh oralig'i
        videoId: "bunny-net-video-id", // Bunny.net dan olingan ID
        duration: 300, // Sekundlarda (masalan 5 daqiqa = 300)
        thumbnail: "https://via.placeholder.com/300x200", // Rasm URL (yoki Bunny.net avtomatik qo'yadi)
        tags: ["tag1", "tag2"],
        isFeatured: true // Tavsiya etilganlarda chiqishi uchun
    },
    // Keyingi videolarni shu yerdan davom ettiring...
];

async function uploadContent() {
    try {
        console.log('🔄 Bazaga ulanmoqda...');
        await mongoose.connect(config.MONGODB_URI);
        console.log('✅ Baza ulandi.');

        let successCount = 0;
        let errorCount = 0;

        for (const video of videosToUpload) {
            try {
                // Videoni nomi bo'yicha qidiramiz (agar bor bo'lsa yangilaymiz)
                const existing = await Content.findOne({ title: video.title });

                if (existing) {
                    console.log(`⚠️ "${video.title}" bazada bor. Yangilanmoqda...`);
                    Object.assign(existing, video);
                    await existing.save();
                } else {
                    console.log(`➕ "${video.title}" yangi qo'shilmoqda...`);
                    await Content.create(video);
                }
                successCount++;
            } catch (err) {
                console.error(`❌ Xatolik "${video.title}":`, err.message);
                errorCount++;
            }
        }

        console.log('\n----------------------------------------');
        console.log(`🎉 Natija: ${successCount} ta muvaffaqiyatli, ${errorCount} ta xato.`);
        console.log('----------------------------------------');

        await mongoose.disconnect();
    } catch (error) {
        console.error('Bosh xatolik:', error);
    }
}

uploadContent();
