import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;

  static const _categories = [
    // ═══ 1. UMUMIY ═══
    _FaqCategory(
      emoji: '📋',
      title: 'Umumiy',
      color: Color(0xFF2D6A9F),
      questions: [
        _FaqItem(
          question: 'Qadamcha nima?',
          answer:
              'Qadamcha — bu ota-onalar uchun mo\'ljallangan bolalar nazorati '
              'va ta\'lim ilovasi. Ilova orqali siz:\n\n'
              '• Farzandingiz qurilmasini masofadan boshqarasiz\n'
              '• Ekran vaqtini kuzatasiz va cheklaysiz\n'
              '• Bo\'yash o\'yini orqali ijodiy mashq berasiz\n'
              '• Bilimdon AI yordamchisi bilan bola savol-javob qiladi\n'
              '• Ta\'limiy video va hikoyalar tomosha qildirarsiz',
        ),
        _FaqItem(
          question: 'Qadamchadan qanday foydalanaman?',
          answer:
              '1️⃣ Telefon raqamingiz orqali ro\'yxatdan o\'ting\n'
              '2️⃣ SMS tasdiqlash kodini kiriting\n'
              '3️⃣ PIN kod yarating (4 raqamli)\n'
              '4️⃣ Farzandingiz profilini qo\'shing (ism, tug\'ilgan yil)\n'
              '5️⃣ Bola qurilmasiga Qadamcha ilovasini o\'rnating\n'
              '6️⃣ QR kod orqali qurilmani ulang\n'
              '7️⃣ Monitoring avtomatik ishlaydi!',
        ),
        _FaqItem(
          question: 'Ilova qaysi qurilmalarda ishlaydi?',
          answer:
              'Android: 5.0 (Lollipop) va undan yuqori\n'
              'iOS: 13.0 va undan yuqori\n\n'
              'Ota-ona va bola qurilmalari turli platformalardan '
              'bo\'lishi mumkin (masalan, ota-ona iPhone, bola Samsung).\n\n'
              'Eng yaxshi natija uchun qurilmalar so\'nggi versiyaga '
              'yangilangan bo\'lishi tavsiya etiladi.',
        ),
        _FaqItem(
          question: 'Bir nechta bola profilini qo\'shish mumkinmi?',
          answer:
              'Ha! Siz bir nechta bola profilini qo\'shishingiz mumkin:\n\n'
              '• Asosiy sahifadan \"+ Bola qo\'shish\" tugmasini bosing\n'
              '• Har bir bola uchun alohida ism va tug\'ilgan yil kiriting\n'
              '• Har bir bola uchun alohida qurilma ulashingiz mumkin\n'
              '• Profillar orasida osongina almashish mumkin\n\n'
              '📌 Bola profillari soni obuna rejangizga bog\'liq.',
        ),
      ],
    ),

    // ═══ 2. MONITORING ═══
    _FaqCategory(
      emoji: '👁️',
      title: 'Monitoring',
      color: Color(0xFF7C4DFF),
      questions: [
        _FaqItem(
          question: 'Monitoring qanday ishlaydi?',
          answer:
              'Qadamcha bola qurilmasidagi faoliyatni avtomatik kuzatadi:\n\n'
              'Kuzatiladigan ma\'lumotlar:\n'
              '• Ekran vaqti — kunlik va haftalik statistika\n'
              '• Qaysi ilovalar qancha vaqt ishlatilgani\n'
              '• Ilova foydalanish vaqtlari\n\n'
              'Vaqt cheklovlari:\n'
              '• Kunlik ekran vaqtini belgilash mumkin\n'
              '• Muddat tugaganda bola bildirishnoma oladi',
        ),
        _FaqItem(
          question: 'Bola monitoring haqida biladimi?',
          answer:
              'Ha, Qadamcha ochiq nazorat tamoyilida ishlaydi. Bola '
              'qurilmasida Qadamcha ilovasi o\'rnatilgan va bola bu haqda '
              'biladi.\n\n'
              'Psixologlar tavsiyasi: bolaga monitoring maqsadini '
              'tushuntiring — bu nazorat emas, balki xavfsizlik uchun.',
        ),
        _FaqItem(
          question: 'Monitoring ishlamay qolsa nima qilay?',
          answer:
              'Monitoring to\'xtab qolishining sabablari:\n\n'
              '• Bola qurilmasida internet yo\'q\n'
              '• Bola qurilmasi o\'chirilgan\n'
              '• Qadamcha ilovasi fonda ishlashi cheklangan\n\n'
              'Tuzatish:\n'
              '1. Bola qurilmasida internetni tekshiring\n'
              '2. Qadamcha ilovasining \"fonda ishlash\" ruxsatini yoqing\n'
              '3. Batareya optimallashtiruvchidan Qadamchani istisno qiling\n'
              '4. Ilovani so\'nggi versiyaga yangilang',
        ),
        _FaqItem(
          question: 'Monitoring ma\'lumotlari qancha vaqt saqlanadi?',
          answer:
              'Monitoring statistikasi quyidagicha saqlanadi:\n\n'
              '• Kunlik hisobot — 90 kun\n'
              '• Haftalik hisobot — 12 hafta\n'
              '• Umumiy statistika — obuna davomida\n\n'
              'Hisob o\'chirilganda barcha ma\'lumotlar 30 kun ichida '
              'butunlay yo\'q qilinadi.',
        ),
      ],
    ),

    // ═══ 3. BO'YASH VA AI ═══
    _FaqCategory(
      emoji: '🎨',
      title: 'Bo\'yash & AI',
      color: Color(0xFFFF6D00),
      questions: [
        _FaqItem(
          question: 'Bo\'yash o\'yini qanday ishlaydi?',
          answer:
              'Qadamcha ichida 70+ bo\'yash rasmi mavjud, 5 ta kategoriyada:\n\n'
              'Hayvonlar — mushuk, it, fil va boshqalar\n'
              'Mashinalar — mashina, samolyot, raketa\n'
              'Mevalar — olma, banan, tarvuz\n'
              'Tabiat — daraxt, quyosh, kamalak\n'
              'Poliz mevalari — pomidor, sabzi, qovoq\n\n'
              'Bola rasmni tanlab, qalamchalar bilan bo\'yaydi. '
              'Bo\'yalgan rasmlarni saqlash va galereyada ko\'rish mumkin.',
        ),
        _FaqItem(
          question: 'Bo\'yalgan rasmlar qaerda saqlanadi?',
          answer:
              'Bo\'yalgan rasmlar faqat mahalliy qurilmada saqlanadi '
              '(serverga yuborilmaydi).\n\n'
              '• \"Rasmlarim\" bo\'limida barcha saqlangan rasmlarni ko\'rishingiz mumkin\n'
              '• Rasmlarni o\'chirish ham mumkin\n'
              '• Ilovani o\'chirsangiz, rasmlar ham o\'chadi',
        ),
        _FaqItem(
          question: 'Bilimdon AI nima?',
          answer:
              'Bilimdon AI — bu bolalar uchun maxsus yaratilgan sun\'iy '
              'intellekt yordamchisi.\n\n'
              'Imkoniyatlari:\n'
              '• Bolaning istalgan savoliga tushunarli javob beradi\n'
              '• Matematika, fan, tabiat haqida o\'rgatadi\n'
              '• Hikoyalar aytib beradi\n'
              '• Bolaning yoshiga mos tilda gaplashadi\n\n'
              'Xavfsizlik:\n'
              '• Noto\'g\'ri yoki zararli kontentga ruxsat bermaydi\n'
              '• Shaxsiy ma\'lumotlarni so\'ramaydi\n'
              '• Ota-ona chat tarixini ko\'ra oladi',
        ),
        _FaqItem(
          question: 'AI chat tarixi saqlanadimi?',
          answer:
              'Ha, Bilimdon AI bilan suhbat tarixi 30 kun saqlanadi.\n\n'
              '• Ota-ona istalgan vaqtda chat tarixini ko\'rishi mumkin\n'
              '• Chat tarixini tozalash mumkin\n'
              '• 30 kundan eski xabarlar avtomatik o\'chiriladi\n\n'
              'AI bolaning shaxsiy ma\'lumotlarini saqlamaydi va '
              'uchinchi tomonlarga bermaydi.',
        ),
      ],
    ),

    // ═══ 4. QURILMA ═══
    _FaqCategory(
      emoji: '📱',
      title: 'Qurilma',
      color: Color(0xFF22C55E),
      questions: [
        _FaqItem(
          question: 'Bola qurilmasini qanday ulash mumkin?',
          answer:
              'Qurilma ulash jarayoni:\n\n'
              '1️⃣ Ota-ona ilovasidan \"Qurilma qo\'shish\" tugmasini bosing\n'
              '2️⃣ Ekranda QR kod paydo bo\'ladi\n'
              '3️⃣ Bola qurilmasida Qadamcha ilovasini o\'rnating\n'
              '4️⃣ Bola ilovasida \"QR kod skanerlash\" tugmasini bosing\n'
              '5️⃣ QR kodni skanerlang — qurilma avtomatik ulanadi\n\n'
              '⚠️ Ikkala qurilma ham internetga ulangan bo\'lishi kerak.',
        ),
        _FaqItem(
          question: 'Nechta qurilma ulash mumkin?',
          answer:
              'Qurilmalar soni obuna rejangizga bog\'liq.\n\n'
              'Qurilmalar ro\'yxatini va limitini Sozlamalar > '
              'Qurilmalarni boshqarish bo\'limida ko\'rishingiz mumkin.\n\n'
              'Qo\'shimcha qurilma qo\'shish uchun obunangizni '
              'yuqori rejaga o\'tkazishingiz mumkin.',
        ),
        _FaqItem(
          question: 'Qurilma ulanmayapti, nima qilay?',
          answer:
              'Agar qurilma ulanmasa:\n\n'
              '1. ✅ Ikkala qurilmada internet borligini tekshiring\n'
              '2. ✅ QR kodni yangilab, qayta skanerlang\n'
              '3. ✅ Ilovani so\'nggi versiyaga yangilang\n'
              '4. ✅ Qurilmani qayta ishga tushiring\n'
              '5. ✅ VPN yoqilgan bo\'lsa, o\'chiring\n\n'
              'Qurilma ulashda muammo davom etsa, '
              'qurilmani ro\'yxatdan o\'chirib qayta ulang.\n\n'
              'Muammo hal bo\'lmasa — support@qadamcha.uz ga yozing.',
        ),
        _FaqItem(
          question: 'Qurilmani ro\'yxatdan o\'chirish mumkinmi?',
          answer:
              'Ha, istalgan vaqtda:\n\n'
              '1. Sozlamalar > Qurilmalarni boshqarish\n'
              '2. Kerakli qurilmani tanlang\n'
              '3. \"O\'chirish\" tugmasini bosing\n\n'
              'O\'chirilgan qurilma monitoring to\'xtatiladi. '
              'Qayta ulash uchun QR kodni skanerlash kerak bo\'ladi.',
        ),
      ],
    ),

    // ═══ 5. OBUNA VA TO'LOV ═══
    _FaqCategory(
      emoji: '👑',
      title: 'Obuna',
      color: Color(0xFFF59E0B),
      questions: [
        _FaqItem(
          question: 'Obuna turlari qanday?',
          answer:
              'Qadamcha quyidagi obuna turlarini taklif etadi:\n\n'
              'Oylik — 19 000 so\'m/oy\n'
              'Yillik — 179 000 so\'m/yil (oyiga 14 917 so\'m)\n\n'
              'Barcha rejalarda:\n'
              '• To\'liq monitoring\n'
              '• Bo\'yash o\'yini\n'
              '• Bilimdon AI chat\n'
              '• Ta\'limiy kontent (video va hikoyalar)\n'
              '• Qurilma boshqaruvi',
        ),
        _FaqItem(
          question: 'To\'lov qanday amalga oshiriladi?',
          answer:
              'To\'lov tizimlari:\n\n'
              'Payme — karta orqali\n'
              'Click — karta yoki Click hamyon orqali\n\n'
              'Xavfsizlik:\n'
              '• Karta ma\'lumotlari bizning serverlarimizda saqlanmaydi\n'
              '• To\'lov tizimlari tekshirilgan va litsenziyalangan',
        ),
        _FaqItem(
          question: 'Obunani qanday bekor qilaman?',
          answer:
              'Obunani bekor qilish:\n\n'
              '1. Sozlamalar sahifasiga o\'ting\n'
              '2. \"Obuna holati\" bo\'limini bosing\n'
              '3. \"Obunani bekor qilish\" tugmasini bosing\n'
              '4. Tasdiqlang\n\n'
              'Muhim:\n'
              '• Bekor qilingan obuna muddati tugaguncha faol qoladi\n'
              '• Qayta obuna bo\'lish istalgan vaqtda mumkin\n'
              '• Ma\'lumotlaringiz 30 kun saqlanadi',
        ),
        _FaqItem(
          question: 'Pulimni qaytarib olsam bo\'ladimi?',
          answer:
              'Qaytarish siyosati:\n\n'
              '• To\'lovdan 7 kun ichida — to\'liq qaytarish\n'
              '• 7 kundan keyin — qolgan muddat uchun proporsional\n\n'
              'Qaytarish so\'rovi uchun support@qadamcha.uz ga yozing '
              'yoki Telegram orqali murojaat qiling.\n\n'
              'So\'rov 3-5 ish kuni ichida ko\'rib chiqiladi.',
        ),
      ],
    ),

    // ═══ 6. XAVFSIZLIK ═══
    _FaqCategory(
      emoji: '🔒',
      title: 'Xavfsizlik',
      color: Color(0xFFEF4444),
      questions: [
        _FaqItem(
          question: 'Ma\'lumotlarim xavfsizmi?',
          answer:
              'Ha! Biz ko\'p bosqichli himoya tizimidan foydalanamiz:\n\n'
              'Texnik himoya:\n'
              '• HTTPS/TLS shifrlangan aloqa\n'
              '• Ma\'lumotlar bazasi shifrlash bilan himoyalangan\n'
              '• JWT token autentifikatsiya\n'
              '• QR-kod bilan xavfsiz qurilma ulash\n\n'
              'Ma\'lumot himoyasi:\n'
              '• Shaxsiy ma\'lumotlar uchinchi tomonlarga sotilmaydi\n'
              '• Bola ma\'lumotlari faqat ota-onaga ko\'rinadi',
        ),
        _FaqItem(
          question: 'PIN kodni unutdim, nima qilay?',
          answer:
              'PIN kodni tiklash juda oson:\n\n'
              '1️⃣ Kirish sahifasida \"PIN kodni unutdim\" tugmasini bosing\n'
              '2️⃣ Telefon raqamingizni kiriting\n'
              '3️⃣ SMS orqali tasdiqlash kodi keladi\n'
              '4️⃣ Kodni kiritib, yangi PIN yarating\n\n'
              '⚠️ SMS kelmasa:\n'
              '• 60 soniya kutib, qayta yuboring\n'
              '• Telefon raqamini to\'g\'ri kiritganingizni tekshiring\n'
              '• Tarmoq muammosi bo\'lsa, biroz kutib qaytadan urinib ko\'ring',
        ),
        _FaqItem(
          question: 'Hisobimni qanday o\'chirsam bo\'ladi?',
          answer:
              'Hisobni o\'chirish uchun:\n\n'
              '1. Sozlamalar sahifasiga o\'ting\n'
              '2. support@qadamcha.uz ga so\'rov yuboring\n'
              '3. So\'rov 3 ish kuni ichida ko\'rib chiqiladi\n\n'
              '⚠️ Ogohlantirish:\n'
              '• Hisob o\'chirilganda BARCHA ma\'lumotlar yo\'q qilinadi\n'
              '• Bog\'langan qurilmalar uziladi\n'
              '• Bo\'yash rasmlari o\'chiriladi\n'
              '• Bu jarayonni qaytarib bo\'lmaydi\n\n'
              'Ma\'lumotlar 30 kun ichida serverlardan butunlay tozalanadi.',
        ),
        _FaqItem(
          question: 'Boshqa birov bolam qurilmasini ko\'rishi mumkinmi?',
          answer:
              'Yo\'q! Bola ma\'lumotlari faqat BIRIKTIRILGAN ota-onaga '
              'ko\'rinadi.\n\n'
              'Himoya qatlamlari:\n'
              '• PIN kod bilan kirish\n'
              '• Telefon raqami + SMS tasdiqlash\n'
              '• Sessiya muddati tugaganda avtomatik chiqish\n'
              '• Bir paytda faqat bitta qurilmadan kirish\n\n'
              'Agar hisobingizga ruxsatsiz kirish shubhasi bo\'lsa, '
              'darhol PIN kodni o\'zgartiring va support ga xabar bering.',
        ),
      ],
    ),
  ];

  List<_FaqItem> get _filteredQuestions {
    final category = _categories[_selectedCategoryIndex];
    if (_searchQuery.isEmpty) return category.questions;
    final query = _searchQuery.toLowerCase();
    return category.questions
        .where((q) =>
            q.question.toLowerCase().contains(query) ||
            q.answer.toLowerCase().contains(query))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search bar
                    _buildSearchBar(),
                    SizedBox(height: 16.h),

                    // Categories
                    _buildCategoryChips(),
                    SizedBox(height: 16.h),

                    // FAQ list
                    ..._buildFaqList(),
                    SizedBox(height: 20.h),

                    // Contact section
                    _buildContactSection(),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 6.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16.sp,
                color: const Color(0xFF1A1A2E),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            'Yordam markazi ❓',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(
          fontSize: 14.sp,
          fontFamily: 'Nunito',
          color: const Color(0xFF1A1A2E),
        ),
        decoration: InputDecoration(
          hintText: 'Savolingizni qidiring...',
          hintStyle: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF9CA3AF),
            fontFamily: 'Nunito',
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: const Color(0xFF9CA3AF),
            size: 22.sp,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: Icon(
                    Icons.close_rounded,
                    color: const Color(0xFF9CA3AF),
                    size: 20.sp,
                  ),
                )
              : null,
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = index == _selectedCategoryIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? category.color.withValues(alpha: 0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected
                      ? category.color
                      : const Color(0xFFE5E7EB),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? category.color
                          : const Color(0xFF6B7280),
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFaqList() {
    final items = _filteredQuestions;
    if (items.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(32.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Column(
            children: [
              Text('🔍', style: TextStyle(fontSize: 40.sp)),
              SizedBox(height: 12.h),
              Text(
                'Natija topilmadi',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                  fontFamily: 'Nunito',
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Boshqa kalit so\'z bilan qidirib ko\'ring',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF9CA3AF),
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return items.map((item) {
      return Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              childrenPadding:
                  EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
              leading: Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: _categories[_selectedCategoryIndex]
                      .color
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.help_outline_rounded,
                  color: _categories[_selectedCategoryIndex].color,
                  size: 18.sp,
                ),
              ),
              title: Text(
                item.question,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                  fontFamily: 'Nunito',
                ),
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    item.answer,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFF4B5563),
                      fontFamily: 'Nunito',
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildContactSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D6A9F), Color(0xFF4A90D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A9F).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.headset_mic_rounded,
              color: Colors.white,
              size: 26.sp,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'Javob topa olmadingizmi?',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'Nunito',
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Biz bilan to\'g\'ridan-to\'g\'ri bog\'laning',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white.withValues(alpha: 0.85),
              fontFamily: 'Nunito',
            ),
          ),
          SizedBox(height: 18.h),

          // Telegram button
          _buildContactButton(
            icon: Icons.send_rounded,
            label: 'Telegram orqali yozish',
            color: const Color(0xFF29B6F6),
            onTap: () => _launchUrl('https://t.me/qadamcha_support'),
          ),
          SizedBox(height: 10.h),

          // Email button
          _buildContactButton(
            icon: Icons.email_outlined,
            label: 'Email yuborish',
            color: const Color(0xFFF59E0B),
            onTap: () => _launchUrl('mailto:support@qadamcha.uz'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(width: 10.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _FaqCategory {
  final String emoji;
  final String title;
  final Color color;
  final List<_FaqItem> questions;

  const _FaqCategory({
    required this.emoji,
    required this.title,
    required this.color,
    required this.questions,
  });
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}
