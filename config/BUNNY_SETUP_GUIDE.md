# 🎬 Bunny.net Video Streaming Sozlash

> **Qadam-baqadam yo'riqnoma** — Qadamcha ilovasi uchun video streaming

---

## 📋 Kerakli Sozlamalar

Bunny.net da **ikkita asosiy xizmat** kerak bo'ladi:

| Xizmat | Maqsad | Narx |
|--------|--------|------|
| **Stream (Video Library)** | Videolarni yuklash va transcode qilish | ~$1/1000 daqiqa video |
| **CDN (Pull Zone)** | Videolarni tez yetkazish | $0.005/GB |

---

## 🚀 1-QADAM: Stream Library Yaratish

### 1.1 Stream bo'limiga o'ting

1. Chap menyuda **"Delivery"** → **"Stream"** bosing
2. Yoki to'g'ridan-to'g'ri: <https://dash.bunny.net/stream>

### 1.2 Yangi Video Library yarating

1. **"Add Video Library"** tugmasini bosing
2. Quyidagi ma'lumotlarni kiriting:

```
Video Library Name: qadamcha-videos
Replication Regions: 
  ✅ Europe (Frankfurt) - Yaqin, tez
  ✅ Asia (Singapore) - O'zbekiston uchun yaxshi
```

1. **"Add Video Library"** bosing

### 1.3 Muhim ma'lumotlarni oling

Library yaratilgandan keyin quyidagilarni yozib oling:

```
Library ID: xxxxxxxx (raqam)
API Key: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Hostname: vz-xxxxxx.b-cdn.net
```

**Qayerda topish:**

- **Settings** → **API** bo'limida

---

## 🌍 2-QADAM: CDN Pull Zone Yaratish

### 2.1 Pull Zone yarating

1. **"Delivery"** → **"CDN"** → **"Pull Zones"**
2. **"Add Pull Zone"** bosing

### 2.2 Sozlamalar

```
Pull Zone Name: qadamcha-cdn
Origin URL: (bo'sh qoldiring, Stream ishlatamiz)
Standard Tier: ✅ (arzonroq)

Standard Network:
  ✅ Europe
  ✅ Asia & Oceania  
  ✅ Middle East & Africa
```

### 2.3 Pull Zone yaratilgandan keyin

```
Pull Zone ID: xxxxxxx
CDN Hostname: qadamcha-cdn.b-cdn.net
```

---

## 🔐 3-QADAM: Account API Key Olish

### 3.1 Account Settings

1. Yuqori o'ng burchakda **profil ikonkasini** bosing
2. **"Account Settings"** tanlang
3. **"API"** bo'limiga o'ting

### 3.2 API Key yarating

1. **"API Keys"** bo'limida
2. **"Add API Key"** bosing
3. Nom bering: `qadamcha-backend`
4. Permissions: **Read & Write**
5. **"Add"** bosing

```
Account API Key: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

> ⚠️ **MUHIM:** Bu key faqat bir marta ko'rsatiladi! Yozib oling!

---

## 🔒 4-QADAM: Token Authentication (Xavfsizlik)

Videolarni xavfsiz qilish uchun:

### 4.1 Stream Library Settings

1. **Stream** → **Library** → **Security** tabling
2. **"Token Authentication"** yoqing
3. **Token Authentication Key** ni yozib oling

```
Token Auth Key: xxxxxxxxxxxxxxxxxxxxxxxx
```

### 4.2 Signed URLs

Bu bilan faqat sizning server tomondan berilgan URL lar ishlaydi.

---

## 📝 Menga Kerakli Ma'lumotlar

Hammasi tayyor bo'lgandan keyin menga **4 ta key** yuboring:

```
1. Stream Library ID: _____________
2. Stream API Key: _____________
3. Account API Key: _____________
4. Token Auth Key: _____________
5. CDN Hostname: _____________
```

---

## 📸 Qayerda Topish (Screenshots)

### Stream Library ID va API Key

```
Stream → [Library nomi] → Settings → API
```

### Account API Key

```
Profil → Account Settings → API → API Keys
```

### Token Auth Key

```
Stream → [Library nomi] → Security → Token Authentication Key
```

### CDN Hostname

```
CDN → Pull Zones → [Zone nomi] → General → Hostnames
```

---

## ✅ Checklist

- [ ] Stream Library yaratildi
- [ ] Library ID yozib olindi
- [ ] Stream API Key yozib olindi
- [ ] Pull Zone yaratildi (optional)
- [ ] Account API Key yaratildi
- [ ] Token Authentication yoqildi
- [ ] Token Auth Key yozib olindi

---

## 🎯 Keyingi Qadam

Barcha kalitlarni yig'ganingizdan keyin menga bering, men:

1. Backend integratsiya kodini yozaman
2. Video upload funksiyasini sozlayman
3. HLS streaming ni configure qilaman
4. Flutter video player uchun kod yozaman

---

> 📅 **Yaratilgan:** 2026-02-09
> 🔗 **Bunny Docs:** <https://docs.bunny.net/docs/stream-overview>
