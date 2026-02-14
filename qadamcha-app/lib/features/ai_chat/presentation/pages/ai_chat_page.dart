import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

/// AI Maslahatchi sahifasi — full_architecture.html dizaynida
/// Chat interfeysi: header + xabarlar + input
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
      text: 'Assalomu alaykum! Qanday savol bor? 😊',
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
    final queries = query.toLowerCase();

    if (queries.contains('ekran') || queries.contains('vaqt') || queries.contains('telefon')) {
      return 'Yaxshi savol!\n\n⏰ Kuniga 1 soat limit\n✅ Foydali kontent\n🏃 Sport bilan almashtiring';
    }

    if (queries.contains('multfilm') || queries.contains('kontent')) {
      return '🎬 Yosh bo\'yicha kontent:\n\n• 0-3 yosh: Ranglar, shakllar\n• 3-6 yosh: Qisqa hikoyalar\n• 6+ yosh: Ta\'limiy seriallar';
    }

    return '🤔 Yaxshi savol!\n\nBu haqida batafsil ma\'lumot berish uchun savol berishingiz mumkin:\n\n• Ekran vaqti qancha bo\'lishi kerak?\n• Qanday multfilmlar foydali?\n• Bolam qanday rivojlanmoqda?';
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom header matching HTML design
            _buildHeader(),

            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16.w),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),

            // Quick Suggestions
            if (_messages.length == 1)
              Container(
                height: 46.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildSuggestionChip(
                      '📱 Ekran vaqti',
                      () {
                        _controller.text = 'Bolam uchun ekran vaqti qancha bo\'lishi kerak?';
                        _sendMessage();
                      },
                    ),
                    _buildSuggestionChip(
                      '🎬 Multfilmlar',
                      () {
                        _controller.text = 'Qaysi multfilmlar bolam uchun foydali?';
                        _sendMessage();
                      },
                    ),
                    _buildSuggestionChip(
                      '📊 Rivojlanish',
                      () {
                        _controller.text = 'Bolam qanday rivojlanmoqda?';
                        _sendMessage();
                      },
                    ),
                  ],
                ),
              ),

            if (_messages.length == 1)
              SizedBox(height: 8.h),

            // Input area — matching HTML design
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  /// Header: white bg, border-bottom, back button, robot avatar, title + status
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Robot avatar — purple gradient
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Center(
              child: Text('🤖', style: TextStyle(fontSize: 20.sp)),
            ),
          ),
          SizedBox(width: 10.w),
          // Title and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Maslahatchi',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                    fontFamily: 'Nunito',
                  ),
                ),
                Text(
                  '✅ Online',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF22C55E),
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Message bubble with avatar circle for bot messages
  Widget _buildMessageBubble(_ChatMessage message) {
    if (message.isUser) {
      // User message — right aligned, blue gradient
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h, left: 60.w),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D6A9F), Color(0xFF4A90D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: Radius.circular(16.r),
              bottomRight: Radius.circular(4.r),
            ),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white,
              height: 1.5,
              fontFamily: 'Nunito',
            ),
          ),
        ),
      );
    }

    // Bot message — left aligned with small avatar
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Small bot avatar
          Container(
            width: 26.w,
            height: 26.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9.r),
            ),
            child: Center(
              child: Text('🤖', style: TextStyle(fontSize: 12.sp)),
            ),
          ),
          SizedBox(width: 6.w),
          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomLeft: Radius.circular(4.r),
                  bottomRight: Radius.circular(16.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF1A1A2E),
                  height: 1.6,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Typing indicator with bot avatar
  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 26.w,
            height: 26.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9.r),
            ),
            child: Center(
              child: Text('🤖', style: TextStyle(fontSize: 12.sp)),
            ),
          ),
          SizedBox(width: 6.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
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
        ],
      ),
    );
  }

  /// Input area: white bg, border-top, gray pill input, blue gradient send button
  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 18.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: TextField(
                controller: _controller,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: const Color(0xFF1A1A2E),
                  fontFamily: 'Nunito',
                ),
                decoration: InputDecoration(
                  filled: false,
                  fillColor: Colors.transparent,
                  hintText: 'Savol yozing...',
                  hintStyle: TextStyle(
                    fontSize: 15.sp,
                    color: const Color(0xFF9CA3AF),
                    fontFamily: 'Nunito',
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // Send button — blue gradient rounded square
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D6A9F), Color(0xFF4A90D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D6A9F),
            fontFamily: 'Nunito',
          ),
        ),
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
          color: const Color(0xFF7C4DFF).withOpacity(0.3 + _animation.value * 0.7),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
