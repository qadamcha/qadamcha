# Qadamcha Backend

Qadamcha ilovasining backend serveri - Node.js + Fastify

## 🚀 Tez Boshlash

```bash
# Dependencies o'rnatish
npm install

# Development mode
npm run dev

# Production mode
npm start
```

## 📋 Talablar

- Node.js 18+
- MongoDB 6+
- Redis 7+

## 🔧 Environment Sozlamalari

`.env.example` faylini `.env` ga ko'chirib, qiymatlarni o'zgartiring:

```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/qadamcha
REDIS_URL=redis://localhost:6379
JWT_SECRET=your-secret-key
```

## 📁 Fayl Strukturasi

```
src/
├── config/      # Konfiguratsiya fayllari
├── controllers/ # API controllerlari
├── models/      # Mongoose modellari
├── routes/      # API routelari
├── services/    # Business logic
├── middlewares/ # Custom middlewarelar
├── utils/       # Yordamchi funksiyalar
└── app.js       # Entry point
```

## 🔐 API Endpointlar

### Auth

- `POST /api/v1/auth/send-otp` - SMS OTP yuborish
- `POST /api/v1/auth/verify-otp` - OTP tasdiqlash
- `POST /api/v1/auth/register` - Ro'yxatdan o'tish
- `POST /api/v1/auth/login` - Kirish
- `POST /api/v1/auth/refresh` - Token yangilash
- `POST /api/v1/auth/logout` - Chiqish

## 📝 License

MIT
