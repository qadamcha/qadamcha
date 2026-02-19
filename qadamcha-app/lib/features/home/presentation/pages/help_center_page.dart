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
    _FaqCategory(
      emoji: '📋',
      title: 'Umumiy',
      color: Color(0xFF2D6A9F),
      questions: [
        _FaqItem(
          question: 'Qadamcha nima?',
          answer:
              'Qadamcha — bu ota-onalar uchun bolalarning raqamli vaqtini '
              'boshqarish ilovasi. Ilova orqali siz farzandingizning '
              'qurilmada o\'tkazayotgan vaqtini kuzatishingiz, kontentni '
              'boshqarishingiz va foydali ta\'limiy materiallar taqdim '
              'etishingiz mumkin.',
        ),
        _FaqItem(
          question: 'Ilovadan qanday foydalanaman?',
          answer:
              '1. Telefon raqamingiz orqali ro\'yxatdan o\'ting\n'
              '2. PIN kod yarating\n'
              '3. Farzandingiz profilini qo\'shing\n'
              '4. QR kod orqali bola qurilmasini ulang\n'
              '5. Monitoring va kontent boshqaruvidan foydalaning',
        ),
        _FaqItem(
          question: 'Ilova qaysi qurilmalarda ishlaydi?',
          answer:
              'Qadamcha Android (5.0+) va iOS (13.0+) qurilmalarida '
              'ishlaydi. Ota-ona va bola qurilmalari turli platformalardan '
              'bo\'lishi mumkin.',
        ),
      ],
    ),
    _FaqCategory(
      emoji: '👑',
      title: 'Obuna',
      color: Color(0xFFF59E0B),
      questions: [
        _FaqItem(
          question: 'Obuna turlari qanday?',
          answer:
              'Qadamcha quyidagi obuna turlarini taklif etadi:\n\n'
              '• Oylik obuna — 1 oy muddatga\n'
              '• 3 oylik obuna — tejamkor variant\n'
              '• Yillik obuna — eng foydali narx\n\n'
              'Barcha obunalar bir xil funksiyalarni taqdim etadi.',
        ),
        _FaqItem(
          question: 'Obunani qanday bekor qilaman?',
          answer:
              'Obunani istalgan vaqtda Sozlamalar > Obuna holati bo\'limidan '
              'bekor qilishingiz mumkin. Bekor qilingan obuna muddati '
              'tugaguncha faol bo\'lib qoladi.',
        ),
        _FaqItem(
          question: 'To\'lov usullari qanday?',
          answer:
              'Hozirda Payme va Click to\'lov tizimlari orqali to\'lov '
              'qilish mumkin. Barcha to\'lovlar xavfsiz kanal orqali '
              'amalga oshiriladi.',
        ),
      ],
    ),
    _FaqCategory(
      emoji: '📱',
      title: 'Qurilma',
      color: Color(0xFF7C4DFF),
      questions: [
        _FaqItem(
          question: 'Bola qurilmasini qanday ulash mumkin?',
          answer:
              '1. Ota-ona ilovasidan "Qurilma qo\'shish" tugmasini bosing\n'
              '2. QR kod paydo bo\'ladi\n'
              '3. Bola qurilmasida Qadamcha ilovasini o\'rnating\n'
              '4. Bola ilovasidan QR kodni skanerlang\n'
              '5. Qurilma avtomatik ulanadi',
        ),
        _FaqItem(
          question: 'Nechta qurilma ulash mumkin?',
          answer:
              'Qurilmalar soni obuna rejangizga bog\'liq. Joriy '
              'limitingizni Sozlamalar > Qurilmalarni boshqarish '
              'bo\'limida ko\'rishingiz mumkin.',
        ),
        _FaqItem(
          question: 'Qurilma ulanmayapti, nima qilishim kerak?',
          answer:
              '• Ikkala qurilmada internet ulanishini tekshiring\n'
              '• QR kodni qayta yarating\n'
              '• Ilovani so\'nggi versiyaga yangilang\n'
              '• Qurilmani qayta ishga tushiring\n\n'
              'Muammo davom etsa, yordam xizmatiga murojaat qiling.',
        ),
      ],
    ),
    _FaqCategory(
      emoji: '🎬',
      title: 'Kontent',
      color: Color(0xFF22C55E),
      questions: [
        _FaqItem(
          question: 'Qanday kontentlar mavjud?',
          answer:
              'Qadamcha quyidagi turdagi kontentlarni taqdim etadi:\n\n'
              '• Ta\'limiy videolar — turli fanlar bo\'yicha\n'
              '• Interaktiv o\'yinlar — aqliy rivojlanish uchun\n'
              '• Audio ertaklar — eshitish uchun\n'
              '• Qo\'llanmalar — ota-onalar uchun foydali maslahatlar',
        ),
        _FaqItem(
          question: 'Kontent qanday tanlanadi?',
          answer:
              'Barcha kontentlar pedagog va psixologlar tomonidan '
              'tekshiriladi. Faqat bolalarga mos, ta\'limiy va xavfsiz '
              'kontentlar ilovaga joylashtiriladi.',
        ),
      ],
    ),
    _FaqCategory(
      emoji: '🔒',
      title: 'Xavfsizlik',
      color: Color(0xFFEF4444),
      questions: [
        _FaqItem(
          question: 'Ma\'lumotlarim xavfsizmi?',
          answer:
              'Ha, biz xalqaro xavfsizlik standartlaridan foydalanamiz:\n\n'
              '• TLS/HTTPS shifrlash\n'
              '• Xavfsiz token autentifikatsiya\n'
              '• PIN kod himoyasi\n'
              '• Ma\'lumotlar bazasi shifrlash',
        ),
        _FaqItem(
          question: 'PIN kodni unutdim, nima qilaman?',
          answer:
              'PIN kodni tiklash uchun:\n'
              '1. Kirish sahifasida "PIN kodni unutdim" tugmasini bosing\n'
              '2. Telefon raqamingizga SMS kod yuboriladi\n'
              '3. Kodni kiritib, yangi PIN yarating',
        ),
        _FaqItem(
          question: 'Hisobimni qanday o\'chirsam bo\'ladi?',
          answer:
              'Hisobni o\'chirish uchun Sozlamalar sahifasidan '
              'support@qadamcha.uz ga murojaat qiling. Hisobingiz va '
              'barcha ma\'lumotlaringiz 30 kun ichida butunlay o\'chiriladi.',
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
                  Text(category.emoji, style: TextStyle(fontSize: 14.sp)),
                  SizedBox(width: 6.w),
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
