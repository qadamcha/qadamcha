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
            // Header
            _buildHeader(context),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero card
                    _buildHeroCard(),
                    SizedBox(height: 16.h),

                    // Last updated
                    _buildLastUpdated(),
                    SizedBox(height: 16.h),

                    // Sections
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
            'Sizning maxfiyligingiz\nbizning ustuvorligimiz',
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
            'Qadamcha farzandlaringiz va oilangiz ma\'lumotlarini '
            'xalqaro standartlarga muvofiq himoya qiladi.',
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
            'Oxirgi yangilanish: 2026-yil, 15-fevral',
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
      _PolicySection(
        icon: Icons.info_outline_rounded,
        color: const Color(0xFF2D6A9F),
        title: '1. Umumiy ma\'lumot',
        content:
            'Qadamcha — bu ota-onalar uchun bolalarning raqamli vaqtini '
            'boshqarish ilovasi. Biz foydalanuvchilarimizning shaxsiy '
            'ma\'lumotlarini himoya qilishga alohida e\'tibor qaratamiz.\n\n'
            'Ushbu siyosat ilovamiz orqali qanday ma\'lumotlar '
            'yig\'ilishi, ular qanday ishlatilishi va qanday himoya '
            'qilinishini tushuntiradi.',
      ),
      _PolicySection(
        icon: Icons.data_usage_rounded,
        color: const Color(0xFF7C4DFF),
        title: '2. Yig\'iladigan ma\'lumotlar',
        content:
            '• Telefon raqami — ro\'yxatdan o\'tish va autentifikatsiya uchun\n'
            '• Ota-ona va bola ismlari — profil yaratish uchun\n'
            '• Qurilma ma\'lumotlari — qurilmani ulash va boshqarish uchun\n'
            '• Foydalanish statistikasi — ilovani yaxshilash uchun\n'
            '• Monitoring ma\'lumotlari — bola faoliyatini kuzatish uchun\n\n'
            'Biz kredit karta ma\'lumotlarini o\'z serverlarimizda saqlamaymiz. '
            'To\'lovlar xavfsiz to\'lov tizimlari orqali amalga oshiriladi.',
      ),
      _PolicySection(
        icon: Icons.child_care_rounded,
        color: const Color(0xFFFF6D00),
        title: '3. Bolalar maxfiyligini himoya qilish',
        content:
            'Qadamcha bolalar ma\'lumotlarini maxsus himoya qiladi:\n\n'
            '• Bolalar haqidagi ma\'lumotlar faqat ota-onaga ko\'rinadi\n'
            '• Bola profili uchinchi tomonlarga taqdim etilmaydi\n'
            '• Monitoring ma\'lumotlari shifrlangan holda saqlanadi\n'
            '• Bolalar reklama maqsadida targtetlanmaydi\n'
            '• Ma\'lumotlar COPPA (Children\'s Online Privacy Protection Act) '
            'talablariga muvofiq boshqariladi',
      ),
      _PolicySection(
        icon: Icons.lock_rounded,
        color: const Color(0xFF22C55E),
        title: '4. Ma\'lumotlar xavfsizligi',
        content:
            '• HTTPS/TLS orqali shifrlangan aloqa\n'
            '• PIN-kod orqali ilova himoyasi\n'
            '• JWT token asosidagi autentifikatsiya\n'
            '• Ma\'lumotlar bazasi shifrlash bilan himoyalangan\n'
            '• Muntazam xavfsizlik tekshiruvlari o\'tkaziladi\n'
            '• Qurilma biriktirilishida QR-kod himoyasi',
      ),
      _PolicySection(
        icon: Icons.share_rounded,
        color: const Color(0xFFF59E0B),
        title: '5. Ma\'lumotlarni ulashish',
        content:
            'Biz shaxsiy ma\'lumotlaringizni uchinchi tomonlarga '
            'sotmaymiz yoki almashinmaymiz.\n\n'
            'Ma\'lumotlar faqat quyidagi holatlarda ulashilishi mumkin:\n'
            '• Qonuniy talab bo\'lganda\n'
            '• To\'lov provayderlari bilan (faqat to\'lov amalga oshirish uchun)\n'
            '• Sizning aniq roziliginiz bo\'lganda',
      ),
      _PolicySection(
        icon: Icons.manage_accounts_rounded,
        color: const Color(0xFFEF4444),
        title: '6. Foydalanuvchi huquqlari',
        content:
            'Siz quyidagi huquqlarga egasiz:\n\n'
            '• Ma\'lumotlaringizni ko\'rish va yuklab olish\n'
            '• Profil ma\'lumotlarini o\'zgartirish\n'
            '• Hisobni o\'chirish va barcha ma\'lumotlarni yo\'q qilish\n'
            '• Bildirishnomalarni o\'chirish\n'
            '• Ma\'lumotlar yig\'ilishiga rozilikni qaytarib olish\n\n'
            'Barcha so\'rovlar 30 kun ichida ko\'rib chiqiladi.',
      ),
      _PolicySection(
        icon: Icons.storage_rounded,
        color: const Color(0xFF6B7280),
        title: '7. Ma\'lumotlarni saqlash',
        content:
            '• Faol foydalanuvchi ma\'lumotlari obuna davomida saqlanadi\n'
            '• Hisob o\'chirilganda ma\'lumotlar 30 kun ichida yo\'q qilinadi\n'
            '• Monitoring tarixi 90 kun saqlanadi\n'
            '• Anonimizatsiya qilingan statistika ilmiy maqsadlarda '
            'saqlanishi mumkin',
      ),
      _PolicySection(
        icon: Icons.gavel_rounded,
        color: const Color(0xFF2D6A9F),
        title: '8. O\'zgarishlar kiritish',
        content:
            'Ushbu maxfiylik siyosatiga o\'zgarishlar kiritilishi mumkin. '
            'Muhim o\'zgarishlar haqida ilova orqali xabar beramiz.\n\n'
            'Ilovadan foydalanishni davom ettirish orqali siz '
            'yangilangan siyosatga rozilik bildirasiz.',
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
            'Savollar bormi?',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
              fontFamily: 'Nunito',
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Maxfiylik bo\'yicha savollaringiz bo\'lsa,\nbiz bilan bog\'laning',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF6B7280),
              fontFamily: 'Nunito',
              height: 1.5,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'support@qadamcha.uz',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2D6A9F),
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
