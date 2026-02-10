const fetch = require('node-fetch');
const config = require('../config/env');

class VideoService {
    constructor() {
        this.libraryId = config.BUNNY_LIBRARY_ID;
        this.apiKey = config.BUNNY_API_KEY;
        this.cdnHost = config.BUNNY_CDN_HOST;
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
     * HLS streaming URL olish
     */
    getStreamUrl(videoId) {
        return `https://${this.cdnHost}/${videoId}/playlist.m3u8`;
    }

    /**
     * Thumbnail URL olish
     */
    getThumbnailUrl(videoId) {
        return `https://${this.cdnHost}/${videoId}/thumbnail.jpg`;
    }

    /**
     * Preview animatsiya URL
     */
    getPreviewUrl(videoId) {
        return `https://${this.cdnHost}/${videoId}/preview.webp`;
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
