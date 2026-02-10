# 📱 Eskiz.uz SMS Integratsiya

> **SMS gateway** — O'zbekistondagi eng ishonchli SMS xizmati

---

## 🔐 Credentials

```env
# .env fayliga qo'shing
ESKIZ_EMAIL=kelajak054@gmail.com
ESKIZ_PASSWORD=0CHFfjdXL4N4DqBdGrbg9sYmZsz2vq8DB1hABoHX
ESKIZ_BASE_URL=https://notify.eskiz.uz/api
```

> ⚠️ **MUHIM:** Haqiqiy credentials `.env` faylida saqlanadi, git-ga PUSH qilinmaydi!

---

## 🔗 API Endpoints

| Endpoint | Method | Tavsif |
|----------|--------|--------|
| `/auth/login` | POST | Token olish |
| `/auth/refresh` | PATCH | Token yangilash |
| `/auth/user` | GET | User ma'lumotlari |
| `/auth/invalidate` | DELETE | Token bekor qilish |
| `/message/sms/send` | POST | SMS yuborish |
| `/message/sms/send-batch` | POST | Ko'p SMS yuborish |
| `/message/sms/get-user-messages` | GET | Yuborilgan SMSlar |
| `/message/sms/get-user-messages-by-dispatch` | GET | Dispatch bo'yicha |
| `/message/sms/get-dispatch-status` | GET | Status tekshirish |

---

## 🔄 SMS Yuborish Flow

```
┌────────────────────────────────────────────────────────────┐
│                   ESKIZ SMS FLOW                           │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  1. AUTH (Token olish)                                     │
│     ┌──────────┐    ┌──────────┐    ┌──────────┐          │
│     │  Email   │───▶│ /auth/   │───▶│  Token   │          │
│     │ Password │    │  login   │    │ (30 kun) │          │
│     └──────────┘    └──────────┘    └──────────┘          │
│                                                            │
│  2. SMS YUBORISH                                           │
│     ┌──────────┐    ┌──────────┐    ┌──────────┐          │
│     │  Token   │───▶│ /message │───▶│  Status  │          │
│     │ + Phone  │    │ /sms/send│    │   ID     │          │
│     │ + Text   │    │          │    │          │          │
│     └──────────┘    └──────────┘    └──────────┘          │
│                                                            │
│  3. STATUS TEKSHIRISH                                      │
│     ┌──────────┐    ┌──────────┐    ┌──────────┐          │
│     │ Status   │───▶│  /get-   │───▶│ Delivered│          │
│     │   ID     │    │ dispatch │    │   /Sent  │          │
│     │          │    │ -status  │    │   /Error │          │
│     └──────────┘    └──────────┘    └──────────┘          │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 📝 API Namunalari

### 1. Token Olish (Login)

```javascript
// POST https://notify.eskiz.uz/api/auth/login
// Content-Type: multipart/form-data

const formData = new FormData();
formData.append('email', 'kelajak054@gmail.com');
formData.append('password', '0CHFfjdXL4N4DqBdGrbg9sYmZsz2vq8DB1hABoHX');

const response = await fetch('https://notify.eskiz.uz/api/auth/login', {
  method: 'POST',
  body: formData
});

const data = await response.json();
// Response:
// {
//   "message": "token_generated",
//   "data": {
//     "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
//   },
//   "token_type": "bearer"
// }
```

### 2. SMS Yuborish

```javascript
// POST https://notify.eskiz.uz/api/message/sms/send
// Authorization: Bearer {token}
// Content-Type: multipart/form-data

const formData = new FormData();
formData.append('mobile_phone', '998901234567'); // 998 bilan, + siz
formData.append('message', 'Sizning tasdiqlash kodingiz: 123456');
formData.append('from', '4546');  // Eskiz bergan sender ID
formData.append('callback_url', 'https://your-api.com/sms/callback'); // Optional

const response = await fetch('https://notify.eskiz.uz/api/message/sms/send', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`
  },
  body: formData
});

const data = await response.json();
// Response:
// {
//   "id": "a]b4a5f0-1234-5678-9abc-def012345678",
//   "status": "waiting",
//   "message": "Waiting for SMS to be sent"
// }
```

### 3. Token Yangilash

```javascript
// PATCH https://notify.eskiz.uz/api/auth/refresh
// Authorization: Bearer {old_token}

const response = await fetch('https://notify.eskiz.uz/api/auth/refresh', {
  method: 'PATCH',
  headers: {
    'Authorization': `Bearer ${token}`
  }
});

const data = await response.json();
// Yangi token qaytadi
```

### 4. SMS Status Tekshirish

```javascript
// GET https://notify.eskiz.uz/api/message/sms/get-dispatch-status?id={dispatch_id}
// Authorization: Bearer {token}

const response = await fetch(
  `https://notify.eskiz.uz/api/message/sms/get-dispatch-status?id=${dispatchId}`,
  {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  }
);

const data = await response.json();
// Status: DELIVERED, SENT, FAILED, EXPIRED
```

---

## 🧪 Test Rejimi

> ⚠️ **Test rejimida** faqat quyidagi matnlar yuborish mumkin:

| Til | Ruxsat etilgan matn |
|-----|---------------------|
| Uzbek | `Bu Eskiz dan test` |
| Russian | `Это тест от Eskiz` |
| English | `This is test from Eskiz` |

Production rejimga o'tish uchun Eskiz.uz bilan bog'laning.

---

## 🛡️ Xavfsizlik Eslatmalari

1. **Token saqlash** — Redis da keshlash (30 kun amal qiladi)
2. **Rate Limit** — Eskiz o'z limitlari bor, tekshiring
3. **Phone format** — `998901234567` format (+ siz, 12 raqam)
4. **Callback URL** — HTTPS bo'lishi kerak (production)
5. **Error handling** — Barcha xatolarni log qiling

---

## 📊 OTP Xabar Formati

```javascript
// Bizning OTP xabarimiz
const otpMessage = (code) => `Qadamcha: Tasdiqlash kodingiz: ${code}. 5 daqiqa amal qiladi.`;

// Yoki qisqa versiya
const otpMessageShort = (code) => `Kod: ${code}`;
```

---

## 🔧 Node.js Service (Eskiz)

Backend uchun tayyor service kodi:

```javascript
// src/services/sms.service.js

const ESKIZ_BASE_URL = 'https://notify.eskiz.uz/api';

class EskizService {
  constructor() {
    this.token = null;
    this.tokenExpiry = null;
  }

  async getToken() {
    // Token mavjud va amal qilayotgan bo'lsa
    if (this.token && this.tokenExpiry > Date.now()) {
      return this.token;
    }

    const formData = new FormData();
    formData.append('email', process.env.ESKIZ_EMAIL);
    formData.append('password', process.env.ESKIZ_PASSWORD);

    const response = await fetch(`${ESKIZ_BASE_URL}/auth/login`, {
      method: 'POST',
      body: formData
    });

    const data = await response.json();
    
    if (data.data?.token) {
      this.token = data.data.token;
      // Token 30 kun amal qiladi, biz 29 kun deymiz xavfsizlik uchun
      this.tokenExpiry = Date.now() + (29 * 24 * 60 * 60 * 1000);
      return this.token;
    }

    throw new Error('Failed to get Eskiz token');
  }

  async sendOtp(phone, code) {
    const token = await this.getToken();
    
    // Phone formatini tekshirish
    const formattedPhone = this.formatPhone(phone);
    
    const message = `Qadamcha: Tasdiqlash kodingiz: ${code}. 5 daqiqa amal qiladi.`;

    const formData = new FormData();
    formData.append('mobile_phone', formattedPhone);
    formData.append('message', message);
    formData.append('from', '4546'); // Yoki sizning sender ID

    const response = await fetch(`${ESKIZ_BASE_URL}/message/sms/send`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`
      },
      body: formData
    });

    const data = await response.json();
    
    return {
      success: !!data.id,
      messageId: data.id,
      status: data.status
    };
  }

  formatPhone(phone) {
    // +998901234567 -> 998901234567
    // 998901234567 -> 998901234567
    // 901234567 -> 998901234567
    let cleaned = phone.replace(/\D/g, '');
    
    if (cleaned.startsWith('998')) {
      return cleaned;
    }
    
    if (cleaned.length === 9) {
      return '998' + cleaned;
    }
    
    return cleaned;
  }

  generateOtp() {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }
}

module.exports = new EskizService();
```

---

## ✅ Status

- [x] Eskiz.uz credentials mavjud
- [x] API hujjatlari o'rganildi
- [x] Service kodi tayyor
- [ ] Production rejimga o'tish (kerak bo'lganda)

---

> 📅 **Yaratilgan:** 2026-02-09
> 🔗 **API Docs:** <https://documenter.getpostman.com/view/663428/RzfmES4z>
