import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class GuideSection {
  final String type;
  final String? title;
  final String? content;
  final List<String>? items;
  final List<List<String>>? tableData;
  final List<String>? tableHeaders;
  final String? imagePath;
  final String? emoji;
  const GuideSection({required this.type, this.title, this.content, this.items, this.tableData, this.tableHeaders, this.imagePath, this.emoji});
}

class GuideArticle {
  final String emoji;
  final String title;
  final String category;
  final String readTime;
  final Color color;
  final String summary;
  final String heroImage;
  final List<GuideSection> sections;
  const GuideArticle({required this.emoji, required this.title, required this.category, required this.readTime, required this.color, required this.summary, required this.heroImage, required this.sections});
}

const guideCategories = ['Barchasi', 'Tarbiya', 'Psixologiya', 'Sport', 'Ovqatlanish'];

final List<GuideArticle> allGuides = [..._tarbiyaGuides, ..._psixologiyaGuides, ..._sportGuides, ..._ovqatlanishGuides];

const _h = 'assets/images/guides/guide_';

// ═══ TARBIYA (11) ═══
final _tarbiyaGuides = <GuideArticle>[
  GuideArticle(emoji:'👶',title:'Bolani ertalab uyg\'otish usullari',category:'Tarbiya',readTime:'5 min',color:AppColors.kidBlue,heroImage:'${_h}tarbiya.png',summary:'Bolangizni ertalab yoqimli tarzda uyg\'otish uchun ilmiy asoslangan usullar.',sections:[
    GuideSection(type:'text',content:'AQSh Pediatriya Akademiyasi (AAP) bo\'yicha, bolalar 6-12 yoshda kuniga 9-12 soat uxlashi kerak. Bolani qanday uyg\'otishingiz uning butun kunlik kayfiyatiga ta\'sir qiladi.'),
    GuideSection(type:'table',tableHeaders:['Yosh','Uyqu (soat)','Uyg\'onish'],tableData:[['3-5','10-13','6:30-7:00'],['6-8','9-12','6:00-7:00'],['9-12','9-11','6:00-6:30']]),
    GuideSection(type:'list',items:['🌅 Pardalarni sekin oching — tabiiy yorug\'lik melatonin ishlab chiqarishni to\'xtatadi','🎵 Yumshoq musiqa — 60-80 BPM tezlikdagi kuylar eng samarali','🤗 Yumshoq teginish — yelkasini sekin silab uyg\'oting','⏰ Har kuni bir xil vaqtda — sirkadiyan ritm barqarorlashadi','🚫 Baqirish yoki silkitishdan saqlaning — kortizol ko\'tariladi','🍎 Nonushta hidi — miya hid orqali uyg\'onish signali oladi','📖 Ertalabki ritual — kitob yoki qo\'shiq bilan boshlash']),
    GuideSection(type:'fact',emoji:'🔬',title:'Ilmiy fakt',content:'Harvard (2019): Muntazam uyg\'onish vaqtiga ega bolalar maktabda 23% yaxshiroq o\'zlashtirishga erishadi.'),
    GuideSection(type:'tip',title:'Maslahat',content:'Uyg\'otishdan 10 daqiqa oldin xona yorug\'ligini asta-sekin oshiring.'),
  ]),
  GuideArticle(emoji:'📖',title:'Kitob o\'qish odatini shakllantirish',category:'Tarbiya',readTime:'6 min',color:AppColors.kidBlue,heroImage:'${_h}tarbiya.png',summary:'Farzandingizda kitob o\'qish sevgisini uyg\'otish uchun amaliy qo\'llanma.',sections:[
    GuideSection(type:'text',content:'UNESCO: har kuni 20 daqiqa kitob o\'qaydigan bolalar yiliga 1.8 million so\'z o\'qiydi. Bu ularning lug\'at boyligini 3 barobar oshiradi.'),
    GuideSection(type:'table',tableHeaders:['Kunlik','Yillik so\'z','Lug\'at o\'sishi'],tableData:[['5 daq','282,000','+15%'],['20 daq','1,800,000','+45%'],['30 daq','2,700,000','+60%']]),
    GuideSection(type:'list',items:['📚 Uyda kitob burchagi yarating','🕐 Har kuni bir xil vaqtda o\'qing — uyqudan oldin eng samarali','👆 Bola o\'zi yoqtirgan kitobni tanlaydi','🗣️ Ovoz chiqarib o\'qing — tushunishni 40% oshiradi','❓ Savollar bering — "Keyin nima bo\'ladi?"','🎁 Kitobni sovg\'a qiling']),
    GuideSection(type:'fact',emoji:'🔬',title:'Ilmiy fakt',content:'Melburn tadqiqoti: ota-onasi bilan kitob o\'qigan bolalar maktabga tayyorgarlikda 6 oy oldinda.'),
    GuideSection(type:'warning',title:'Eslatma',content:'Bolani kitob o\'qishga majburlamang. O\'zingiz namuna bo\'ling.'),
  ]),
  GuideArticle(emoji:'🤝',title:'Bola bilan muloqot qilish san\'ati',category:'Tarbiya',readTime:'6 min',color:AppColors.kidBlue,heroImage:'${_h}tarbiya.png',summary:'Farzandingiz bilan samarali muloqot o\'rnatish uchun psixologik usullar.',sections:[
    GuideSection(type:'text',content:'Dr. Thomas Gordon tadqiqotlari: "Men-xabarlar" texnikasi bolalar bilan muloqotni 67% yaxshilaydi.'),
    GuideSection(type:'table',tableHeaders:['❌ Noto\'g\'ri','✅ To\'g\'ri'],tableData:[['Sen doim tartibing yo\'q!','Men xonaning tartibsizligidan xafa bo\'lyapman'],['Nega bunday qilding?','Nima bo\'lganini tushuntirsang?'],['Yig\'lama!','Sening xafa bo\'lganingni tushunaman'],['Aytganim aytgan!','Keling, birga hal qilamiz']]),
    GuideSection(type:'list',items:['👂 Faol tinglash — telefonni qo\'ying','👀 Ko\'z kontakti — bolaning balandligiga tushib gaplashing','🤔 Refleksiya — "Sen aytmoqchisanki..."','❤️ His-tuyg\'ularni tan oling','🎯 Muqobil taklif qiling']),
    GuideSection(type:'fact',emoji:'🔬',title:'Ilmiy fakt',content:'Yale (2020): ochiq muloqot qiladigan bolalarda depressiya xavfi 40% past.'),
  ]),
  GuideArticle(emoji:'🧩',title:'Bolada mantiqiy fikrlashni rivojlantirish',category:'Tarbiya',readTime:'6 min',color:AppColors.kidBlue,heroImage:'${_h}tarbiya.png',summary:'Mantiqiy tafakkurni kuchaytiradigan mashq va o\'yinlar.',sections:[
    GuideSection(type:'text',content:'Piaget nazariyasi: 7-11 yoshdagi bolalar konkret operatsional bosqichda mantiqiy fikrlashni faol rivojlantiradi.'),
    GuideSection(type:'table',tableHeaders:['Yosh','Bosqich','Mashqlar'],tableData:[['3-5','Oldindan operatsional','Shakl ajratish, rang guruhlash'],['6-8','Konkret operatsional','Puzzle, shaxmat asoslari'],['9-12','Rivojlangan mantiq','Dasturlash, boshqotirmalar']]),
    GuideSection(type:'list',items:['🧩 Puzzle — 50-100 bo\'lakdan boshlang','♟️ Shaxmat — strategik fikrlashni 35% oshiradi','🔢 Sodoku — raqamli mantiq','🏗️ LEGO — fazoviy tafakkur','💻 Scratch dasturlash — algoritmik fikrlash']),
    GuideSection(type:'tip',title:'Maslahat',content:'Har kuni 15-20 daqiqa mantiqiy mashq qilish kifoya. Asosiysi — muntazamlik!'),
  ]),
  GuideArticle(emoji:'🎨',title:'Ijodkorlikni oshirish: rasm, qo\'shiq, qo\'l mehnati',category:'Tarbiya',readTime:'5 min',color:AppColors.kidBlue,heroImage:'${_h}tarbiya.png',summary:'Bolaning ijodiy qobiliyatlarini rivojlantirish uchun amaliy mashg\'ulotlar.',sections:[
    GuideSection(type:'text',content:'Michigan Universiteti: san\'at bilan shug\'ullanadigan bolalar ijodiy muammolarni hal qilishda 3 barobar samaraliroq.'),
    GuideSection(type:'table',tableHeaders:['Faoliyat','Yosh','Rivojlantiradi'],tableData:[['🎨 Rasm','2+','Mayda motorika, rang sezgisi'],['🎵 Musiqa','3+','Ritm, xotira'],['✂️ Qirqish','4+','Koordinatsiya, sabr'],['🏺 Loy','3+','Sensorik rivojlanish'],['🎭 Teatr','5+','Nutq, ijtimoiy ko\'nikmalar']]),
    GuideSection(type:'list',items:['🖌️ Har kuni 20 daq erkin rasm chizish','🎶 Qo\'shiqlarni birga kuylang','📦 Ijod qutisi tayyorlang','🌿 Tabiatdan materiallar bilan ijod','👏 Natija emas, jarayon muhim — maqtang']),
    GuideSection(type:'fact',emoji:'🔬',title:'Ilmiy fakt',content:'NASA (2018): 5 yoshgacha bolalarning 98% ijodiy daholar darajasida, 25 yoshda bu 2% ga tushadi.'),
  ]),
  GuideArticle(emoji:'📱',title:'Bolani texnologiyadan to\'g\'ri foydalanishga o\'rgatish',category:'Tarbiya',readTime:'7 min',color:AppColors.kidBlue,heroImage:'${_h}tarbiya.png',summary:'Bola va texnologiya: muvozanat saqlash usullari.',sections:[
    GuideSection(type:'text',content:'JSST tavsiyasi: 2 yoshgacha ekran vaqti 0, 2-5 yoshda kuniga 1 soatdan ko\'p bo\'lmasligi kerak.'),
    GuideSection(type:'table',tableHeaders:['Yosh','Tavsiya','Maks'],tableData:[['0-2','Ekransiz','0 daq'],['2-5','30 daq','1 soat'],['6-9','1 soat','1.5 soat'],['10-12','1.5 soat','2 soat']]),
    GuideSection(type:'list',items:['⏰ Aniq vaqt chegarasi qo\'ying','📵 Ovqat va uxlashdan 1 soat oldin ekransiz','👀 Kontent nazorati','🎮 Ta\'limiy kontentni tanlang — Qadamcha','🌳 Har 30 daqiqada 10 daq tanaffus']),
    GuideSection(type:'warning',title:'Ogohlantirish',content:'Ortiqcha ekran vaqti uyqu sifatini 45% pasaytiradi (AAP, 2021).'),
    GuideSection(type:'tip',title:'Maslahat',content:'Qadamcha ilovasining "Vaqt nazorati" funksiyasidan foydalaning!'),
  ]),
  GuideArticle(emoji:'🕐',title:'Bolada vaqt boshqarish ko\'nikmasini shakllantirish',category:'Tarbiya',readTime:'5 min',color:AppColors.kidBlue,heroImage:'${_h}tarbiya.png',summary:'Farzandingizni vaqtni qadrlay olishga o\'rgatish.',sections:[
    GuideSection(type:'text',content:'Duke Universiteti: vaqtni boshqarish ko\'nikmasi erta yoshda o\'rganilsa, maktabdagi muvaffaqiyatni 30% oshiradi.'),
    GuideSection(type:'table',tableHeaders:['Vaqt','Faoliyat','Davomiylik'],tableData:[['7:00','🌅 Uyg\'onish + gigiena','30 daq'],['7:30','🍳 Nonushta','20 daq'],['8:00','📚 Maktab','4-6 soat'],['15:00','🎮 Erkin vaqt','1.5 soat'],['16:30','📝 Uy vazifasi','1 soat'],['18:00','🍽️ Ovqat','30 daq'],['19:00','📖 Oila vaqti','1 soat'],['20:30','😴 Uyqu','30 daq']]),
    GuideSection(type:'list',items:['📋 Vizual jadval yarating','⏳ Taymer ishlating','⭐ Mukofot tizimi — yulduzchalar','🔄 Moslashuvchan, lekin izchil bo\'ling']),
    GuideSection(type:'fact',emoji:'🔬',title:'Ilmiy fakt',content:'Stanford "marshmallow eksperimenti": sabr-toqatli bolalar kattalar bo\'lganda moliyaviy va ijtimoiy muvaffaqiyatliroq.'),
  ]),
  GuideArticle(emoji:'🙏',title:'Bolaga odob-axloqni o\'rgatishning 10 usuli',category:'Tarbiya',readTime:'6 min',color:AppColors.kidBlue,heroImage:'${_h}tarbiya.png',summary:'Yaxshi odob-axloqni shakllantirish uchun amaliy yo\'llar.',sections:[
    GuideSection(type:'text',content:'Albert Bandura "Ijtimoiy o\'rganish nazariyasi": 85% xulq-atvor taqlid orqali shakllanadi.'),
    GuideSection(type:'list',items:['1️⃣ O\'zingiz namuna bo\'ling','2️⃣ "Iltimos" va "Rahmat" — har doim ishlating','3️⃣ Boshqalar hissiyotini tushuntiring — empatiya','4️⃣ Ijobiy xatti-harakatni maqtang','5️⃣ Oilaviy qoidalar o\'rnating','6️⃣ Xatoni tuzatishga imkon bering','7️⃣ Hikoyalar orqali o\'rgating','8️⃣ Ijtimoiy vaziyatlar yarating','9️⃣ Sabr-toqat — natija vaqt oladi','🔟 Sevgi va hurmat — har qanday sharoitda']),
    GuideSection(type:'tip',title:'Maslahat',content:'"Bugun qanday yaxshilik qilding?" — har kecha so\'rang.'),
  ]),
  GuideArticle(emoji:'🌍',title:'Bolani tabiatni sevishga o\'rgatish',category:'Tarbiya',readTime:'4 min',color:AppColors.kidBlue,heroImage:'${_h}tarbiya.png',summary:'Tabiat bolaning ruhiy va jismoniy salomatligini yaxshilaydi.',sections:[
    GuideSection(type:'text',content:'Richard Louv: tabiatdan uzoqlashish bolalarda e\'tibor tanqisligi, semizlik va depressiya xavfini oshiradi.'),
    GuideSection(type:'list',items:['🌱 Birga gul eking','🦋 Hasharotlarni kuzating','🥾 Haftalik tabiat sayri','🪨 Tabiiy materiallar bilan ijod','🐦 Qushlarni kuzating','♻️ Chiqindilarni saralashni o\'rgating']),
    GuideSection(type:'fact',emoji:'🔬',title:'Ilmiy fakt',content:'Tabiatda kuniga 2 soat: stress 28% kam, e\'tibor 20% yaxshi, immunitet kuchli.'),
  ]),
  GuideArticle(emoji:'🧮',title:'Matematikani o\'yin orqali o\'rganish',category:'Tarbiya',readTime:'5 min',color:AppColors.kidBlue,heroImage:'${_h}tarbiya.png',summary:'Matematikani qiziqarli tarzda o\'rgatish usullari.',sections:[
    GuideSection(type:'text',content:'Stanford: o\'yin orqali matematik o\'rgangan bolalar 40% tezroq o\'zlashtiradi, qo\'rquv 60% kamayadi.'),
    GuideSection(type:'table',tableHeaders:['Yosh','O\'yin','Natija'],tableData:[['3-4','Sanash o\'yini','1-10 gacha sanash'],['5-6','Do\'kon o\'yini','Oddiy qo\'shish'],['7-8','Karta o\'yinlari','Ko\'paytirish jadvali'],['9-10','Sudoku','Mantiqiy fikrlash'],['11-12','Dasturlash','Algoritmik tafakkur']]),
    GuideSection(type:'list',items:['🛒 Do\'kon o\'yini — narxlarni qo\'shish','🍕 Pitsani bo\'ling — kasr tushunchasi','📏 Uyni o\'lchang — metr, santimetr','🎯 "Tez javob" — 5 soniyada javob','🧱 Geometrik shakllar bilan qurilish']),
    GuideSection(type:'tip',title:'Maslahat',content:'Xato javobni kulish yoki jahl bilan to\'g\'rilamang. "Yaxshi urinish!" deng.'),
  ]),
  GuideArticle(emoji:'👫',title:'Bolada do\'stlik va jamoaviy ko\'nikmalar',category:'Tarbiya',readTime:'6 min',color:AppColors.kidBlue,heroImage:'${_h}tarbiya.png',summary:'Ijtimoiy ko\'nikmalarni mustahkamlash yo\'llari.',sections:[
    GuideSection(type:'text',content:'Harvard 80 yillik tadqiqot (Grant Study): baxtli hayotning eng muhim omili — mustahkam ijtimoiy munosabatlar.'),
    GuideSection(type:'table',tableHeaders:['Yosh','Ko\'nikma','Rivojlantirish'],tableData:[['3-4','Bo\'lishish','O\'yinchoqlarni navbat bilan'],['5-6','Hamkorlik','Guruhli o\'yinlar'],['7-8','Empatiya','Hissiyotni muhokama'],['9-12','Nizolarni hal qilish','Muzokaralar']]),
    GuideSection(type:'list',items:['🎉 Do\'stlarni uyga taklif qiling','⚽ Guruh sportiga yozing','🎭 Rol o\'yinlari','💬 "Sen nima qilgan bo\'larding?"','🏆 Yutqazishni o\'rgating']),
    GuideSection(type:'fact',emoji:'🔬',title:'Ilmiy fakt',content:'Ijtimoiy ko\'nikmalarga ega bolalar maktabda 25% yaxshi o\'zlashtiradi, ishda 40% muvaffaqiyatliroq.'),
  ]),
];

// ═══ PSIXOLOGIYA (4) ═══
final _psixologiyaGuides = <GuideArticle>[
  GuideArticle(emoji:'🧠',title:'Bolaning xotirasi qanday rivojlanadi?',category:'Psixologiya',readTime:'7 min',color:AppColors.kidPurple,heroImage:'${_h}psixologiya.png',summary:'Bolaning xotirasini mustahkamlash usullari va ilmiy asoslar.',sections:[
    GuideSection(type:'text',content:'Hermann Ebbinghaus tadqiqotlari: muntazam takrorlash xotirani 80% mustahkamlaydi. Bolaning xotirasi 3-6 yoshda eng tez rivojlanadi.'),
    GuideSection(type:'table',tableHeaders:['Yosh','Xotira turi','Sig\'imi'],tableData:[['0-2','Sensorik','Qisqa muddatli ta\'surotlar'],['3-5','Epizodik','Voqealarni eslab qolish'],['6-8','Semantik','Faktlar va tushunchalar'],['9-12','Strategik','Ongli eslab qolish usullari']]),
    GuideSection(type:'list',items:['🎵 Qo\'shiq va she\'rlar — ritmik xotira','🖼️ Vizual kartochkalar — tasviriy xotira','🔁 Kunlik takrorlash — 3 marta takrorlang','🎲 Xotira o\'yinlari — "Nima yo\'qoldi?" o\'yini','😴 Yaxshi uyqu — xotira uyquda mustahkamlanadi']),
    GuideSection(type:'fact',emoji:'🔬',title:'Ilmiy fakt',content:'Tokio Universiteti (2020): Kuniga 30 daqiqa xotira mashqi qiladigan bolalarda o\'zlashtirish 35% yaxshi.'),
  ]),
  GuideArticle(emoji:'🎯',title:'Bolada mas\'uliyat hissini o\'stirish',category:'Psixologiya',readTime:'8 min',color:AppColors.kidPurple,heroImage:'${_h}psixologiya.png',summary:'Farzandingizda mas\'uliyatli bo\'lish ko\'nikmasini shakllantirish.',sections:[
    GuideSection(type:'text',content:'Erik Erikson\'ning psixosotsial rivojlanish nazariyasi: 6-12 yoshdagi "mehnatsevarlik vs pastlik" bosqichida mas\'uliyat hissi shakllanadi.'),
    GuideSection(type:'table',tableHeaders:['Yosh','Mas\'uliyat','Qanday o\'rgatish'],tableData:[['3-4','O\'yinchoqlarni yig\'ish','Birga yig\'ing, maqtang'],['5-6','Kiyimlarni yig\'ish','Vizual ko\'rsatmalar'],['7-8','Uy vazifasi','Jadval va mukofot'],['9-12','Pul boshqarish','Cho\'ntak puli berish']]),
    GuideSection(type:'list',items:['📋 Yoshiga mos vazifalar bering','⭐ Bajarganini maqtang, majburlamang','🔄 Izchil bo\'ling — har kuni bir xil kutish','🤝 Oqibatlarni tushuntiring, jazolamang','📈 Asta-sekin murakkablashtiring']),
    GuideSection(type:'tip',title:'Maslahat',content:'Xato qilsa, jazolamang. "Keling, buni qanday tuzatishni birga o\'ylaymiz" deng.'),
  ]),
  GuideArticle(emoji:'😴',title:'Yaxshi uyqu gigiyenasi',category:'Psixologiya',readTime:'5 min',color:AppColors.kidPurple,heroImage:'${_h}psixologiya.png',summary:'Bolaning sifatli uyqusini ta\'minlash uchun amaliy qo\'llanma.',sections:[
    GuideSection(type:'text',content:'National Sleep Foundation: yomon uyqu bolaning o\'sish gormoni ishlab chiqarishini 70% ga pasaytiradi, o\'zlashtirishni 40% kamaytiradi.'),
    GuideSection(type:'table',tableHeaders:['Yosh','Kerakli uyqu','Yotish vaqti'],tableData:[['3-5','10-13 soat','19:00-20:00'],['6-8','9-12 soat','20:00-21:00'],['9-12','9-11 soat','20:30-21:30']]),
    GuideSection(type:'list',items:['🌙 Uyquga 1 soat oldin ekransiz','🛁 Yotishdan oldin iliq vanna','📖 Uyqu oldi rituali — kitob o\'qish','🌡️ Xona harorati 18-21°C','🔇 Jim muhit yarating','⏰ Har kuni bir xil vaqtda yoting']),
    GuideSection(type:'fact',emoji:'🔬',title:'Ilmiy fakt',content:'Uyqu paytida o\'sish gormoni (GH) eng faol ishlab chiqariladi — bolaning jismoniy rivojlanishi uchun muhim.'),
  ]),
  GuideArticle(emoji:'💪',title:'Bolaning jismoniy faolligi',category:'Psixologiya',readTime:'5 min',color:AppColors.kidPurple,heroImage:'${_h}psixologiya.png',summary:'Jismoniy harakatning bolaning ruhiy salomatligiga ta\'siri.',sections:[
    GuideSection(type:'text',content:'JSST: 5-17 yoshdagi bolalar kuniga kamida 60 daqiqa o\'rtacha-yuqori intensivlikdagi jismoniy faollik bilan shug\'ullanishi kerak.'),
    GuideSection(type:'table',tableHeaders:['Faoliyat','Davomiylik','Foyda'],tableData:[['Yugurish','20 daq','Yurak-qon tizimi'],['Sakrash','15 daq','Suyak mustahkamligi'],['Suzish','30 daq','Barcha mushaklarni rivojlantiradi'],['O\'yin','45 daq','Ijtimoiy+jismoniy']]),
    GuideSection(type:'list',items:['🏃 Har kuni 60 daq harakat','⚽ Sport seksiyasiga yozing','🚶 Maktabga piyoda yuring','🎯 Oilaviy faol dam olish','📵 Harakatni ekran vaqtiga almashtiring']),
    GuideSection(type:'fact',emoji:'🔬',title:'Ilmiy fakt',content:'Lancet (2019): Jismoniy faol bolalarda ADHD alomatlari 30% kam, akademik natijalar 20% yuqori.'),
  ]),
];

// ═══ SPORT (8) ═══
final _sportGuides = <GuideArticle>[
  GuideArticle(emoji:'⚽',title:'Bolalar uchun futbol: necha yoshdan?',category:'Sport',readTime:'5 min',color:AppColors.kidGreen,heroImage:'${_h}sport.png',summary:'Futbolning bolalar rivojlanishiga ta\'siri va boshlash yoshi.',sections:[
    GuideSection(type:'text',content:'UEFA bolalar futboli dasturi: 5-6 yoshdan o\'yin shaklidagi mashqlar, 8 yoshdan taktik o\'rgatish tavsiya etiladi.'),
    GuideSection(type:'table',tableHeaders:['Yosh','Mashq','Maqsad'],tableData:[['4-5','To\'p bilan o\'yin','Koordinatsiya'],['6-7','Asosiy texnika','Dribling, pas'],['8-10','Jamoaviy o\'yin','Taktika, hamkorlik'],['11-12','Maxsus mashqlar','Pozitsiya, strategiya']]),
    GuideSection(type:'list',items:['⚽ Koordinatsiya va chaqqonlikni rivojlantiradi','🤝 Jamoa ruhi va hamkorlikni o\'rgatadi','💪 Chidamlilikni oshiradi — 90 daq davomida harakat','🧠 Tezkor qaror qabul qilish ko\'nikmasi','😊 Ijtimoiy munosabatlarni mustahkamlaydi']),
    GuideSection(type:'tip',title:'Maslahat',content:'Bolani g\'alaba uchun emas, zavqlanish uchun futbol o\'ynashga undang.'),
  ]),
  GuideArticle(emoji:'🏊',title:'Suzish: bolalar uchun eng foydali sport',category:'Sport',readTime:'6 min',color:AppColors.kidGreen,heroImage:'${_h}sport.png',summary:'Suzishning bolalar uchun 360° foydalari va xavfsizlik qoidalari.',sections:[
    GuideSection(type:'text',content:'Griffith Universiteti (2016): suzish bilan shug\'ullanadigan bolalar tengdoshlaridan matematik va savodxonlik bo\'yicha 6-15 oy oldinda.'),
    GuideSection(type:'table',tableHeaders:['Yosh','Bosqich','Mashq'],tableData:[['6 oy-3','Suv bilan tanishish','Ota-ona bilan birga'],['4-5','Asosiy ko\'nikmalar','Suv ustida turish'],['6-8','Texnika','Bras, krol usullari'],['9-12','Mustahkamlash','Tezlik va chidamlilik']]),
    GuideSection(type:'list',items:['🫁 Nafas olish tizimini rivojlantiradi','💪 Barcha mushak guruhlarini ishlaydi','🧘 Stressni kamaytiradi — suv tinchlantiradi','🦴 Bo\'g\'imlarga og\'irlik tushmaydi','🧠 Koordinatsiya va fazoviy tafakkur']),
    GuideSection(type:'warning',title:'Xavfsizlik',content:'Bolani hech qachon suvda yolg\'iz qoldirmang! 4 yoshgacha faqat kattalar nazoratida.'),
  ]),
  GuideArticle(emoji:'🤸',title:'Ertalabki mashqlar: 10 daqiqalik dastur',category:'Sport',readTime:'4 min',color:AppColors.kidGreen,heroImage:'${_h}sport.png',summary:'Bolalar uchun oddiy va samarali ertalabki mashqlar.',sections:[
    GuideSection(type:'text',content:'British Journal of Sports Medicine: ertalabki mashq bolaning e\'tibor jamlashini 3 soatga yaxshilaydi va maktabdagi samaradorlikni 20% oshiradi.'),
    GuideSection(type:'table',tableHeaders:['Mashq','Davomiylik','Foyda'],tableData:[['Cho\'zilish','2 daq','Mushaklarni uyg\'otish'],['Joyida yugurish','2 daq','Yurakni tezlashtirish'],['Sakrash','1 daq','Energiya berish'],['Qo\'l aylantirish','1 daq','Yelka bo\'g\'imlari'],['Egilish','2 daq','Bel moslashuvchanligi'],['Nafas mashqi','2 daq','Tinchlanish']]),
    GuideSection(type:'tip',title:'Maslahat',content:'Mashqni musiqa bilan qiling — bola ko\'proq zavqlanadi va odatlashadi!'),
  ]),
  GuideArticle(emoji:'🚴',title:'Velosiped: xavfsizlik va foydalari',category:'Sport',readTime:'5 min',color:AppColors.kidGreen,heroImage:'${_h}sport.png',summary:'Velosiped haydashning bolalar rivojlanishiga ta\'siri.',sections:[
    GuideSection(type:'text',content:'Velosiped haydash bolalarning muvozanat sezgisi, koordinatsiya va mustaqillik hissini rivojlantiradi. BMJ tadqiqoti: velosipedchi bolalar 30% kam semiradi.'),
    GuideSection(type:'table',tableHeaders:['Yosh','Velosiped turi','Ko\'nikma'],tableData:[['2-3','Balans velosiped','Muvozanat saqlash'],['4-5','16" g\'ildirakli','Pedal bosish'],['6-8','20" velosiped','Mustaqil haydash'],['9-12','24-26" velosiped','Yo\'l qoidalari']]),
    GuideSection(type:'list',items:['🪖 Har doim dubulg\'a kiyish — MAJBURIY!','🦺 Yorug\'lik qaytargichlar','🚦 Yo\'l qoidalarini o\'rgating','👀 Boshida kattalar nazoratida','🔧 Velosipedni muntazam tekshirish']),
    GuideSection(type:'warning',title:'Xavfsizlik',content:'AQShda velosiped jarohatlarining 75% bosh jarohatlar — dubulg\'a xavfni 85% kamaytiradi!'),
  ]),
  GuideArticle(emoji:'🥋',title:'Karate va taekwondo: intizom va himoya',category:'Sport',readTime:'6 min',color:AppColors.kidGreen,heroImage:'${_h}sport.png',summary:'Jang san\'atlarining bolalar tarbiyasidagi o\'rni.',sections:[
    GuideSection(type:'text',content:'Journal of Pediatric Psychology: jang san\'atlari bilan 6 oy shug\'ullangan bolalarda o\'zini boshqarish 42% yaxshilangan, tajovuzkorlik 38% kamaygan.'),
    GuideSection(type:'table',tableHeaders:['San\'at','Yosh','Asosiy foyda'],tableData:[['Karate','5+','Intizom, kuch'],['Taekwondo','6+','Moslashuvchanlik, tezlik'],['Judo','6+','Muvozanat, strategiya'],['Aikido','8+','Tinchlik, himoya']]),
    GuideSection(type:'list',items:['🎯 Intizom va o\'zini boshqarish','🙏 Hurmat va kamtarlik','💪 Jismoniy kuch va moslashuvchanlik','🧠 Diqqat va kontsentratsiya','🛡️ O\'zini himoya qilish ko\'nikmasi']),
    GuideSection(type:'fact',emoji:'🔬',title:'Ilmiy fakt',content:'Jang san\'atlari bilan shug\'ullanadigan bolalarda maktabdagi xulq muammolari 50% kam kuzatiladi.'),
  ]),
  GuideArticle(emoji:'🏃',title:'Bolani sportga qiziqtirish usullari',category:'Sport',readTime:'5 min',color:AppColors.kidGreen,heroImage:'${_h}sport.png',summary:'Farzandingizni sportga sevdirish uchun ota-onalarga maslahatlar.',sections:[
    GuideSection(type:'text',content:'Aspen Institute: sport bilan shug\'ullanadigan bolalarda o\'ziga ishonch 35% yuqori, maktab natijalar 15% yaxshi.'),
    GuideSection(type:'list',items:['🌟 Bola o\'zi tanlaydi — majburlamang!','👨‍👩‍👧 Oilaviy sport — birga yuguring, o\'ynang','📺 Sport musobaqalarini birga tomosha qiling','🏅 Kichik muvaffaqiyatlarni nishonlang','🔄 Turli sportlarni sinab ko\'ring','👫 Do\'stlari bilan birga sport qildiring','🎮 Sport video o\'yinlari — qiziqishni boshlash uchun']),
    GuideSection(type:'warning',title:'Muhim',content:'Bolani hech qachon sport turiga majburlamang. Bu sportga bo\'lgan sevgini o\'ldiradi. O\'zi yoqtirgan sportni qo\'llab-quvvatlang.'),
    GuideSection(type:'tip',title:'Maslahat',content:'Har xil sport turlarini "sinov haftasi" formatida tanishtiring — bola o\'ziga yoqqanini tanlaydi.'),
  ]),
  GuideArticle(emoji:'🧘',title:'Bolalar uchun yoga va moslashuvchanlik',category:'Sport',readTime:'5 min',color:AppColors.kidGreen,heroImage:'${_h}sport.png',summary:'Yoga bolaning jismoniy va ruhiy salomatligiga ijobiy ta\'sir qiladi.',sections:[
    GuideSection(type:'text',content:'Journal of Developmental & Behavioral Pediatrics: yoga bolalarda anxieta (tashvish) alomatlarini 50% kamaytiradi va e\'tiborni 30% yaxshilaydi.'),
    GuideSection(type:'table',tableHeaders:['Poza','Nomi','Foyda'],tableData:[['🌳','Daraxt pozasi','Muvozanat'],['🐕','It pozasi','Cho\'zilish'],['🐍','Ilon pozasi','Orqa mushaklari'],['🦋','Kapalak pozasi','Moslashuvchanlik'],['🧘','Lotus pozasi','Tinchlanish']]),
    GuideSection(type:'list',items:['🕐 Kuniga 10-15 daqiqa kifoya','🎵 Tinch musiqa bilan mashq qiling','🤝 Birga qiling — bolaga namuna','📚 Bolalarga mo\'ljallangan yoga videolari','😊 O\'yin shaklida — hayvonlar pozalari']),
    GuideSection(type:'fact',emoji:'🔬',title:'Ilmiy fakt',content:'Harvard Medical School: yoga qiladigan bolalar stressga 40% yaxshiroq bardosh beradi va uyqu sifati 25% yaxshilanadi.'),
  ]),
  GuideArticle(emoji:'🏀',title:'Guruh sportlari: basketbol va voleybol',category:'Sport',readTime:'6 min',color:AppColors.kidGreen,heroImage:'${_h}sport.png',summary:'Jamoaviy sportlarning bolalar rivojlanishidagi o\'rni.',sections:[
    GuideSection(type:'text',content:'Canadian Society for Exercise Physiology: jamoaviy sport bilan shug\'ullanadigan bolalarda liderlik ko\'nikmasi 45% yuqori, depressiya xavfi 25% kam.'),
    GuideSection(type:'table',tableHeaders:['Sport','Yosh','Asosiy foyda'],tableData:[['Basketbol','6+','Bo\'y o\'sishi, sakrash kuchi'],['Voleybol','8+','Refleks, jamoa ishi'],['Gandbol','7+','Tezlik, chidamlilik'],['Futbol','5+','Koordinatsiya, strategiya']]),
    GuideSection(type:'list',items:['🤝 Jamoa ruhi va hamkorlik','🏆 Sog\'lom raqobat','📊 Strategik fikrlash','💬 Kommunikatsiya ko\'nikmasi','😤 Yutqazishni qabul qilish — hayotiy dars']),
    GuideSection(type:'tip',title:'Maslahat',content:'7 yoshgacha natijaga emas, jarayonga e\'tibor bering. Bolani raqobatga erta solib qo\'ymang.'),
  ]),
];

// ═══ OVQATLANISH (9) ═══
final _ovqatlanishGuides = <GuideArticle>[
  GuideArticle(emoji:'🥗',title:'Bolalar uchun sog\'lom ovqatlanish',category:'Ovqatlanish',readTime:'4 min',color:AppColors.kidYellow,heroImage:'${_h}ovqatlanish.png',summary:'Bolaning to\'g\'ri ovqatlanishi uchun asosiy tamoyillar.',sections:[
    GuideSection(type:'text',content:'JSST tavsiyasi: bolalar kuniga kamida 5 porsiya meva va sabzavot iste\'mol qilishi kerak. Bu yurak kasalliklari xavfini 30% kamaytiradi.'),
    GuideSection(type:'table',tableHeaders:['Guruh','Porsiya/kun','Misollar'],tableData:[['Don mahsulotlari','4-6','Non, guruch, makaron'],['Meva','2-3','Olma, banan, uzum'],['Sabzavot','3-4','Sabzi, pomidor, bodring'],['Oqsil','2-3','Go\'sht, tuxum, loviya'],['Sut mahsulotlari','2-3','Sut, qatiq, pishloq']]),
    GuideSection(type:'list',items:['🌈 Rangli tarelka — har xil rangli ovqatlar','⏰ Muntazam ovqat vaqtlari — 3 asosiy + 2 yengil','🚫 Oldinga turtish emas, o\'rgatish','🥤 Shirinlashtirilgan ichimliklardan saqlaning','👨‍🍳 Bolani oshxonada ishtirok ettiring']),
    GuideSection(type:'fact',emoji:'🔬',title:'Ilmiy fakt',content:'Bolalar 8-15 marta tatib ko\'rgandan keyin yangi ovqatni qabul qiladi. Sabr qiling!'),
  ]),
  GuideArticle(emoji:'🍎',title:'Kundalik vitamin va minerallar',category:'Ovqatlanish',readTime:'5 min',color:AppColors.kidYellow,heroImage:'${_h}ovqatlanish.png',summary:'Bolalar uchun eng muhim vitamin va minerallar va ularning manbalari.',sections:[
    GuideSection(type:'text',content:'UNICEF: Dunyo bo\'ylab har 3-chi bolada vitamin va mineral yetishmovchilik mavjud. To\'g\'ri ovqatlanish buni oldini oladi.'),
    GuideSection(type:'table',tableHeaders:['Vitamin','Foyda','Manbalar'],tableData:[['A','Ko\'rish, immunitet','Sabzi, tuxum, jigar'],['C','Immunitet, teri','Sitrus, qalampir, kivi'],['D','Suyak mustahkamligi','Quyosh, baliq, sut'],['B12','Nerv tizimi','Go\'sht, tuxum, sut'],['Temir','Qon, energiya','Go\'sht, ismaloq, loviya'],['Kalsiy','Suyak va tishlar','Sut, pishloq, brokoli']]),
    GuideSection(type:'warning',title:'Ogohlantirish',content:'Vitamin preparatlarini shifokor tavsiyasisiz bermang. Ortiqcha vitamin ham zararli bo\'lishi mumkin!'),
    GuideSection(type:'tip',title:'Maslahat',content:'Rangdor ovqat tayyorlang: qizil pomidor, yashil brokoli, to\'q sariq sabzi — bu vitaminlar xilma-xilligini ta\'minlaydi.'),
  ]),
  GuideArticle(emoji:'🥛',title:'Sut mahsulotlari: qancha va qachon?',category:'Ovqatlanish',readTime:'4 min',color:AppColors.kidYellow,heroImage:'${_h}ovqatlanish.png',summary:'Bolalar uchun sut mahsulotlarining ahamiyati va me\'yori.',sections:[
    GuideSection(type:'text',content:'AAP tavsiyasi: 1 yoshdan keyin sigir suti berilishi mumkin. 2-3 yoshda to\'liq yog\'li, 3+ yoshda kam yog\'li sut tavsiya etiladi.'),
    GuideSection(type:'table',tableHeaders:['Yosh','Sut (kuniga)','Kalsiy me\'yori'],tableData:[['1-3','2 stakan','700 mg'],['4-8','2.5 stakan','1000 mg'],['9-12','3 stakan','1300 mg']]),
    GuideSection(type:'list',items:['🥛 Sut — kalsiy va vitamin D manbai','🧀 Pishloq — konsentrlangan kalsiy','🥄 Qatiq/yogurt — probiotiklar uchun ajoyib','🍨 Muzqaymoq — cheklangan miqdorda','❌ Laktoza muqobillari — soya suti, bodom suti']),
    GuideSection(type:'fact',emoji:'🔬',title:'Ilmiy fakt',content:'Kalsiy yetarli bo\'lgan bolalarda suyak sinishi xavfi 40% past bo\'ladi (Pediatrics journal, 2019).'),
  ]),
  GuideArticle(emoji:'🍯',title:'Shirinlik o\'rniga tabiiy alternativlar',category:'Ovqatlanish',readTime:'5 min',color:AppColors.kidYellow,heroImage:'${_h}ovqatlanish.png',summary:'Bolangizning shirinlik ishtiyoqini sog\'lom ravishda boshqarish.',sections:[
    GuideSection(type:'text',content:'JSST: bolalar kuniga 25 grammdan ko\'p qo\'shilgan shakar iste\'mol qilmasligi kerak. Bu 6 choy qoshiqqa teng.'),
    GuideSection(type:'table',tableHeaders:['❌ O\'rniga','✅ Tabiiy muqobil'],tableData:[['Shokolad','Kakao + banan smoothie'],['Konfet','Quritilgan mevalar'],['Pechenye','Uy pishirig\'i — kamroq shakar'],['Gazlangan ichimlik','Tabiiy meva sharbati + suv'],['Muzqaymoq','Muzlatilgan banan pure']]),
    GuideSection(type:'list',items:['🍌 Banan — tabiiy shirinlik va energiya','🫐 Mevalar — antioksidantlar bilan boy','🍯 Asal — 1 yoshdan keyin, oz miqdorda','🥜 Yong\'oq — sog\'lom yog\'lar va oqsil','🥕 Sabzi chips — pechda pishirilgan']),
    GuideSection(type:'warning',title:'Ogohlantirish',content:'Shakarli ovqatlar bolada ADHD alomatlarini kuchaytirishi mumkin (Yale University, 2018).'),
  ]),
  GuideArticle(emoji:'🥦',title:'Bolani sabzavot yeyishga o\'rgatish',category:'Ovqatlanish',readTime:'6 min',color:AppColors.kidYellow,heroImage:'${_h}ovqatlanish.png',summary:'Sabzavotlarni bolaga sevdirish uchun ijodiy yondashuvlar.',sections:[
    GuideSection(type:'text',content:'UCL tadqiqoti (2014): bolalar yangi ovqatni qabul qilish uchun 8-15 marta tatib ko\'rishi kerak. Ko\'pchilik ota-onalar 3-5 urinishdan keyin voz kechadi.'),
    GuideSection(type:'list',items:['🎨 Sabzavotdan rasm yarating — yuz, hayvon shakllari','🥤 Smoothiega qo\'shing — banan + ismaloq = yashil smoothie','🍕 Sevimli taomga qo\'shing — pitsa ustiga sabzavot','👨‍🍳 Birga pishiring — bola o\'zi tayyorlagan narsani yeydi','🌱 Sabzavot eking — o\'z hosilini yig\'ish qiziqtiradi','🎮 O\'yin qiling — "Barcha ranglarni yeb ko\'r"','🏆 Mukofot — yangi sabzavot tatib ko\'rgani uchun stiker']),
    GuideSection(type:'tip',title:'Maslahat',content:'Sabzavotni "sog\'lom" deb ta\'riflamang. "Mazali", "qiziqarli" deng — bolalar "sog\'lom" so\'zidan qochadi.'),
  ]),
  GuideArticle(emoji:'🍳',title:'Nonushta: 7 ta oson va foydali retsept',category:'Ovqatlanish',readTime:'5 min',color:AppColors.kidYellow,heroImage:'${_h}ovqatlanish.png',summary:'Bolalar uchun tez, mazali va vitaminlarga boy nonushta g\'oyalari.',sections:[
    GuideSection(type:'text',content:'Harvard School of Public Health: nonushta qiladigan bolalar maktabda 22% yaxshiroq o\'zlashtiradi, energiya darajasi kun davomida barqaror.'),
    GuideSection(type:'table',tableHeaders:['#','Retsept','Tayyorlash vaqti'],tableData:[['1','🥣 Yog\'urt + meva + granola','3 daq'],['2','🍳 Tuxum + pishloqli tost','7 daq'],['3','🥞 Banan pankek (2 komponent)','10 daq'],['4','🥤 Meva smoothie + yulaf','5 daq'],['5','🧇 Tvorog + asal + yong\'oq','3 daq'],['6','🥪 Avokado + tuxumli sendvich','8 daq'],['7','🥣 Sho\'la (bo\'tqa) + quritilgan meva','10 daq']]),
    GuideSection(type:'tip',title:'Maslahat',content:'Kechqurun ingredientlarni tayyorlab qo\'ying — ertalab vaqt tejaysiz!'),
  ]),
  GuideArticle(emoji:'💧',title:'Suv ichish: bolalar uchun qancha kerak?',category:'Ovqatlanish',readTime:'4 min',color:AppColors.kidYellow,heroImage:'${_h}ovqatlanish.png',summary:'Bolaning suv balansini saqlash uchun muhim ma\'lumotlar.',sections:[
    GuideSection(type:'text',content:'European Food Safety Authority: yengil suvsizlanish ham bolaning kognitiv funktsiyasini 10-15% pasaytiradi.'),
    GuideSection(type:'table',tableHeaders:['Yosh','Kunlik suv','Stakan'],tableData:[['1-3','1.3 litr','5-6 stakan'],['4-8','1.7 litr','7-8 stakan'],['9-12','2.1 litr','8-9 stakan']]),
    GuideSection(type:'list',items:['💧 Shaxsiy suv idishlari — o\'zi tanlasin, qiziqarli bo\'lsin','⏰ Har 1 soatda eslatib turing','🍉 Suvga boy mevalar — tarvuz, bodring, apelsin','🚫 Shirin ichimliklarni suv bilan almashtiring','📊 Siydik rangi — och sariq = yetarli suv']),
    GuideSection(type:'fact',emoji:'🔬',title:'Ilmiy fakt',content:'Maktabda suv ichish imkoniyati bo\'lgan bolalarning 25% yaxshiroq natija ko\'rsatishi aniqlangan (Journal of Nutrition, 2020).'),
  ]),
  GuideArticle(emoji:'🍕',title:'Fast food zararmi? Sog\'lom alternativalar',category:'Ovqatlanish',readTime:'6 min',color:AppColors.kidYellow,heroImage:'${_h}ovqatlanish.png',summary:'Fast foodning zararini kamaytirish va uy sharoitida sog\'lom alternativalar.',sections:[
    GuideSection(type:'text',content:'The Lancet (2019): Haftada 2+ marta fast food yeydi bolalarda semizlik xavfi 50%, astma xavfi 27% yuqori.'),
    GuideSection(type:'table',tableHeaders:['Fast food','Kaloriya','Uyda tayyorlash'],tableData:[['🍔 Gamburger','550 kkal','Uy burgeri — 300 kkal'],['🍟 Fri','350 kkal','Pechda kartoshka — 150 kkal'],['🍕 Pitsa','300 kkal','Uy pitsasi — 200 kkal'],['🌭 Hot dog','400 kkal','Tost + sosis — 250 kkal'],['🥤 Kola (330ml)','140 kkal','Limonad — 50 kkal']]),
    GuideSection(type:'list',items:['🏠 Uyda birga tayyorlang — 50% kam kaloriya','📅 Haftada 1 martadan ko\'p bermang','🥗 Salat bilan birga bering','🥤 Suv yoki tabiiy sharbat tanlang','📏 Porsiyani kamaytiring — bolalar porsiyasi']),
    GuideSection(type:'tip',title:'Maslahat',content:'To\'liq taqiqlash ishlamaydi — bu bolada obsessiya uyg\'otadi. O\'rniga, sog\'lom alternativalarni mazaliroq qilib tayyorlang!'),
  ]),
  GuideArticle(emoji:'🫐',title:'Mavsumiy mevalar va ularning foydalari',category:'Ovqatlanish',readTime:'5 min',color:AppColors.kidYellow,heroImage:'${_h}ovqatlanish.png',summary:'Har mavsumda bolangizga qaysi mevalarni berish kerak?',sections:[
    GuideSection(type:'text',content:'Mavsumiy mevalar 30-50% ko\'proq vitamin saqlaydi, chunki ular tabiiy ravishda pishgan va uzoq masofaga tashilmagan.'),
    GuideSection(type:'table',tableHeaders:['Mavsum','Mevalar','Asosiy vitaminlar'],tableData:[['🌸 Bahor','Qulupnay, gilos, o\'rik','C, K, kaliy'],['☀️ Yoz','Tarvuz, shaftoli, uzum','A, C, antioksidantlar'],['🍂 Kuz','Olma, anor, nok','C, temir, B6'],['❄️ Qish','Mandarin, xurmo, banan','C, D, magniy']]),
    GuideSection(type:'list',items:['🌱 Mavsumiy mevalar arzonroq va sifatliroq','🧊 Muzlatib saqlang — qishda ham foydalaning','🥤 Smoothie va kompotlar tayyorlang','🎨 Meva salati — rangdor va mazali','🚫 Import mevalardan ko\'ra mahalliy tanlang']),
    GuideSection(type:'fact',emoji:'🔬',title:'Ilmiy fakt',content:'British Journal of Nutrition: Kuniga 2+ porsiya meva iste\'mol qiladigan bolalarda shamollash xavfi 25% kam.'),
  ]),
];
