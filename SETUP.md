# Qadamcha — Developer Setup

## 1. Backend (qadamcha-backend)

```bash
cd qadamcha-backend
cp .env.example .env
# .env ichiga haqiqiy qiymatlarni yozing (MongoDB, Redis, JWT, Eskiz, Bunny, Gemini)
npm install
npm run dev
```

Backend default portda ishlaydi: `http://localhost:3000`

## 2. Flutter App (qadamcha-app)

```bash
cd qadamcha-app
flutter pub get
```

**Emulator uchun** (default — hech narsa berish shart emas):
```bash
flutter run
```

**Real telefon uchun** (kompyuter va telefon bir WiFi tarmog'ida bo'lishi kerak):
```bash
# O'z kompyuteringiz IP adresini toping:
# Windows: ipconfig → IPv4 Address
# Mac/Linux: ifconfig | grep "inet "

flutter run --dart-define=API_HOST=192.168.0.105
```

**Port o'zgargan bo'lsa:**
```bash
flutter run --dart-define=API_HOST=192.168.0.105 --dart-define=API_PORT=3001
```

## 3. Content Uploader

```bash
cd content-uploader
cp .env.example .env
# .env ichiga haqiqiy qiymatlarni yozing
npm install
npm start
```

## Muhim eslatmalar

- `.env` fayllar gitda yo'q — har bir developer o'zi yaratadi
- `.env.example` fayllardan nusxa olib, haqiqiy qiymatlarni jamoa lideridan so'rang
- Hech qachon `.env` faylni commitlamang!
