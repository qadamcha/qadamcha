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
                    model: 'gemini-2.0-flash',
                    generationConfig: {
                        maxOutputTokens: 10192,
                        temperature: 0.7,
                    }
                });
                this.isConfigured = true;
                console.log('✅ Gemini AI initialized (gemini-2.0-flash)');
            } catch (error) {
                console.error('Gemini AI sozlashda xato:', error.message);
            }
        }

        // Tizim prompti — professional ota-ona maslahatchi
        this.systemPrompt = `Sen "Qadamcha" ilovasining professional AI maslahatchi yordamchisisan.
Sening asosiy vazifang — O'zbek ota-onalariga farzand tarbiyasi, rivojlanishi va sog'lig'i bo'yicha ILMIY ASOSLANGAN, PROFESSIONAL maslahatlar berish.

=== SHAXSIYATING ===
- Isming: Qadamcha AI Maslahatchi
- Sening muloqot uslubing: iliq, hurmatli, professional va qo'llab-quvvatlovchi
- Sen bolalar psixologiyasi, pedagogika va oilaviy maslahat bo'yicha ekspertsan
- Javoblaringda AAP (American Academy of Pediatrics), WHO va zamonaviy pediatriya tadqiqotlariga asoslanasan

=== MUHIM QOIDALAR ===
1. FAQAT O'ZBEK TILIDA javob ber — boshqa tilda hech qachon javob berma
2. Har bir maslahat ILMIY FAKT va TADQIQOTLARGA asoslangan bo'lsin
3. Javoblar ANIQ, QISQA va AMALIY bo'lsin (150-250 so'z)
4. Har doim bola YOSHINI hisobga ol — har bir yosh guruhi uchun boshqacha yondashuv
5. Agar bola ismi berilgan bo'lsa, uni hurmat bilan ishlatib javob ber
6. Xavfli yoki tibbiy masalalar bo'lsa, ALBATTA shifokorga murojaat qilishni tavsiya et
7. Hech qachon tibbiy tashxis qo'yma — faqat umumiy maslahatlar ber
8. Ota-onani hech qachon ayblama — har doim qo'llab-quvvatla va rag'batlantir

=== JAVOB FORMATI ===
- Javobni tuzilmali ber: asosiy fikr, tushuntirish, amaliy maslahatlar
- Muhim ma'lumotlarni sanab ber (1, 2, 3...)
- Har bir javob oxirida qisqa xulosa yoki rag'batlantiruvchi gap qo'sh
- Emoji ishlat, lekin haddan tashqari ko'p emas (2-4 ta javobda)

=== MUTAXASSISLIK SOHALARING ===
- Bolalar psixologiyasi va xulq-atvor boshqaruvi
- Yosh davrlariga mos rivojlanish bosqichlari (0-18 yosh)
- Ekran vaqtini boshqarish va raqamli sog'liqni saqlash
- Ovqatlanish va jismoniy faollik maslahatlarini berish
- Uyqu rejimini shakllantirish
- Ota-ona va bola o'rtasidagi munosabatlarni mustahkamlash
- Ta'lim va o'qishga motivatsiya berish
- Ijtimoiy ko'nikmalarni rivojlantirish
- Emotsional intellektni shakllantirish
- Bolalar xavfsizligi (internet, ko'cha, uy)

=== TAQIQLANGAN MAVZULAR ===
- Tibbiy dori-darmonlar yoki davolash usullarini tavsiya qilma
- Diniy yoki siyosiy mavzularda fikr bildirma
- Boshqa ota-onalarni yoki tarbiya usullarini tanqid qilma
- O'zingni haqiqiy shifokor yoki psixolog sifatida ko'rsatma`.trim();
    }

    /**
     * AI bilan suhbat — conversation history bilan
     * @param {string} message - Foydalanuvchi xabari
     * @param {Array} history - Oldingi suhbat tarixi [{role: 'user'|'model', text: '...'}]
     * @param {Object} context - Bola konteksti (ismi, yoshi, jinsi)
     */
    async chat(message, history = [], context = {}) {
        // AI sozlanmagan bo'lsa
        if (!this.isConfigured) {
            return {
                success: false,
                message: 'AI xizmati hozircha mavjud emas. Keyinroq urinib ko\'ring.',
                tokenCount: 0
            };
        }

        try {
            // System prompt + bola konteksti
            let systemInstruction = this.systemPrompt;

            if (context.childAge) {
                systemInstruction += `\n\nBola yoshi: ${context.childAge} yosh`;
            }
            if (context.childGender) {
                systemInstruction += `\nBola jinsi: ${context.childGender === 'male' ? 'O\'g\'il' : 'Qiz'}`;
            }
            if (context.childName) {
                systemInstruction += `\nBola ismi: ${context.childName}`;
            }

            // Gemini contents array yaratish — suhbat tarixi
            const contents = [];

            // Oldingi suhbat tarixini qo'shish
            if (history && history.length > 0) {
                for (const msg of history) {
                    contents.push({
                        role: msg.role === 'user' ? 'user' : 'model',
                        parts: [{ text: msg.text }]
                    });
                }
            }

            // Yangi xabarni qo'shish
            contents.push({
                role: 'user',
                parts: [{ text: message }]
            });

            // AI javob olish (90 soniya timeout bilan)
            const AI_TIMEOUT = 90000;
            const timeoutPromise = new Promise((_, reject) =>
                setTimeout(() => reject(new Error('AI_TIMEOUT')), AI_TIMEOUT)
            );

            const result = await Promise.race([
                this.model.generateContent({
                    contents,
                    systemInstruction: { parts: [{ text: systemInstruction }] }
                }),
                timeoutPromise
            ]);

            const response = result.response;
            const text = response.text();
            const tokenCount = response.usageMetadata?.totalTokenCount || 0;

            return {
                success: true,
                message: text,
                tokenCount
            };

        } catch (error) {
            console.error('Gemini AI xatosi:', error.message);

            if (error.message === 'AI_TIMEOUT') {
                return {
                    success: false,
                    message: 'AI javobi juda uzoq davom etdi. Savolingizni qisqaroq qilib qayta yuboring.',
                    tokenCount: 0
                };
            }

            if (error.message.includes('quota')) {
                return {
                    success: false,
                    message: 'AI xizmati band. Bir ozdan keyin qayta urinib ko\'ring.',
                    tokenCount: 0
                };
            }

            return {
                success: false,
                message: 'Kechirasiz, hozir javob bera olmayapman. Keyinroq urinib ko\'ring.',
                tokenCount: 0
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
            model: this.isConfigured ? 'gemini-2.0-flash' : null
        };
    }
}

// Singleton
module.exports = new AiService();
