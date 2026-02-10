# 🚀 QADAMCHA — Texnik Blueprint

> **Loyiha yuragi** — Bu hujjat butun loyiha davomida asosiy yo'l-yo'riq bo'lib xizmat qiladi

---

## 📋 Umumiy Ma'lumot

| Parametr | Qiymat |
|----------|--------|
| **Loyiha nomi** | Qadamcha |
| **Maqsad** | Ota-ona va bolalar uchun vaqt boshqaruvi va nazorat ilovasi |
| **Platformalar** | Android, iOS (Flutter) |
| **Backend** | Node.js + Fastify |
| **Database** | MongoDB |
| **Video CDN** | Bunny.net |
| **SMS Provider** | Eskiz.uz |

---

## 🏗️ Texnologiyalar Stack

### 📱 Frontend (Mobile)

```
Flutter 3.x
├── State Management: Bloc / flutter_bloc
├── HTTP Client: Dio
├── Local Storage: Hive / SharedPreferences
├── Video Player: video_player / chewie
├── QR Scanner: mobile_scanner
└── Push Notifications: firebase_messaging
```

### 🖥️ Backend (API Server)

```
Node.js 20.x LTS
├── Framework: Fastify (2x tezroq Express dan)
├── Validation: @sinclair/typebox + ajv
├── Auth: @fastify/jwt
├── CORS: @fastify/cors
├── Rate Limiting: @fastify/rate-limit
├── WebSocket: @fastify/websocket
└── File Upload: @fastify/multipart
```

### 🗄️ Database

```
MongoDB 7.x
├── ODM: Mongoose
├── Indexes: Compound indexes for performance
├── Sharding: Ready for horizontal scaling
└── Replica Set: 3-node for high availability
```

### ⚡ Cache & Queue

```
Redis 7.x
├── Sessions: User sessions & tokens
├── Cache: API response caching
├── Rate Limit: Request counting
└── Pub/Sub: Real-time notifications
```

### 🔐 Security

```
├── JWT: Access + Refresh tokens
├── bcrypt: Password hashing
├── helmet: HTTP security headers
├── Rate Limit: DDoS protection
└── Input Validation: All endpoints
```

---

## 📁 Loyiha Strukturasi

### Backend (Node.js)

```
qadamcha-backend/
├── src/
│   ├── config/
│   │   ├── database.js      # MongoDB connection
│   │   ├── redis.js         # Redis connection
│   │   ├── env.js           # Environment variables
│   │   └── constants.js     # App constants
│   │
│   ├── models/
│   │   ├── User.js          # Foydalanuvchi modeli
│   │   ├── Child.js         # Bola profili
│   │   ├── Subscription.js  # Obuna modeli
│   │   ├── Device.js        # Qurilmalar
│   │   ├── Activity.js      # Bola faoliyati
│   │   ├── Content.js       # Multfilm/O'yin/Ertak
│   │   └── Payment.js       # To'lov tarixi
│   │
│   ├── routes/
│   │   ├── auth.routes.js   # Autentifikatsiya
│   │   ├── user.routes.js   # Foydalanuvchi
│   │   ├── child.routes.js  # Bola boshqaruvi
│   │   ├── subscription.routes.js
│   │   ├── device.routes.js # Qurilma ulash
│   │   ├── content.routes.js# Kontent
│   │   ├── payment.routes.js# To'lov
│   │   └── ai.routes.js     # AI maslahatchi
│   │
│   ├── controllers/
│   │   └── [har bir route uchun controller]
│   │
│   ├── services/
│   │   ├── sms.service.js   # Eskiz.uz integratsiyasi
│   │   ├── payment.service.js# Payme/Click
│   │   ├── video.service.js # Bunny.net
│   │   ├── ai.service.js    # AI maslahatchi
│   │   └── notification.service.js
│   │
│   ├── middlewares/
│   │   ├── auth.middleware.js    # JWT tekshirish
│   │   ├── parent.middleware.js  # Ota-ona ruxsati
│   │   ├── child.middleware.js   # Bola ruxsati
│   │   ├── subscription.middleware.js # Obuna tekshirish
│   │   └── device.middleware.js  # Qurilma tekshirish
│   │
│   ├── utils/
│   │   ├── response.js      # Standart javoblar
│   │   ├── errors.js        # Xato turlari
│   │   ├── validators.js    # Input validatsiya
│   │   ├── helpers.js       # Yordamchi funksiyalar
│   │   └── logger.js        # Logging
│   │
│   ├── plugins/
│   │   └── [Fastify plugins]
│   │
│   └── app.js               # Main entry point
│
├── tests/
├── docs/
├── .env.example
├── package.json
├── Dockerfile
└── docker-compose.yml
```

### Frontend (Flutter)

```
qadamcha-app/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   ├── theme/
│   │   ├── utils/
│   │   ├── errors/
│   │   └── network/
│   │       ├── api_client.dart
│   │       ├── api_endpoints.dart
│   │       └── interceptors/
│   │
│   ├── data/
│   │   ├── models/
│   │   ├── repositories/
│   │   └── datasources/
│   │       ├── local/
│   │       └── remote/
│   │
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   │
│   ├── presentation/
│   │   ├── bloc/
│   │   ├── pages/
│   │   │   ├── splash/
│   │   │   ├── auth/
│   │   │   ├── parent/
│   │   │   ├── child/
│   │   │   └── common/
│   │   └── widgets/
│   │
│   └── main.dart
│
├── assets/
├── test/
├── pubspec.yaml
└── README.md
```

---

## 🗃️ Database Schema

### Users Collection

```javascript
{
  _id: ObjectId,
  phone: "+998901234567",      // Unique
  name: "Abdulloh",
  pin: "$2b$10$...",          // bcrypt hashed
  role: "parent",             // parent | child
  parentId: ObjectId | null,  // Agar bola bo'lsa
  children: [ObjectId],       // Agar ota-ona bo'lsa
  createdAt: Date,
  updatedAt: Date
}
```

### Children Collection

```javascript
{
  _id: ObjectId,
  parentId: ObjectId,         // Reference to User
  name: "Ali",
  age: 7,
  gender: "male",             // male | female
  avatar: "url",
  dailyLimit: 60,             // daqiqalarda
  currentUsage: 0,            // bugungi ishlatish
  lastActive: Date,
  createdAt: Date
}
```

### Subscriptions Collection

```javascript
{
  _id: ObjectId,
  userId: ObjectId,
  plan: "yearly",             // monthly | yearly | lifetime
  status: "active",           // active | expired | cancelled
  startDate: Date,
  endDate: Date,
  maxDevices: 3,
  price: 214900,
  paymentMethod: "payme",
  transactionId: "string",
  createdAt: Date
}
```

### Devices Collection

```javascript
{
  _id: ObjectId,
  userId: ObjectId,
  childId: ObjectId | null,
  deviceId: "unique-device-id",
  deviceName: "Samsung Galaxy S24",
  deviceType: "android",      // android | ios
  mode: "parent",             // parent | child
  token: "jwt-token",
  familyCode: "847291",       // 6 raqamli kod
  isActive: true,
  lastSeen: Date,
  createdAt: Date
}
```

### Activities Collection

```javascript
{
  _id: ObjectId,
  childId: ObjectId,
  contentId: ObjectId,
  contentType: "cartoon",     // cartoon | game | story | quest
  contentTitle: "Kolobok",
  duration: 720,              // sekundlarda
  startedAt: Date,
  endedAt: Date,
  date: "2026-02-09"          // Indexing uchun
}
```

### Contents Collection

```javascript
{
  _id: ObjectId,
  title: "Kolobok",
  titleUz: "Kolobok",
  type: "cartoon",            // cartoon | game | story | quest
  category: "fairy_tale",
  ageRange: { min: 3, max: 8 },
  duration: 720,
  thumbnail: "url",
  videoUrl: "bunny-net-url",  // HLS stream
  description: "...",
  isActive: true,
  order: 1,
  createdAt: Date
}
```

### Payments Collection

```javascript
{
  _id: ObjectId,
  userId: ObjectId,
  subscriptionId: ObjectId,
  amount: 214900,
  currency: "UZS",
  provider: "payme",          // payme | click | uzum
  transactionId: "external-id",
  status: "completed",        // pending | completed | failed | refunded
  metadata: {},
  createdAt: Date
}
```

---

## 🔌 API Endpoints

### Auth

```
POST   /api/v1/auth/send-otp        # SMS kod yuborish
POST   /api/v1/auth/verify-otp      # Kodni tasdiqlash
POST   /api/v1/auth/register        # Ro'yxatdan o'tish
POST   /api/v1/auth/login           # PIN bilan kirish
POST   /api/v1/auth/refresh         # Token yangilash
POST   /api/v1/auth/reset-pin       # PIN tiklash
POST   /api/v1/auth/logout          # Chiqish
```

### User

```
GET    /api/v1/user/profile         # Profil olish
PUT    /api/v1/user/profile         # Profil yangilash
PUT    /api/v1/user/pin             # PIN o'zgartirish
```

### Children

```
GET    /api/v1/children             # Barcha bolalar
POST   /api/v1/children             # Bola qo'shish
GET    /api/v1/children/:id         # Bitta bola
PUT    /api/v1/children/:id         # Bola yangilash
DELETE /api/v1/children/:id         # Bola o'chirish
GET    /api/v1/children/:id/activity# Faollik tarixi
PUT    /api/v1/children/:id/limit   # Limit o'zgartirish
```

### Devices

```
GET    /api/v1/devices              # Barcha qurilmalar
POST   /api/v1/devices/link         # QR/Kod bilan ulash
DELETE /api/v1/devices/:id          # Qurilma o'chirish
POST   /api/v1/devices/generate-code# Oila kodi yaratish
GET    /api/v1/devices/qr           # QR kod olish
```

### Subscription

```
GET    /api/v1/subscription         # Joriy obuna
GET    /api/v1/subscription/plans   # Mavjud tariflar
POST   /api/v1/subscription/create  # Obuna yaratish
POST   /api/v1/subscription/renew   # Yangilash
GET    /api/v1/subscription/check   # Tekshirish
```

### Payment

```
POST   /api/v1/payment/payme/create # Payme to'lov
POST   /api/v1/payment/payme/callback
POST   /api/v1/payment/click/create # Click to'lov
POST   /api/v1/payment/click/callback
POST   /api/v1/payment/uzum/create  # Uzum to'lov
POST   /api/v1/payment/uzum/callback
GET    /api/v1/payment/history      # To'lov tarixi
```

### Content

```
GET    /api/v1/content/cartoons     # Multfilmlar
GET    /api/v1/content/games        # O'yinlar
GET    /api/v1/content/stories      # Ertaklar
GET    /api/v1/content/quests       # Kvestlar
GET    /api/v1/content/:id          # Tafsilotlar
GET    /api/v1/content/:id/stream   # Video stream URL
POST   /api/v1/content/:id/activity # Faollik yozish
```

### AI

```
POST   /api/v1/ai/chat              # AI maslahatchi
GET    /api/v1/ai/history           # Chat tarixi
GET    /api/v1/ai/suggestions       # Tavsiyalar
```

---

## 🔐 Autentifikatsiya Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    AUTENTIFIKATSIYA                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. TELEFON RAQAM                                           │
│     ┌──────────┐    ┌──────────┐    ┌──────────┐           │
│     │  Telefon │───▶│ Eskiz.uz │───▶│   SMS    │           │
│     │  +998... │    │   API    │    │   kod    │           │
│     └──────────┘    └──────────┘    └──────────┘           │
│                                                             │
│  2. OTP TASDIQLASH                                          │
│     ┌──────────┐    ┌──────────┐    ┌──────────┐           │
│     │   6-kod  │───▶│  Verify  │───▶│  Yangi?  │           │
│     │   kiritish│   │          │    │          │           │
│     └──────────┘    └──────────┘    └────┬─────┘           │
│                                          │                  │
│                              ┌───────────┴───────────┐     │
│                              ▼                       ▼     │
│                         ┌────────┐              ┌────────┐ │
│                         │ Yangi  │              │ Mavjud │ │
│                         │Register│              │  Login │ │
│                         └───┬────┘              └───┬────┘ │
│                             │                       │      │
│                             ▼                       ▼      │
│                      ┌────────────┐          ┌──────────┐  │
│                      │PIN yaratish│          │PIN kirish│  │
│                      └─────┬──────┘          └────┬─────┘  │
│                            │                      │        │
│                            └──────────┬───────────┘        │
│                                       ▼                    │
│                              ┌────────────────┐            │
│                              │  JWT Tokens    │            │
│                              │ Access+Refresh │            │
│                              └────────────────┘            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### JWT Token Struktura

```javascript
// Access Token (15 daqiqa)
{
  userId: "ObjectId",
  role: "parent",
  deviceId: "device-uuid",
  type: "access",
  iat: timestamp,
  exp: timestamp + 15min
}

// Refresh Token (30 kun)
{
  userId: "ObjectId",
  deviceId: "device-uuid",
  type: "refresh",
  iat: timestamp,
  exp: timestamp + 30days
}
```

---

## 📱 Qurilma Ulash Flow

```
┌─────────────────────────────────────────────────────────────┐
│                  QURILMA ULASH LOGIKASI                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  OTA-ONA TELEFONI                    BOLA TELEFONI          │
│  ┌─────────────┐                    ┌─────────────┐         │
│  │ Sozlamalar  │                    │ "Farzandim  │         │
│  │ → Qurilma   │                    │   uchun"    │         │
│  │    ulash    │                    │   bosadi    │         │
│  └──────┬──────┘                    └──────┬──────┘         │
│         │                                  │                │
│         ▼                                  ▼                │
│  ┌─────────────┐                    ┌─────────────┐         │
│  │  QR kod     │◀───── Skaner ─────│   Kamera    │         │
│  │  ko'rsatadi │                    │   ochiladi  │         │
│  └─────────────┘                    └─────────────┘         │
│                                                             │
│         YOKI                               YOKI             │
│                                                             │
│  ┌─────────────┐                    ┌─────────────┐         │
│  │ Oila kodi:  │────── Kiritadi ───▶│  6 raqam    │         │
│  │   847291    │                    │   kiritadi  │         │
│  └─────────────┘                    └─────────────┘         │
│                                                             │
│                         │                                   │
│                         ▼                                   │
│                  ┌─────────────┐                            │
│                  │   Server    │                            │
│                  │ tekshiradi  │                            │
│                  └──────┬──────┘                            │
│                         │                                   │
│              ┌──────────┴──────────┐                        │
│              ▼                     ▼                        │
│       ┌─────────────┐       ┌─────────────┐                 │
│       │ Kod to'g'ri │       │ Kod noto'g'ri│                │
│       │ Qurilma     │       │   Xato!     │                 │
│       │ ulandi ✅   │       │             │                 │
│       └─────────────┘       └─────────────┘                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 💳 To'lov Flow (Payme misol)

```
┌─────────────────────────────────────────────────────────────┐
│                     PAYME TO'LOV                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. CHECKOUT YARATISH                                       │
│     ┌──────────┐    ┌──────────┐    ┌──────────┐           │
│     │ Tarif    │───▶│  Server  │───▶│  Payme   │           │
│     │ tanlash  │    │ /create  │    │ checkout │           │
│     └──────────┘    └──────────┘    └──────────┘           │
│                                                             │
│  2. REDIRECT                                                │
│     ┌──────────┐    ┌──────────┐                           │
│     │  Ilova   │───▶│  Payme   │                           │
│     │ WebView  │    │  sahifa  │                           │
│     └──────────┘    └──────────┘                           │
│                                                             │
│  3. CALLBACK                                                │
│     ┌──────────┐    ┌──────────┐    ┌──────────┐           │
│     │  Payme   │───▶│ /callback│───▶│  Obuna   │           │
│     │  server  │    │          │    │faollashtir│          │
│     └──────────┘    └──────────┘    └──────────┘           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## ⚡ Performance Optimizatsiyalar

### Backend

1. **Redis Cache** — API javoblarni keshlash
2. **MongoDB Indexes** — Tez qidiruv
3. **Connection Pooling** — DB ulanishlarni qayta ishlatish
4. **Compression** — Gzip javoblar
5. **Rate Limiting** — DDoS himoya
6. **Clustering** — CPU yadrolari bo'yicha

### Flutter

1. **Lazy Loading** — Kerakli vaqtda yuklash
2. **Image Caching** — Rasmlarni keshlash
3. **Offline First** — Hive lokalda saqlash
4. **Pagination** — Sahifalash

---

## 🛡️ Xavfsizlik

1. **HTTPS** — Barcha so'rovlar shifrlangan
2. **JWT** — Tokenlar asosida autentifikatsiya
3. **PIN Hashing** — bcrypt bilan
4. **Rate Limit** — So'rovlar cheklash
5. **Input Validation** — Barcha kirishlar tekshiriladi
6. **SQL Injection** — MongoDB NoSQL, Mongoose validation
7. **XSS** — Helmet headers
8. **CORS** — Faqat ruxsat etilgan domainlar

---

## 📊 Monitoring & Logging

```
├── Winston — Logging
├── Morgan — HTTP request logs
├── PM2 — Process manager
├── Prometheus — Metrics
└── Grafana — Dashboards
```

---

## 🚀 Deployment

```
┌─────────────────────────────────────────────────────────────┐
│                      DEPLOYMENT                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   Docker    │───▶│   Nginx    │───▶│   Client    │     │
│  │  Container  │    │ (Reverse   │    │   (App)     │     │
│  │  (Node.js)  │    │   Proxy)   │    │             │     │
│  └──────┬──────┘    └─────────────┘    └─────────────┘     │
│         │                                                   │
│         │           ┌─────────────┐                         │
│         └──────────▶│  MongoDB    │                         │
│                     │   Atlas     │                         │
│         │           └─────────────┘                         │
│         │                                                   │
│         │           ┌─────────────┐                         │
│         └──────────▶│   Redis     │                         │
│                     │   Cloud     │                         │
│                     └─────────────┘                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ Yakunlangan Qarorlar

- [x] **1. Backend texnologiyasi** — Node.js + Fastify ✅
- [x] **2. Eskiz.uz SMS** — Credentials tayyor ✅
- [x] **3. Bunny.net Video** — Credentials tayyor ✅
- [x] **4. To'lov tizimlari** — Test mode (real keylar keyinchalik) ✅
- [x] **5. Qurilma limiti** — 3 ta (o'zgarishi mumkin) ✅
- [x] **6. Kontent manbasi** — O'zim tayyorlayman + Bunny.net ✅
- [x] **7. AI provider** — Google Gemini ✅
- [x] **8. Loyiha nomi** — Qadamcha ✅

---

## 🌟 SIFAT STANDARTLARI

### 📱 App Performance (Smooth & Fast)

```
┌─────────────────────────────────────────────────────────────┐
│                  PERFORMANCE TALABLARI                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  🎯 TARGET METRICS                                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ App Launch Time     │  < 2 soniya (cold start)      │   │
│  │ Screen Transition   │  < 300ms                      │   │
│  │ API Response Time   │  < 500ms (95th percentile)    │   │
│  │ Frame Rate          │  60 FPS (minimum 55 FPS)      │   │
│  │ Memory Usage        │  < 150MB (idle state)         │   │
│  │ Battery Drain       │  < 5% per hour (active use)   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Flutter Optimization Qoidalari

```dart
// 1. CONST CONSTRUCTORS — Rebuild oldini olish
const MyWidget(); // ✅ To'g'ri
MyWidget();       // ❌ Noto'g'ri

// 2. BUILD METHOD — Yengil saqlash
Widget build(BuildContext context) {
  // ❌ Heavy computation
  final data = expensiveOperation();
  
  // ✅ Use cached or computed in initState
  return Text(_cachedData);
}

// 3. LISTVIEW — Large lists uchun
ListView.builder(  // ✅ Lazy loading
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
);

// 4. IMAGE CACHING
CachedNetworkImage(
  imageUrl: url,
  placeholder: (c, u) => CircularProgressIndicator(),
  errorWidget: (c, u, e) => Icon(Icons.error),
);

// 5. ISOLATES — Heavy tasks
await compute(heavyTask, data);
```

### Backend Optimization

```javascript
// 1. CONNECTION POOLING
const mongoose = require('mongoose');
mongoose.connect(uri, {
  maxPoolSize: 100,      // Connection pool
  minPoolSize: 10,
  serverSelectionTimeoutMS: 5000,
});

// 2. QUERY OPTIMIZATION
// ❌ N+1 Query Problem
const users = await User.find();
for (const user of users) {
  const posts = await Post.find({ userId: user._id });
}

// ✅ Use aggregation/populate
const users = await User.find().populate('posts');

// 3. INDEXING
userSchema.index({ phone: 1 });  // Single field
userSchema.index({ parentId: 1, createdAt: -1 });  // Compound

// 4. PAGINATION
const results = await Content.find()
  .skip((page - 1) * limit)
  .limit(limit)
  .lean();  // Plain JS objects (faster)

// 5. CACHING
const cached = await redis.get(`user:${userId}`);
if (cached) return JSON.parse(cached);
const user = await User.findById(userId);
await redis.setex(`user:${userId}`, 3600, JSON.stringify(user));
```

---

## 📐 RESPONSIVE UI (Moslashuvchan Dizayn)

### Qurilma Moslashuvchanligi

```
┌─────────────────────────────────────────────────────────────┐
│              QURILMA TURLARI QO'LLAB-QUVVATLASH             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  📱 MOBIL TELEFONLAR                                        │
│  ├── Kichik (320-375px)    — iPhone SE, eski telefonlar    │
│  ├── O'rta (376-414px)     — iPhone 12/13/14               │
│  └── Katta (415-480px)     — iPhone Pro Max, Galaxy Ultra  │
│                                                             │
│  📱 TABLETLAR                                               │
│  ├── Kichik (481-768px)    — iPad Mini                     │
│  └── Katta (769-1024px)    — iPad Pro                      │
│                                                             │
│  📺 NOTCH & CUTOUT                                          │
│  ├── SafeArea handling                                      │
│  └── Dynamic Island support                                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Flutter Responsive Implementation

```dart
// 1. SCREEN UTILS
import 'package:flutter_screenutil/flutter_screenutil.dart';

// main.dart
ScreenUtilInit(
  designSize: const Size(375, 812),  // Design mockup size
  builder: (context, child) => MyApp(),
);

// Usage
Container(
  width: 100.w,    // Responsive width
  height: 50.h,    // Responsive height
  padding: EdgeInsets.all(16.r),  // Responsive radius
  child: Text(
    'Hello',
    style: TextStyle(fontSize: 14.sp),  // Responsive font
  ),
);

// 2. LAYOUT BUILDER
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 600) {
      return MobileLayout();
    } else {
      return TabletLayout();
    }
  },
);

// 3. MEDIA QUERY
final screenWidth = MediaQuery.of(context).size.width;
final isTablet = screenWidth > 600;
final padding = screenWidth * 0.05;  // 5% of screen

// 4. SAFE AREA
SafeArea(
  child: Scaffold(
    body: MyContent(),
  ),
);

// 5. FLEXIBLE WIDGETS
Row(
  children: [
    Expanded(flex: 2, child: Widget1()),
    Expanded(flex: 1, child: Widget2()),
  ],
);
```

### Font Scaling & Accessibility

```dart
// Foydalanuvchi font size ni o'zgartirsa ham ishlashi kerak
Text(
  'Matn',
  style: TextStyle(fontSize: 16),
  textScaleFactor: 1.0,  // Yoki MediaQuery.textScaleFactorOf(context)
);

// Accessibility
Semantics(
  label: 'Play video button',
  child: IconButton(
    icon: Icon(Icons.play_arrow),
    onPressed: _playVideo,
  ),
);
```

---

## 🛡️ XAVFSIZLIK STANDARTLARI (KUCHLI)

### Xavfsizlik Qatlamlari

```
┌─────────────────────────────────────────────────────────────┐
│                   XAVFSIZLIK ARXITEKTURASI                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  QATLAM 1: NETWORK                                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ✅ HTTPS/TLS 1.3 — Shifrlangan aloqa                │   │
│  │ ✅ Certificate Pinning — MITM oldini olish          │   │
│  │ ✅ Rate Limiting — DDoS himoya                      │   │
│  │ ✅ WAF — Web Application Firewall                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  QATLAM 2: API                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ✅ JWT Authentication — Tokenlar                    │   │
│  │ ✅ Input Validation — Barcha kirishlar              │   │
│  │ ✅ Output Encoding — XSS oldini olish               │   │
│  │ ✅ CORS Policy — Ruxsat etilgan origins             │   │
│  │ ✅ Request Signing — API integrity                  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  QATLAM 3: DATA                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ✅ Encryption at Rest — DB ma'lumotlar              │   │
│  │ ✅ Password Hashing — bcrypt (cost 12)              │   │
│  │ ✅ PII Protection — Shaxsiy ma'lumotlar             │   │
│  │ ✅ Secure Token Storage — Flutter Secure Storage    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  QATLAM 4: APP                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ✅ Code Obfuscation — Decompile qilishni qiyinlashtir│  │
│  │ ✅ Root/Jailbreak Detection — Xavfsiz qurilma       │   │
│  │ ✅ Screenshot Prevention — Maxfiy ekranlar         │   │
│  │ ✅ Biometric Auth — Qo'shimcha xavfsizlik          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Backend Security Implementation

```javascript
// 1. HELMET — HTTP Security Headers
const helmet = require('@fastify/helmet');
fastify.register(helmet, {
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
    },
  },
  hsts: { maxAge: 31536000, includeSubDomains: true },
});

// 2. RATE LIMITING
fastify.register(require('@fastify/rate-limit'), {
  max: 100,           // Max requests
  timeWindow: '1 minute',
  keyGenerator: (req) => req.ip,
  errorResponseBuilder: (req, context) => ({
    statusCode: 429,
    error: 'Too Many Requests',
    message: 'Juda ko\'p so\'rovlar. Keyinroq urinib ko\'ring.'
  })
});

// 3. INPUT VALIDATION (TypeBox)
const { Type } = require('@sinclair/typebox');

const LoginSchema = Type.Object({
  phone: Type.String({ pattern: '^\\+998[0-9]{9}$' }),
  pin: Type.String({ minLength: 4, maxLength: 6 }),
});

// 4. SQL/NoSQL INJECTION PREVENTION
// ❌ Xavfli
const user = await User.findOne({ phone: req.body.phone });

// ✅ Xavfsiz (validation + sanitization)
const { phone } = await fastify.validate(LoginSchema, req.body);
const sanitizedPhone = sanitize(phone);
const user = await User.findOne({ phone: sanitizedPhone });

// 5. ERROR HANDLING — No sensitive info leakage
fastify.setErrorHandler((error, request, reply) => {
  // Log full error internally
  fastify.log.error(error);
  
  // Return safe message to client
  reply.status(error.statusCode || 500).send({
    success: false,
    message: error.statusCode < 500 
      ? error.message 
      : 'Ichki server xatosi'  // Don't expose internal errors
  });
});

// 6. SENSITIVE DATA ENCRYPTION
const crypto = require('crypto');
const algorithm = 'aes-256-gcm';

function encrypt(text, key) {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(algorithm, key, iv);
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  const authTag = cipher.getAuthTag();
  return { iv: iv.toString('hex'), encrypted, authTag: authTag.toString('hex') };
}
```

### Flutter Security Implementation

```dart
// 1. SECURE STORAGE
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

// Token saqlash
await storage.write(key: 'access_token', value: token);

// Token olish
final token = await storage.read(key: 'access_token');

// 2. CERTIFICATE PINNING
import 'package:dio/dio.dart';
import 'package:dio_certificate_pinning/dio_certificate_pinning.dart';

final dio = Dio();
dio.interceptors.add(CertificatePinningInterceptor(
  allowedSHAFingerprints: ['sha256/...'],
));

// 3. ROOT/JAILBREAK DETECTION
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

Future<void> checkDeviceSecurity() async {
  bool isJailBroken = await FlutterJailbreakDetection.jailbroken;
  bool isDeveloperMode = await FlutterJailbreakDetection.developerMode;
  
  if (isJailBroken || isDeveloperMode) {
    // Ogohlantirish yoki cheklash
    showSecurityWarning();
  }
}

// 4. SCREENSHOT PREVENTION
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

// Android: To'lov ekranlarida screenshot oldini olish
await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);

// 5. BIOMETRIC AUTH
import 'package:local_auth/local_auth.dart';

final auth = LocalAuthentication();
final didAuthenticate = await auth.authenticate(
  localizedReason: 'Ilovaga kirish uchun barmoq izi kerak',
  options: AuthenticationOptions(
    stickyAuth: true,
    biometricOnly: true,
  ),
);
```

---

## 🧪 TESTLASH STRATEGIYASI

### Test Pyramidi

```
┌─────────────────────────────────────────────────────────────┐
│                    TEST PYRAMIDI                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                         /\                                  │
│                        /  \          E2E Tests              │
│                       /    \         (10%)                  │
│                      /      \        - Full user flows      │
│                     /────────\                              │
│                    /          \      Integration Tests      │
│                   /            \     (20%)                  │
│                  /              \    - API tests            │
│                 /────────────────\   - DB tests             │
│                /                  \                         │
│               /                    \ Unit Tests             │
│              /                      \(70%)                  │
│             /                        \- Functions           │
│            /──────────────────────────\- Models             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Backend Testing

```javascript
// 1. UNIT TESTS (Jest)
// services/sms.service.test.js
describe('SmsService', () => {
  describe('formatPhone', () => {
    it('should format phone with +998 prefix', () => {
      expect(smsService.formatPhone('901234567')).toBe('998901234567');
    });
    
    it('should remove + from phone', () => {
      expect(smsService.formatPhone('+998901234567')).toBe('998901234567');
    });
  });
  
  describe('generateOtp', () => {
    it('should generate 6 digit code', () => {
      const otp = smsService.generateOtp();
      expect(otp).toMatch(/^\d{6}$/);
    });
  });
});

// 2. INTEGRATION TESTS
// routes/auth.routes.test.js
describe('Auth Routes', () => {
  beforeAll(async () => {
    await mongoose.connect(testDbUri);
  });
  
  afterAll(async () => {
    await mongoose.disconnect();
  });
  
  describe('POST /api/v1/auth/send-otp', () => {
    it('should send OTP to valid phone', async () => {
      const response = await fastify.inject({
        method: 'POST',
        url: '/api/v1/auth/send-otp',
        payload: { phone: '+998901234567' }
      });
      
      expect(response.statusCode).toBe(200);
      expect(JSON.parse(response.payload).success).toBe(true);
    });
    
    it('should reject invalid phone format', async () => {
      const response = await fastify.inject({
        method: 'POST',
        url: '/api/v1/auth/send-otp',
        payload: { phone: 'invalid' }
      });
      
      expect(response.statusCode).toBe(400);
    });
  });
});

// 3. MOCK EXTERNAL SERVICES
jest.mock('../services/sms.service', () => ({
  sendOtp: jest.fn().mockResolvedValue({ success: true }),
}));
```

### Flutter Testing

```dart
// 1. UNIT TESTS
// test/services/auth_service_test.dart
void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockApiClient mockApiClient;
    
    setUp(() {
      mockApiClient = MockApiClient();
      authService = AuthService(apiClient: mockApiClient);
    });
    
    test('sendOtp returns success for valid phone', () async {
      when(mockApiClient.post(any, any))
        .thenAnswer((_) async => Response(data: {'success': true}));
      
      final result = await authService.sendOtp('+998901234567');
      
      expect(result.isSuccess, true);
    });
  });
}

// 2. WIDGET TESTS
// test/widgets/pin_input_test.dart
void main() {
  testWidgets('PinInput renders 4 fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PinInput(length: 4)),
    );
    
    expect(find.byType(TextField), findsNWidgets(4));
  });
  
  testWidgets('PinInput calls onComplete when filled', (tester) async {
    String? enteredPin;
    
    await tester.pumpWidget(
      MaterialApp(
        home: PinInput(
          length: 4,
          onComplete: (pin) => enteredPin = pin,
        ),
      ),
    );
    
    // Enter PIN
    for (int i = 0; i < 4; i++) {
      await tester.enterText(find.byType(TextField).at(i), '${i + 1}');
    }
    
    expect(enteredPin, '1234');
  });
}

// 3. BLOC TESTS
// test/bloc/auth_bloc_test.dart
void main() {
  group('AuthBloc', () {
    late AuthBloc authBloc;
    late MockAuthRepository mockAuthRepository;
    
    setUp(() {
      mockAuthRepository = MockAuthRepository();
      authBloc = AuthBloc(authRepository: mockAuthRepository);
    });
    
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Success] when SendOtp succeeds',
      build: () {
        when(mockAuthRepository.sendOtp(any))
          .thenAnswer((_) async => Right(unit));
        return authBloc;
      },
      act: (bloc) => bloc.add(SendOtpEvent('+998901234567')),
      expect: () => [
        AuthLoading(),
        AuthOtpSent(),
      ],
    );
  });
}

// 4. INTEGRATION TESTS
// integration_test/auth_flow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Complete auth flow', (tester) async {
    await tester.pumpWidget(MyApp());
    
    // Enter phone
    await tester.enterText(find.byKey(Key('phone_input')), '+998901234567');
    await tester.tap(find.byKey(Key('send_otp_button')));
    await tester.pumpAndSettle();
    
    // Verify OTP screen
    expect(find.text('Kodni kiriting'), findsOneWidget);
    
    // Enter OTP
    await tester.enterText(find.byKey(Key('otp_input')), '123456');
    await tester.pumpAndSettle();
    
    // Verify home screen
    expect(find.byKey(Key('home_screen')), findsOneWidget);
  });
}
```

### Test Coverage Talablari

```
┌─────────────────────────────────────────────────────────────┐
│                 TEST COVERAGE TALABLARI                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Komponent           │ Minimum Coverage │ Target Coverage  │
│  ────────────────────┼──────────────────┼─────────────────  │
│  Backend Services    │      80%         │      90%         │
│  Backend Controllers │      70%         │      85%         │
│  Backend Utils       │      90%         │      95%         │
│  Flutter Bloc        │      80%         │      90%         │
│  Flutter Widgets     │      60%         │      75%         │
│  Flutter Services    │      75%         │      85%         │
│  ────────────────────┴──────────────────┴─────────────────  │
│  OVERALL MINIMUM: 75%         OVERALL TARGET: 85%          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### CI/CD Pipeline

```yaml
# .github/workflows/test.yml
name: Test & Build

on: [push, pull_request]

jobs:
  backend-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      
      - name: Install dependencies
        run: cd backend && npm ci
      
      - name: Run tests
        run: cd backend && npm test -- --coverage
      
      - name: Check coverage threshold
        run: |
          COVERAGE=$(cat backend/coverage/coverage-summary.json | jq '.total.lines.pct')
          if (( $(echo "$COVERAGE < 75" | bc -l) )); then
            echo "Coverage too low: $COVERAGE%"
            exit 1
          fi

  flutter-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      
      - name: Install dependencies
        run: cd app && flutter pub get
      
      - name: Run tests
        run: cd app && flutter test --coverage
      
      - name: Check coverage
        run: |
          flutter pub global activate test_coverage
          test_coverage --min 75
```

---

## 🏗️ SCALABLE ARXITEKTURA

### Clean Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CLEAN ARCHITECTURE                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   PRESENTATION                       │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐       │   │
│  │  │  Widgets  │  │   Blocs   │  │   Pages   │       │   │
│  │  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘       │   │
│  └────────┼──────────────┼──────────────┼─────────────┘   │
│           │              │              │                  │
│           ▼              ▼              ▼                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                     DOMAIN                           │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐       │   │
│  │  │ Entities  │  │ Use Cases │  │Repositories│       │   │
│  │  │(interface)│  │           │  │(interface)│       │   │
│  │  └───────────┘  └─────┬─────┘  └───────────┘       │   │
│  └───────────────────────┼────────────────────────────┘   │
│                          │                                 │
│                          ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                      DATA                            │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐       │   │
│  │  │  Models   │  │Repo Impls │  │Data Sources│       │   │
│  │  └───────────┘  └───────────┘  └─────┬─────┘       │   │
│  └──────────────────────────────────────┼─────────────┘   │
│                                         │                  │
│                          ┌──────────────┼──────────────┐  │
│                          ▼              ▼              ▼  │
│                     ┌────────┐    ┌────────┐    ┌────────┐│
│                     │  API   │    │  Local │    │ Cache  ││
│                     │ Remote │    │  Hive  │    │ Redis  ││
│                     └────────┘    └────────┘    └────────┘│
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Backend Modular Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              MODULAR BACKEND ARCHITECTURE                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                     API GATEWAY                      │   │
│  │           (Nginx / Load Balancer)                    │   │
│  └─────────────────────────┬───────────────────────────┘   │
│                            │                                │
│    ┌───────────────────────┼───────────────────────────┐   │
│    │                       │                           │   │
│    ▼                       ▼                           ▼   │
│  ┌───────────┐      ┌───────────┐      ┌───────────┐      │
│  │   Auth    │      │  Content  │      │  Payment  │      │
│  │  Service  │      │  Service  │      │  Service  │      │
│  └─────┬─────┘      └─────┬─────┘      └─────┬─────┘      │
│        │                  │                  │             │
│        └──────────────────┼──────────────────┘             │
│                           │                                 │
│                    ┌──────┴──────┐                         │
│                    │   Message   │                         │
│                    │    Queue    │                         │
│                    │   (Redis)   │                         │
│                    └──────┬──────┘                         │
│                           │                                 │
│              ┌────────────┼────────────┐                   │
│              ▼            ▼            ▼                   │
│         ┌────────┐   ┌────────┐   ┌────────┐              │
│         │MongoDB │   │ Redis  │   │Bunny.net│              │
│         │ Atlas  │   │ Cache  │   │   CDN  │              │
│         └────────┘   └────────┘   └────────┘              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Horizontal Scaling Strategy

```javascript
// 1. STATELESS DESIGN
// Har bir request o'ziga oid, session serverda emas Redis da
app.register(require('@fastify/session'), {
  store: new RedisStore({ client: redisClient }),
});

// 2. DATABASE SHARDING READY
// User ID bo'yicha shard key
const userSchema = new Schema({
  _id: { type: ObjectId, shardKey: true },
  // ...
});

// 3. QUEUE-BASED PROCESSING
// Heavy tasks async bajarish
const Queue = require('bull');
const videoQueue = new Queue('video processing', redisUrl);

videoQueue.process(async (job) => {
  await processVideo(job.data.videoId);
});

// Add job
await videoQueue.add({ videoId: '123' });

// 4. MICROSERVICES READY
// Har bir service alohida deploy qilish mumkin
// auth-service, content-service, payment-service
```

### Future Scalability Plan

```
┌─────────────────────────────────────────────────────────────┐
│                  KENGAYTIRISH REJASI                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  FAZA 1 (0-10K users) — MONOLITH                           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Single Node.js instance                              │   │
│  │ MongoDB Atlas M10                                    │   │
│  │ Redis Labs Free                                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  FAZA 2 (10K-50K users) — VERTICAL + HORIZONTAL            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 3x Node.js instances (PM2 cluster)                   │   │
│  │ MongoDB Atlas M20 + Read Replicas                    │   │
│  │ Redis Labs Paid                                      │   │
│  │ CDN for static assets                                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  FAZA 3 (50K+ users) — MICROSERVICES                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Kubernetes cluster                                   │   │
│  │ Separate services: auth, content, payment, ai       │   │
│  │ MongoDB Sharded Cluster                              │   │
│  │ Redis Cluster                                        │   │
│  │ API Gateway (Kong/Nginx)                             │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 DEVELOPMENT WORKFLOW

### Git Branching Strategy

```
main (production)
  │
  ├── develop (staging)
  │     │
  │     ├── feature/auth-module
  │     ├── feature/payment-integration
  │     └── feature/video-player
  │
  ├── hotfix/critical-bug
  │
  └── release/v1.0.0
```

### Code Review Checklist

```markdown
## Pull Request Checklist

### Code Quality
- [ ] Code follows project style guide
- [ ] No console.log / print statements
- [ ] No hardcoded values (use constants/env)
- [ ] Error handling implemented
- [ ] Comments added for complex logic

### Testing
- [ ] Unit tests added/updated
- [ ] All tests passing
- [ ] Coverage threshold met (75%+)

### Security
- [ ] No sensitive data exposed
- [ ] Input validation implemented
- [ ] SQL/NoSQL injection safe

### Performance
- [ ] No unnecessary re-renders (Flutter)
- [ ] Database queries optimized
- [ ] Large lists use lazy loading

### Documentation
- [ ] API documentation updated
- [ ] README updated if needed
- [ ] Changelog updated
```

---

> 📅 **Yaratilgan:** 2026-02-09
> 📝 **Versiya:** 2.0
> 👤 **Loyiha:** Qadamcha
> ✅ **Status:** Texnik Blueprint to'liq tayyor
