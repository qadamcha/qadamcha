const { GoogleGenerativeAI } = require('@google/generative-ai');
const config = require('../config/env');

class AiService {
    constructor() {
        this.model = null;
        this.isConfigured = false;

        // API key bo'lsa, modelni sozlash
        if (config.GEMINI_API_KEY && config.GEMINI_API_KEY !== 'your-gemini-api-key') {
            try {
                const genAI = new GoogleGenerativeAI(config.GEMINI_API_KEY);
                this.model = genAI.getGenerativeModel({
                    model: 'gemini-3.0-flash-preview',
                    generationConfig: {
                        maxOutputTokens: 1024,
                        temperature: 0.7,
                    }
                });
                this.isConfigured = true;
                console.log('✅ Gemini AI initialized (gemini-3.0-flash-preview)');
            } catch (error) {
                console.error('Gemini AI sozlashda xato:', error.message);
            }
        }

        // Tizim prompti
        this.systemPrompt = `
Sen "Qadamcha" ilovasining AI maslahatchi yordamchisisan.
Sening vazifang O'zbek ota-onalariga farzand tarbiyasi haqida maslahat berish.

QOIDALAR:
1. Har doim O'ZBEK TILIDA javob ber
2. Ijobiy va qo'llab-quvvatlovchi bo'l
3. Ilmiy asoslangan maslahatlar ber
4. Qisqa va tushunarli gapir (max 200 so'z)
5. Ekran vaqtini cheklash haqida maslahat ber
6. Bola yoshi va jinsi hisobga ol

MAVZULAR:
- Bola tarbiyasi
- Ekran vaqti boshqaruvi
- Sog'lom odatlar
- O'yin va o'rganish balansini
- Ota-ona-bola munosabatlari
    `.trim();
    }

    /**
     * AI bilan suhbat
     */
    async chat(message, context = {}) {
        // AI sozlanmagan bo'lsa
        if (!this.isConfigured) {
            return {
                success: false,
                message: 'AI xizmati hozircha mavjud emas. Keyinroq urinib ko\'ring.'
            };
        }

        try {
            // Promptni shakllantirish
            let prompt = this.systemPrompt;

            // Kontekst qo'shish
            if (context.childAge) {
                prompt += `\n\nBola yoshi: ${context.childAge} yosh`;
            }
            if (context.childGender) {
                prompt += `\nBola jinsi: ${context.childGender === 'male' ? 'O\'g\'il' : 'Qiz'}`;
            }
            if (context.childName) {
                prompt += `\nBola ismi: ${context.childName}`;
            }

            prompt += `\n\nOta-ona savoli: ${message}`;

            // AI javob olish
            const result = await this.model.generateContent(prompt);
            const response = result.response;
            const text = response.text();

            return {
                success: true,
                message: text,
                tokens: response.usageMetadata?.totalTokenCount || 0
            };

        } catch (error) {
            console.error('Gemini AI xatosi:', error.message);

            // Rate limit yoki boshqa xatolar
            if (error.message.includes('quota')) {
                return {
                    success: false,
                    message: 'AI xizmati band. Bir ozdan keyin qayta urinib ko\'ring.'
                };
            }

            return {
                success: false,
                message: 'Kechirasiz, hozir javob bera olmayapman. Keyinroq urinib ko\'ring.'
            };
        }
    }

    /**
     * Tez maslahatlar (oldindan tayyorlangan)
     */
    getQuickTips(childAge) {
        const tips = {
            '3-5': [
                '3-5 yoshda kuniga 1 soatdan ortiq ekran vaqti tavsiya etilmaydi',
                'Bu yoshda o\'yin orqali o\'rganish eng samarali',
                'Uxlashdan 1 soat oldin ekranlarni o\'chiring',
                'Bolaga interaktiv kontentni tanlang, passiv tomosha emas'
            ],
            '6-8': [
                '6-8 yoshda kuniga 1-2 soat ekran vaqti muvofiq',
                'Ta\'limiy o\'yinlar va multfilmlarni tanlang',
                'Bola bilan birga tomosha qiling va muhokama qiling',
                'Jismoniy faollik bilan muvozanatni saqlang'
            ],
            '9-12': [
                '9-12 yoshda kuniga 2 soatgacha ekran vaqti tavsiya etiladi',
                'Ijtimoiy tarmoqlardan ehtiyot bo\'ling',
                'Onlayn xavfsizlik haqida suhbatlashing',
                'Bola qiziqishlariga qarab kontentni tanlang'
            ]
        };

        if (childAge <= 5) return tips['3-5'];
        if (childAge <= 8) return tips['6-8'];
        return tips['9-12'];
    }

    /**
     * AI holatini tekshirish
     */
    getStatus() {
        return {
            configured: this.isConfigured,
            model: this.isConfigured ? 'gemini-pro' : null
        };
    }
}

// Singleton
module.exports = new AiService();
