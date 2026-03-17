import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
                    _buildHeroCard(),
                    SizedBox(height: 16.h),
                    _buildLastUpdated(),
                    SizedBox(height: 16.h),
                    ..._buildPolicySections(),
                    SizedBox(height: 16.h),
                    _buildContactCard(),
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
            'Maxfiylik siyosati 🛡️',
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

  Widget _buildHeroCard() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 26.sp,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'Farzandlaringiz xavfsizligi\nbizning ustuvorligimiz',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'Nunito',
              height: 1.3,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Qadamcha ilovasi bolalaringizning raqamli hayotini himoya qilish '
            'uchun yaratilgan. Barcha ma\'lumotlar xavfsizlik '
            'standartlariga muvofiq ishlanadi.',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white.withValues(alpha: 0.85),
              fontFamily: 'Nunito',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFF2D6A9F).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Icon(Icons.update_rounded,
              size: 16.sp, color: const Color(0xFF2D6A9F)),
          SizedBox(width: 8.w),
          Text(
            'Oxirgi yangilanish: 2026-yil, 8-mart',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF2D6A9F),
              fontWeight: FontWeight.w600,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPolicySections() {
    final sections = <_PolicySection>[
      // ═══ 1. ILOVA HAQIDA ═══
      _PolicySection(
        icon: Icons.info_outline_rounded,
        color: const Color(0xFF2D6A9F),
        title: '1. Ilova haqida',
        content:
            'Qadamcha — bu ota-onalar uchun mo\'ljallangan bolalar nazorati '
            'va ta\'lim ilovasi. Ilova quyidagi asosiy funksiyalarni taqdim etadi:\n\n'
            '• Bola qurilmasini masofadan boshqarish va monitoring\n'
            '• Bo\'yash o\'yini — bolalar uchun ijodiy mashq\n'
            '• Bilimdon AI — sun\'iy intellekt yordamchisi (bolalar uchun)\n'
            '• Ta\'limiy kontent — video darslar va hikoyalar\n'
            '• Ekran vaqtini cheklash va boshqarish\n'
            '• Bola faoliyati haqida ota-onaga bildirishnomalar\n\n'
            'Ushbu maxfiylik siyosati ilovamiz orqali qanday ma\'lumotlar '
            'yig\'ilishi, qanday maqsadda ishlatilishi va qanday himoya '
            'qilinishini batafsil tushuntiradi.',
      ),

      // ═══ 2. YIG'ILADIGAN MA'LUMOTLAR ═══
      _PolicySection(
        icon: Icons.data_usage_rounded,
        color: const Color(0xFF7C4DFF),
        title: '2. Yig\'iladigan ma\'lumotlar',
        content:
            'Qadamcha quyidagi ma\'lumotlarni yig\'adi:\n\n'
            'Shaxsiy ma\'lumotlar:\n'
            '• Telefon raqami — ro\'yxatdan o\'tish va SMS tasdiqlash uchun\n'
            '• Ota-ona ismi — profil yaratish uchun\n'
            '• Bola ismi, tug\'ilgan yili — profil va yoshga mos kontent uchun\n\n'
            'Qurilma ma\'lumotlari:\n'
            '• Qurilma modeli va operatsion tizim versiyasi\n'
            '• Unikal qurilma ID — qurilmani bog\'lash uchun\n'
            '• O\'rnatilgan ilovalar ro\'yxati (faqat bola qurilmasida)\n\n'
            'Foydalanish ma\'lumotlari:\n'
            '• Ekran vaqti statistikasi (bola qurilmasida)\n'
            '• Ilova foydalanish davomiyligi\n'
            '• Bo\'yash o\'yini natijalari (saqlangan rasmlar)\n\n'
            'AI Chat ma\'lumotlari:\n'
            '• Bilimdon AI bilan suhbat matni (bolaga mos javob berish uchun)\n'
            '• Chat tarixi ma\'lum muddat saqlanadi\n\n'
            'Biz yig\'MAYDIGAN ma\'lumotlar:\n'
            '• Kredit karta raqamlari (to\'lovlar Payme/Click orqali amalga oshiriladi)\n'
            '• Bola geojoylashuvi (GPS)\n'
            '• Kamera yoki mikrofon yozuvlari\n'
            '• Bola shaxsiy xabarlari yoki qo\'ng\'iroqlari',
      ),

      // ═══ 3. BOLALAR MAXFIYLIGI ═══
      _PolicySection(
        icon: Icons.child_care_rounded,
        color: const Color(0xFFFF6D00),
        title: '3. Bolalar maxfiyligini himoya qilish',
        content:
            'Qadamcha bolalar ma\'lumotlariga alohida e\'tibor qaratadi:\n\n'
            'Asosiy tamoyillar:\n'
            '• Bola ma\'lumotlari FAQAT bog\'langan ota-onaga ko\'rinadi\n'
            '• Bola profili hech qanday uchinchi tomonga berilmaydi\n'
            '• Bola AI chat tarixi ota-ona tomonidan ko\'rib chiqilishi mumkin\n'
            '• Bolalar uchun reklama ko\'rsatilmaydi va targetlanmaydi\n'
            '• Bo\'yash o\'yinidagi saqlangan rasmlar faqat mahalliy qurilmada saqlanadi\n\n'
            'Standartlar:\n'
            '• O\'zbekiston Respublikasi «Shaxsiy ma\'lumotlar to\'g\'risida»gi qonuni\n'
            '• Bolalar maxfiyligini himoya qilish tamoyillari\n\n'
            'Ota-ona nazorati:\n'
            '• Faqat ota-ona PIN-kod yoki parol orqali sozlamalarni o\'zgartira oladi\n'
            '• Bola ilovaning monitoring sozlamalarini o\'zgartira olmaydi\n'
            '• AI chat filtrlangan — noto\'g\'ri kontentga ruxsat berilmaydi',
      ),

      // ═══ 4. XAVFSIZLIK ═══
      _PolicySection(
        icon: Icons.lock_rounded,
        color: const Color(0xFF22C55E),
        title: '4. Ma\'lumotlar xavfsizligi',
        content:
            'Biz xavfsizlik tizimidan foydalanamiz:\n\n'
            'Shifrlash:\n'
            '• HTTPS/TLS orqali barcha aloqa shifrlangan\n'
            '• Ma\'lumotlar bazasi shifrlash bilan himoyalangan\n'
            '• JWT tokenlar asosidagi autentifikatsiya\n\n'
            'Kirish nazorati:\n'
            '• Ota-ona PIN-kodi orqali ilova himoyasi\n'
            '• QR-kod bilan qurilma ulash — xavfsiz pairing\n'
            '• Sessiya muddati tugaganda avtomatik chiqish\n'
            '• Bir paytda faqat bitta qurilmadan kirish imkoniyati\n\n'
            'Server himoyasi:\n'
            '• Serverlar xavfsiz bulutli infratuzilmada joylashgan\n'
            '• Ma\'lumotlar zaxira nusxalari avtomatik olinadi',
      ),

      // ═══ 5. MA'LUMOT ULASHISH ═══
      _PolicySection(
        icon: Icons.share_rounded,
        color: const Color(0xFFF59E0B),
        title: '5. Ma\'lumotlarni ulashish',
        content:
            'Biz shaxsiy ma\'lumotlaringizni SOTMAYMIZ va reklama maqsadida '
            'ULASHMAYMIZ.\n\n'
            'Ma\'lumotlar faqat quyidagi holatlarda uchinchi tomonlarga '
            'berilishi mumkin:\n\n'
            '• Qonun talab qilganda (sud qarori yoki huquqni muhofaza qilish '
            'organlari so\'rovi)\n'
            '• To\'lov provayderlari (Payme, Click) — faqat tranzaksiya uchun '
            'zarur minimal ma\'lumot\n'
            '• AI xizmatlari — Bilimdon AI javoblarini generatsiya qilish uchun '
            '(anonim, shaxsiy ma\'lumotlarsiz)\n'
            '• Firebase — push bildirishnomalar yuborish uchun\n'
            '• Anonimizatsiya qilingan umumiy statistika — ilovani '
            'yaxshilash maqsadida\n\n'
            'Uchinchi tomon xizmatlariga shaxsiy ma\'lumotlar emas, '
            'faqat texnik identifikatorlar uzatiladi.',
      ),

      // ═══ 6. FOYDALANUVCHI HUQUQLARI ═══
      _PolicySection(
        icon: Icons.manage_accounts_rounded,
        color: const Color(0xFFEF4444),
        title: '6. Foydalanuvchi huquqlari',
        content:
            'Siz quyidagi huquqlarga to\'liq egasiz:\n\n'
            'Ma\'lumotlarni boshqarish:\n'
            '• Profil ma\'lumotlarini istalgan vaqtda ko\'rish va tahrirlash\n'
            '• Bola profilini qo\'shish, o\'zgartirish yoki o\'chirish\n'
            '• AI chat tarixini tozalash\n'
            '• Saqlangan bo\'yash rasmlarini o\'chirish\n\n'
            'Hisobni o\'chirish:\n'
            '• Hisobingizni istalgan vaqtda to\'liq o\'chirish huquqi\n'
            '• O\'chirish so\'rovidan so\'ng 30 kun ichida barcha ma\'lumotlar '
            'serverlardan butunlay yo\'q qilinadi\n'
            '• Mahalliy qurilmadagi ma\'lumotlar darhol o\'chiriladi\n\n'
            'Boshqarish:\n'
            '• Bildirishnomalarni istalgan vaqtda o\'chirish\n'
            '• Obunani bekor qilish\n'
            '• Ma\'lumot yig\'ilishiga rozilikni qaytarib olish\n\n'
            'Barcha so\'rovlar 15 ish kuni ichida ko\'rib chiqiladi.',
      ),

      // ═══ 7. MA'LUMOT SAQLASH ═══
      _PolicySection(
        icon: Icons.storage_rounded,
        color: const Color(0xFF6B7280),
        title: '7. Ma\'lumotlarni saqlash muddatlari',
        content:
            'Saqlash muddatlari:\n'
            '• Hisob ma\'lumotlari — obuna davomida\n'
            '• Monitoring statistikasi — oxirgi 90 kun\n'
            '• AI chat tarixi — oxirgi 30 kun\n'
            '• Bo\'yash o\'yini rasmlari — foydalanuvchi o\'chirishiga qadar '
            '(faqat mahalliy qurilmada)\n'
            '• To\'lov tarixi — qonun talabiga ko\'ra 3 yil\n\n'
            'Avtomatik tozalash:\n'
            '• Hisob o\'chirilganda — 30 kun ichida to\'liq tozalash\n\n'
            'Mahalliy saqlash:\n'
            '• Bo\'yash rasmlari faqat qurilmada saqlanadi\n'
            '• Kontent (video/hikoya) offline rejim uchun keshlanadi\n'
            '• Kesh ilovani o\'chirganda tozalanadi',
      ),

      // ═══ 8. OBUNA VA TO'LOVLAR ═══
      _PolicySection(
        icon: Icons.payment_rounded,
        color: const Color(0xFF0891B2),
        title: '8. Obuna va to\'lovlar',
        content:
            'To\'lov xavfsizligi:\n'
            '• To\'lovlar Payme va Click orqali amalga oshiriladi\n'
            '• Kredit/debet karta raqamlari bizning serverlarimizda '
            'SAQLANMAYDI\n\n'
            'Obuna shartlari:\n'
            '• Obuna har oyda avtomatik yangilanadi\n'
            '• Bekor qilish istalgan vaqtda mumkin\n'
            '• Bekor qilinganda joriy davr oxirigacha xizmat davom etadi\n'
            '• Qaytarish siyosati — to\'lovdan 7 kun ichida',
      ),

      // ═══ 9. O'ZGARISHLAR ═══
      _PolicySection(
        icon: Icons.gavel_rounded,
        color: const Color(0xFF2D6A9F),
        title: '9. Siyosatga o\'zgarishlar kiritish',
        content:
            'Ushbu maxfiylik siyosatiga vaqti-vaqti bilan o\'zgarishlar kiritilishi '
            'mumkin.\n\n'
            'Xabardor qilish:\n'
            '• Muhim o\'zgarishlar haqida ilova ichida bildirishnoma yuboriladi\n'
            '• Kichik tuzatishlar ilova yangilanishi bilan kuchga kiradi\n'
            '• O\'zgarishlar tarixi shu sahifada ko\'rsatiladi\n\n'
            'Ilovadan foydalanishni davom ettirish orqali siz yangilangan '
            'siyosatni qabul qilgan hisoblanasiz.\n\n'
            'Amaldagi versiya: 1.0 (2026-yil, 8-mart)',
      ),

      // ═══ 10. HUQUQIY ASOS ═══
      _PolicySection(
        icon: Icons.balance_rounded,
        color: const Color(0xFF8B5CF6),
        title: '10. Huquqiy asos',
        content:
            'Qadamcha ilovasi quyidagi qonunchilik asosida faoliyat yuritadi:\n\n'
            'O\'zbekiston:\n'
            '• «Shaxsiy ma\'lumotlar to\'g\'risida»gi qonun (2019)\n'
            '• «Axborotlashtirish to\'g\'risida»gi qonun\n'
            '• «Bolalar huquqlarining kafolatlari to\'g\'risida»gi qonun',
      ),
    ];

    return sections
        .map((s) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _buildSectionCard(s),
            ))
        .toList();
  }

  Widget _buildSectionCard(_PolicySection section) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: section.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(section.icon, color: section.color, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A2E),
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            section.content,
            style: TextStyle(
              fontSize: 13.sp,
              color: const Color(0xFF4B5563),
              fontFamily: 'Nunito',
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: const Color(0xFF2D6A9F).withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.mail_outline_rounded,
            color: const Color(0xFF2D6A9F),
            size: 28.sp,
          ),
          SizedBox(height: 10.h),
          Text(
            'Savollaringiz bormi?',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
              fontFamily: 'Nunito',
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Maxfiylik yoki ma\'lumotlar himoyasi\nbo\'yicha har qanday savol uchun bog\'laning',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF6B7280),
              fontFamily: 'Nunito',
              height: 1.5,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFF2D6A9F).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              'support@qadamcha.uz',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D6A9F),
                fontFamily: 'Nunito',
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Toshkent shahri, O\'zbekiston',
            style: TextStyle(
              fontSize: 11.sp,
              color: const Color(0xFF9CA3AF),
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection {
  final IconData icon;
  final Color color;
  final String title;
  final String content;

  const _PolicySection({
    required this.icon,
    required this.color,
    required this.title,
    required this.content,
  });
}
