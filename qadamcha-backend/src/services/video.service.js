const fetch = require('node-fetch');
const crypto = require('crypto');
const config = require('../config/env');

class VideoService {
    constructor() {
        this.libraryId = config.BUNNY_LIBRARY_ID;
        this.apiKey = config.BUNNY_API_KEY;
        this.cdnHost = config.BUNNY_CDN_HOST;
        this.cdnTokenKey = config.BUNNY_CDN_TOKEN_KEY || null; // [FIX SEC-11]
        this.baseUrl = `https://video.bunnycdn.com/library/${this.libraryId}`;
    }

    /**
     * Bitta video ma'lumotlarini olish
     */
    async getVideo(videoId) {
        const response = await fetch(`${this.baseUrl}/videos/${videoId}`, {
            headers: {
                'Accept': 'application/json',
                'AccessKey': this.apiKey
            }
        });

        if (!response.ok) {
            throw new Error(`Video topilmadi: ${videoId}`);
        }

        return response.json();
    }

    /**
     * Barcha videolarni olish (pagination bilan)
     */
    async getAllVideos(page = 1, itemsPerPage = 100) {
        const response = await fetch(
            `${this.baseUrl}/videos?page=${page}&itemsPerPage=${itemsPerPage}`,
            {
                headers: {
                    'Accept': 'application/json',
                    'AccessKey': this.apiKey
                }
            }
        );

        if (!response.ok) {
            throw new Error('Videolarni olishda xato');
        }

        return response.json();
    }

    /**
     * Video qidiruv
     */
    async searchVideos(query, page = 1) {
        const response = await fetch(
            `${this.baseUrl}/videos?search=${encodeURIComponent(query)}&page=${page}`,
            {
                headers: {
                    'Accept': 'application/json',
                    'AccessKey': this.apiKey
                }
            }
        );

        return response.json();
    }

    /**
     * [FIX SEC-11] Bunny CDN Token Authentication
     * Vaqt cheklangan signed URL yaratish — faqat autentifikatsiya qilingan
     * foydalanuvchilar video ko'rishi mumkin
     * @param {string} path - CDN path (e.g. /videoId/playlist.m3u8)
     * @param {number} expiresInSeconds - URL amal qilish muddati (default 4 soat)
     * @returns {string} Signed URL
     */
    _signUrl(path, expiresInSeconds = 14400) {
        if (!this.cdnTokenKey) {
            // Token key sozlanmagan — oddiy URL qaytarish (dev/test uchun)
            return `https://${this.cdnHost}${path}`;
        }

        const expires = Math.floor(Date.now() / 1000) + expiresInSeconds;
        const hashableBase = `${this.cdnTokenKey}${path}${expires}`;
        const token = crypto
            .createHash('sha256')
            .update(hashableBase)
            .digest('base64')
            .replace(/\+/g, '-')
            .replace(/\//g, '_')
            .replace(/=+$/, '');

        return `https://${this.cdnHost}${path}?token=${token}&expires=${expires}`;
    }

    /**
     * HLS streaming URL olish (signed)
     */
    getStreamUrl(videoId) {
        return this._signUrl(`/${videoId}/playlist.m3u8`);
    }

    /**
     * Thumbnail URL olish (signed)
     */
    getThumbnailUrl(videoId) {
        return this._signUrl(`/${videoId}/thumbnail.jpg`, 86400); // 24 soat
    }

    /**
     * Preview animatsiya URL (signed)
     */
    getPreviewUrl(videoId) {
        return this._signUrl(`/${videoId}/preview.webp`, 86400); // 24 soat
    }

    /**
     * Video statistikasini olish
     */
    async getVideoStats(videoId) {
        const response = await fetch(
            `${this.baseUrl}/videos/${videoId}/heatmap`,
            {
                headers: {
                    'Accept': 'application/json',
                    'AccessKey': this.apiKey
                }
            }
        );

        return response.json();
    }

    /**
     * Video ma'lumotlarini to'liq formatda olish
     */
    async getVideoDetails(videoId) {
        const video = await this.getVideo(videoId);

        return {
            id: video.guid,
            title: video.title,
            duration: video.length, // sekundlarda
            thumbnail: this.getThumbnailUrl(video.guid),
            streamUrl: this.getStreamUrl(video.guid),
            preview: this.getPreviewUrl(video.guid),
            status: video.status,
            views: video.views,
            createdAt: video.dateUploaded
        };
    }

    /**
     * Collection (playlist) yaratish
     */
    async createCollection(name) {
        const response = await fetch(`${this.baseUrl}/collections`, {
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'AccessKey': this.apiKey
            },
            body: JSON.stringify({ name })
        });

        return response.json();
    }

    /**
     * Collection ichidagi videolarni olish
     */
    async getCollectionVideos(collectionId) {
        const response = await fetch(
            `${this.baseUrl}/collections/${collectionId}`,
            {
                headers: {
                    'Accept': 'application/json',
                    'AccessKey': this.apiKey
                }
            }
        );

        return response.json();
    }
}

// Singleton
module.exports = new VideoService();
