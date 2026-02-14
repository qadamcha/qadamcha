import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../bloc/ai_chat_bloc.dart';
import '../bloc/ai_chat_event.dart';
import '../bloc/ai_chat_state.dart';

/// AI Maslahatchi sahifasi — real backend bilan ishlaydi
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AiChatBloc>().add(const CheckAiStatusEvent());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || text.length < 3) return;

    context.read<AiChatBloc>().add(SendMessageEvent(message: text));
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
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
            _buildHeader(),
            Expanded(
              child: BlocConsumer<AiChatBloc, AiChatState>(
                listener: (context, state) {
                  if (state.status == AiChatStatus.loaded ||
                      state.status == AiChatStatus.error) {
                    _scrollToBottom();
                  }
                },
                builder: (context, state) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
                    itemCount: state.messages.length +
                        (state.status == AiChatStatus.loading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length &&
                          state.status == AiChatStatus.loading) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(state.messages[index]);
                    },
                  );
                },
              ),
            ),

            // Tez savollar — faqat birinchi xabar bo'lganda
            BlocBuilder<AiChatBloc, AiChatState>(
              builder: (context, state) {
                if (state.messages.length > 1) return const SizedBox.shrink();
                return Column(
                  children: [
                    Container(
                      height: 46.h,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildSuggestionChip(
                            '📱 Ekran vaqti',
                            'Bolam uchun ekran vaqti qancha bo\'lishi kerak?',
                          ),
                          _buildSuggestionChip(
                            '😴 Uyqu rejimi',
                            'Bolam uchun to\'g\'ri uyqu rejimini qanday shakllantiraman?',
                          ),
                          _buildSuggestionChip(
                            '🧠 Rivojlanish',
                            'Bolamning aqliy rivojlanishini qanday rag\'batlantiraman?',
                          ),
                          _buildSuggestionChip(
                            '🥦 Ovqatlanish',
                            'Bolam sog\'lom ovqatlanishi uchun qanday maslahat berasiz?',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.h),
                  ],
                );
              },
            ),

            _buildInputArea(),
          ],
        ),
      ),
    );
  }

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
                BlocBuilder<AiChatBloc, AiChatState>(
                  builder: (context, state) {
                    return Text(
                      state.isAiOnline ? '✅ Online' : '⏳ Tekshirilmoqda...',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: state.isAiOnline
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEAB308),
                        fontFamily: 'Nunito',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Chat tozalash tugmasi
          GestureDetector(
            onTap: () {
              context.read<AiChatBloc>().add(const ClearChatEvent());
            },
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.refresh_rounded,
                size: 20.sp,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h, left: 60.w),
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
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
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75),
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
          BlocBuilder<AiChatBloc, AiChatState>(
            builder: (context, state) {
              final isLoading = state.status == AiChatStatus.loading;
              return GestureDetector(
                onTap: isLoading ? null : _sendMessage,
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLoading
                          ? [const Color(0xFF9CA3AF), const Color(0xFFBBBBBB)]
                          : [const Color(0xFF2D6A9F), const Color(0xFF4A90D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: isLoading
                      ? Padding(
                          padding: EdgeInsets.all(10.w),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String label, String message) {
    return GestureDetector(
      onTap: () {
        _controller.text = message;
        _sendMessage();
      },
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
          color:
              const Color(0xFF7C4DFF).withOpacity(0.3 + _animation.value * 0.7),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
