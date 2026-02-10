import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: 'Salom! Men Qadamcha AI yordamchisiman. 👋\n\nBolangizning ta\'limi va rivojlanishi haqida savollaringizga javob berishga tayyorman.',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];
  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(_ChatMessage(
            text: _getAiResponse(text),
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    });
  }

  String _getAiResponse(String query) {
    // Placeholder responses - will be replaced with actual Gemini API
    final queries = query.toLowerCase();
    
    if (queries.contains('ekran') || queries.contains('vaqt')) {
      return '📱 Ekran vaqti haqida:\n\n'
          '• 2-5 yoshdagi bolalar uchun: kuniga 1 soatgacha\n'
          '• 6-12 yosh: kuniga 2 soatgacha\n'
          '• O\'rtacha qoida: har 30 daqiqada tanaffus\n\n'
          'Ta\'limiy kontentga ustuvor e\'tibor bering!';
    }
    
    if (queries.contains('multfilm') || queries.contains('kontent')) {
      return '🎬 Yosh bo\'yicha kontent:\n\n'
          '• 0-3 yosh: Ranglar, shakllar, hayvonlar\n'
          '• 3-6 yosh: Qisqa hikoyalar, qo\'shiqlar\n'
          '• 6+ yosh: Ta\'limiy seriallar, ilmiy kontentlar\n\n'
          'Qadamcha barcha kontentni yosh guruhiga moslab taklif qiladi!';
    }
    
    return '🤔 Yaxshi savol!\n\n'
        'Bu haqida batafsil ma\'lumot berish uchun yanada aniqroq savol berishingiz mumkin. '
        'Masalan:\n\n'
        '• Ekran vaqti qancha bo\'lishi kerak?\n'
        '• Qanday multfilmlar foydali?\n'
        '• Bolam qanday rivojlanmoqda?';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Text('🤖', style: TextStyle(fontSize: 20.sp)),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Yordamchi'),
                Text(
                  'Har doim onlayn',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.normal,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16.w),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _TypingIndicator();
                }
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),
          
          // Quick Suggestions
          if (_messages.length == 1)
            Container(
              height: 50.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _SuggestionChip(
                    label: 'Ekran vaqti',
                    onTap: () {
                      _controller.text = 'Bolam uchun ekran vaqti qancha bo\'lishi kerak?';
                      _sendMessage();
                    },
                  ),
                  _SuggestionChip(
                    label: 'Foydali multfilmlar',
                    onTap: () {
                      _controller.text = 'Qaysi multfilmlar bolam uchun foydali?';
                      _sendMessage();
                    },
                  ),
                  _SuggestionChip(
                    label: 'Rivojlanish',
                    onTap: () {
                      _controller.text = 'Bolam qanday rivojlanmoqda?';
                      _sendMessage();
                    },
                  ),
                ],
              ),
            ),
          
          // Input
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Savolingizni yozing...',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 22.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12.h,
          left: message.isUser ? 60.w : 0,
          right: message.isUser ? 0 : 60.w,
        ),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: message.isUser ? AppColors.primaryGradient : null,
          color: message.isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: Radius.circular(message.isUser ? 16.r : 4.r),
            bottomRight: Radius.circular(message.isUser ? 4.r : 16.r),
          ),
          boxShadow: [
            if (!message.isUser)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 15.sp,
            color: message.isUser ? Colors.white : AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h, right: 100.w),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(delay: 0),
            SizedBox(width: 4.w),
            _Dot(delay: 150),
            SizedBox(width: 4.w),
            _Dot(delay: 300),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;

  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: 8.w,
        height: 8.w,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.3 + _animation.value * 0.7),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
