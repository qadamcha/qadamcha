# 🎬 Bunny.net Video Streaming Konfiguratsiya

> **Qadamcha ilovasi uchun video CDN sozlamalari**

---

## 🔐 Credentials

```env
# .env fayliga qo'shing
BUNNY_STREAM_LIBRARY_ID=596058
BUNNY_STREAM_API_KEY=38f6bf65-641d-43bf-a517d5ee28d0-0dc4-4974
BUNNY_CDN_HOSTNAME=vz-cb48e060-a0f.b-cdn.net
BUNNY_PULL_ZONE=vz-cb48e060-a0f
```

> ⚠️ **MUHIM:** Haqiqiy credentials `.env` faylida saqlanadi, git-ga PUSH qilinmaydi!

---

## 🔗 API Ma'lumotlari

| Parametr | Qiymat |
|----------|--------|
| **Library ID** | `596058` |
| **API Key** | `38f6bf65-641d-43bf-a517d5ee28d0-0dc4-4974` |
| **CDN Hostname** | `vz-cb48e060-a0f.b-cdn.net` |
| **Pull Zone** | `vz-cb48e060-a0f` |
| **Base URL** | `https://video.bunnycdn.com/library/596058` |

---

## 📡 API Endpoints

### Video Upload

```
POST https://video.bunnycdn.com/library/{libraryId}/videos
Authorization: AccessKey {apiKey}
```

### Video olish

```
GET https://video.bunnycdn.com/library/{libraryId}/videos/{videoId}
Authorization: AccessKey {apiKey}
```

### Video stream URL

```
https://{hostname}/{videoId}/playlist.m3u8
```

**Misol:**

```
https://vz-cb48e060-a0f.b-cdn.net/abc123-def456/playlist.m3u8
```

---

## 🎥 Video Upload Flow

```
┌────────────────────────────────────────────────────────────┐
│                 VIDEO UPLOAD FLOW                          │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  1. VIDEO YARATISH                                         │
│     ┌──────────┐    ┌──────────┐    ┌──────────┐          │
│     │  Title   │───▶│  POST    │───▶│  Video   │          │
│     │  Metadata│    │ /videos  │    │   ID     │          │
│     └──────────┘    └──────────┘    └──────────┘          │
│                                                            │
│  2. VIDEO YUKLASH                                          │
│     ┌──────────┐    ┌──────────┐    ┌──────────┐          │
│     │  Video   │───▶│   PUT    │───▶│ Transcode│          │
│     │  File    │    │ /{id}    │    │  Started │          │
│     └──────────┘    └──────────┘    └──────────┘          │
│                                                            │
│  3. STREAM TAYYOR                                          │
│     ┌──────────┐    ┌──────────┐    ┌──────────┐          │
│     │ Webhook  │───▶│  Status: │───▶│  HLS URL │          │
│     │ Callback │    │ Finished │    │  Ready   │          │
│     └──────────┘    └──────────┘    └──────────┘          │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 🔧 Node.js Service

```javascript
// src/services/video.service.js

const BUNNY_LIBRARY_ID = process.env.BUNNY_STREAM_LIBRARY_ID;
const BUNNY_API_KEY = process.env.BUNNY_STREAM_API_KEY;
const BUNNY_CDN_HOST = process.env.BUNNY_CDN_HOSTNAME;
const BASE_URL = `https://video.bunnycdn.com/library/${BUNNY_LIBRARY_ID}`;

class BunnyVideoService {
  
  // Video yaratish (metadata)
  async createVideo(title, collectionId = null) {
    const response = await fetch(`${BASE_URL}/videos`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'AccessKey': BUNNY_API_KEY
      },
      body: JSON.stringify({
        title,
        collectionId
      })
    });
    
    return response.json();
  }
  
  // Video yuklash
  async uploadVideo(videoId, fileBuffer) {
    const response = await fetch(`${BASE_URL}/videos/${videoId}`, {
      method: 'PUT',
      headers: {
        'Accept': 'application/json',
        'AccessKey': BUNNY_API_KEY
      },
      body: fileBuffer
    });
    
    return response.json();
  }
  
  // Video ma'lumotlarini olish
  async getVideo(videoId) {
    const response = await fetch(`${BASE_URL}/videos/${videoId}`, {
      headers: {
        'Accept': 'application/json',
        'AccessKey': BUNNY_API_KEY
      }
    });
    
    return response.json();
  }
  
  // Barcha videolarni olish
  async getAllVideos(page = 1, itemsPerPage = 100) {
    const response = await fetch(
      `${BASE_URL}/videos?page=${page}&itemsPerPage=${itemsPerPage}`,
      {
        headers: {
          'Accept': 'application/json',
          'AccessKey': BUNNY_API_KEY
        }
      }
    );
    
    return response.json();
  }
  
  // Video o'chirish
  async deleteVideo(videoId) {
    const response = await fetch(`${BASE_URL}/videos/${videoId}`, {
      method: 'DELETE',
      headers: {
        'AccessKey': BUNNY_API_KEY
      }
    });
    
    return response.ok;
  }
  
  // Stream URL olish
  getStreamUrl(videoId) {
    return `https://${BUNNY_CDN_HOST}/${videoId}/playlist.m3u8`;
  }
  
  // Thumbnail URL olish
  getThumbnailUrl(videoId) {
    return `https://${BUNNY_CDN_HOST}/${videoId}/thumbnail.jpg`;
  }
  
  // Preview animatsiya URL
  getPreviewUrl(videoId) {
    return `https://${BUNNY_CDN_HOST}/${videoId}/preview.webp`;
  }
}

module.exports = new BunnyVideoService();
```

---

## 📱 Flutter Video Player

```dart
// Flutter da video ko'rish
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoId;
  
  VideoPlayerWidget({required this.videoId});
  
  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  
  @override
  void initState() {
    super.initState();
    final streamUrl = 'https://vz-cb48e060-a0f.b-cdn.net/${widget.videoId}/playlist.m3u8';
    
    _controller = VideoPlayerController.network(streamUrl)
      ..initialize().then((_) {
        setState(() {});
      });
  }
  
  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
      ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
      : CircularProgressIndicator();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

## 📊 Video Status

| Status | Ma'nosi |
|--------|---------|
| `0` | Yaratilgan (yuklash kutilmoqda) |
| `1` | Yuklanmoqda |
| `2` | Qayta ishlash (transcode) |
| `3` | Transcode qilinmoqda |
| `4` | ✅ Tayyor (streaming mumkin) |
| `5` | ❌ Xato |
| `6` | Upload xatosi |

---

## 🔒 Token Authentication (Keyinchalik)

Xavfsizlik uchun Token Auth qo'shamiz. Hozircha public URL lar bilan ishlaymiz.

---

## ✅ Status

- [x] Bunny.net akkaunt yaratildi
- [x] Stream Library yaratildi
- [x] Library ID olindi: `596058`
- [x] API Key olindi
- [x] CDN Hostname olindi
- [x] Service kodi tayyor
- [ ] Token Authentication (keyinchalik)

---

> 📅 **Yaratilgan:** 2026-02-09
> 🔗 **API Docs:** <https://docs.bunny.net/docs/stream-api-overview>
