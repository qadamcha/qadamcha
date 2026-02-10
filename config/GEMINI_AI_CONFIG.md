# 🤖 Google Gemini AI Konfiguratsiya

> **Ota-onalar uchun AI maslahatchi**

---

## 🔐 Credentials

```env
# .env fayliga qo'shing
GEMINI_API_KEY=your_api_key_here
GEMINI_MODEL=gemini-pro
```

> ⚠️ **API Key olish:** <https://makersuite.google.com/app/apikey>

---

## 🎯 AI Maslahatchi Maqsadi

1. **Tarbiya maslahatlar** — Bolalarni tarbiyalash haqida
2. **Vaqt boshqaruvi** — Ekran vaqti limitlari
3. **Xulq-atvor** — Bolaning xulqini tushunish
4. **Motivatsiya** — Bolani rag'batlantirish

---

## 🔧 Node.js Service

```javascript
// src/services/ai.service.js

const { GoogleGenerativeAI } = require('@google/generative-ai');

class GeminiService {
  constructor() {
    this.genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
    this.model = this.genAI.getGenerativeModel({ model: 'gemini-pro' });
    
    this.systemPrompt = `
Sen "Qadamcha" ilovasining AI maslahatchi yordamchisisan.
Sening vazifang O'zbek ota-onalariga farzand tarbiyasi haqida maslahat berish.

Qoidalar:
1. Har doim o'zbek tilida javob ber
2. Ijobiy va qo'llab-quvvatlovchi bo'l
3. Ilmiy asoslangan maslahatlar ber
4. Qisqa va tushunarli gapir
5. Bolaning yoshiga qarab maslahat ber
6. Ekran vaqtini cheklash haqida maslahat ber
7. Oilaviy qadriyatlarni hurmat qil
    `.trim();
  }

  async chat(message, childAge = null, chatHistory = []) {
    try {
      // Context qo'shish
      let context = this.systemPrompt;
      if (childAge) {
        context += `\n\nBola yoshi: ${childAge} yosh`;
      }

      // Chat history dan conversation yaratish
      const chat = this.model.startChat({
        history: chatHistory.map(msg => ({
          role: msg.role,
          parts: [{ text: msg.content }]
        })),
        generationConfig: {
          maxOutputTokens: 500,
          temperature: 0.7,
        }
      });

      // Javob olish
      const result = await chat.sendMessage(message);
      const response = await result.response;
      
      return {
        success: true,
        message: response.text(),
        tokensUsed: response.usageMetadata?.totalTokenCount || 0
      };
    } catch (error) {
      console.error('Gemini Error:', error);
      return {
        success: false,
        message: 'Kechirasiz, hozir javob bera olmayapman. Keyinroq urinib ko\'ring.',
        error: error.message
      };
    }
  }

  // Tavsiyalar olish
  async getSuggestions(childAge, recentActivity) {
    const prompt = `
Bola yoshi: ${childAge}
So'nggi faollik: ${recentActivity}

Shu bolaga mos 3 ta qisqa tavsiya ber (har biri 1 gap):
1. Ekran vaqti haqida
2. Rivojlanish haqida
3. Oilaviy vaqt haqida
    `;

    const result = await this.model.generateContent(prompt);
    return result.response.text();
  }
}

module.exports = new GeminiService();
```

---

## 📡 API Endpoints

```javascript
// POST /api/v1/ai/chat
{
  "message": "O'g'lim telefondan ko'p foydalanadi, nima qilsam bo'ladi?",
  "childId": "optional"
}

// Response
{
  "success": true,
  "message": "Bu haqda tashvishlanishingiz to'g'ri...",
  "suggestions": ["Kunlik limit qo'ying", "..."]
}

// GET /api/v1/ai/suggestions?childId=xxx
// GET /api/v1/ai/history?limit=20
```

---

## 💰 Narxlar (Gemini API)

| Model | Narx (1M token) |
|-------|-----------------|
| Gemini Pro | $0.50 input / $1.50 output |
| Gemini Pro Vision | $0.50 input / $1.50 output |

> Free tier: 60 so'rov/minut

---

## ✅ Status

- [x] AI service loyihalashtirildi
- [x] System prompt yaratildi
- [ ] API Key olish (siz)
- [ ] Rate limiting qo'shish
- [ ] Chat history saqlash

---

> 📅 **Yaratilgan:** 2026-02-09
> 🔗 **Docs:** <https://ai.google.dev/docs>
