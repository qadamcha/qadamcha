import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../bloc/ai_chat_bloc.dart';
import '../bloc/ai_chat_event.dart';
import '../bloc/ai_chat_state.dart';

/// AI Chat sahifasi — session-based, context bilan
/// Pro-level markdown rendering + premium dizayn
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Nusxalandi ✓',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        duration: const Duration(seconds: 2),
      ),
    );
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
                  if (state.messages.isEmpty) {
                    return _buildWelcomeView();
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    itemCount: state.messages.length +
                        (state.status == AiChatStatus.loading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length &&
                          state.status == AiChatStatus.loading) {
                        return _buildTypingIndicator();
                      }
                      final msg = state.messages[index];
                      if (msg.isError) {
                        return _buildErrorBubble(msg, state.canRetry);
                      }
                      return _buildMessageBubble(msg);
                    },
                  );
                },
              ),
            ),

            // Tez savollar — faqat kam xabar bo'lganda
            BlocBuilder<AiChatBloc, AiChatState>(
              builder: (context, state) {
                if (state.messages.length > 2) return const SizedBox.shrink();
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
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              context.read<AiChatBloc>().add(const LoadAllChatsEvent());
              Navigator.pop(context);
            },
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16.sp,
                color: const Color(0xFF374151),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: Text('🤖', style: TextStyle(fontSize: 18.sp)),
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
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                    fontFamily: 'Nunito',
                  ),
                ),
                BlocBuilder<AiChatBloc, AiChatState>(
                  builder: (context, state) {
                    return Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.w,
                          decoration: BoxDecoration(
                            color: state.isAiOnline
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFEAB308),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          state.isAiOnline ? 'Online' : 'Tekshirilmoqda...',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: state.isAiOnline
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFEAB308),
                            fontFamily: 'Nunito',
                          ),
                        ),
                        if (state.totalTokens > 0) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 1.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              '${(state.totalTokens / 1000).toStringAsFixed(0)}K',
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF9CA3AF),
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          // Yangi chat tugmasi
          GestureDetector(
            onTap: () {
              context.read<AiChatBloc>().add(const CreateNewChatEvent());
            },
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.edit_note_rounded,
                size: 20.sp,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text('🤖', style: TextStyle(fontSize: 40.sp)),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Qanday yordam bera olaman?',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
                fontFamily: 'Nunito',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Farzand tarbiyasi bo\'yicha savolingizni yozing',
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF6B7280),
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============= MESSAGE BUBBLE =============

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.isUser) {
      return _buildUserBubble(message);
    }
    return _buildAiBubble(message);
  }

  /// Error xabar bubble — "Qayta urinish" tugmasi bilan
  Widget _buildErrorBubble(ChatMessage message, bool canRetry) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30.w,
            height: 30.w,
            margin: EdgeInsets.only(top: 2.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: Text('⚠', style: TextStyle(fontSize: 14.sp)),
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4.r),
                      topRight: Radius.circular(18.r),
                      bottomLeft: Radius.circular(18.r),
                      bottomRight: Radius.circular(18.r),
                    ),
                    border: Border.all(
                      color: const Color(0xFFFECACA),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF991B1B),
                      height: 1.5,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
                if (canRetry)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: GestureDetector(
                      onTap: () {
                        context.read<AiChatBloc>().add(
                          const RetryLastMessageEvent(),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 7.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D6A9F),
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2D6A9F).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: 16.sp,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              'Qayta urinish',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// User xabar bubble — gradient fon
  Widget _buildUserBubble(ChatMessage message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h, left: 48.w),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D6A9F), Color(0xFF4A90D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.r),
            topRight: Radius.circular(18.r),
            bottomLeft: Radius.circular(18.r),
            bottomRight: Radius.circular(4.r),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D6A9F).withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
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

  /// AI xabar bubble — Markdown rendering + copy tugmasi
  Widget _buildAiBubble(ChatMessage message) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Avatar
          Container(
            width: 30.w,
            height: 30.w,
            margin: EdgeInsets.only(top: 2.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text('🤖', style: TextStyle(fontSize: 14.sp)),
            ),
          ),
          SizedBox(width: 8.w),

          // Xabar bubble
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4.r),
                      topRight: Radius.circular(18.r),
                      bottomLeft: Radius.circular(18.r),
                      bottomRight: Radius.circular(18.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(0, 0, 0, 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: MarkdownBody(
                    data: message.text,
                    selectable: true,
                    shrinkWrap: true,
                    softLineBreak: true,
                    styleSheet: _markdownStyleSheet(),
                  ),
                ),
                // Copy tugmasi
                Padding(
                  padding: EdgeInsets.only(top: 4.h, left: 4.w),
                  child: GestureDetector(
                    onTap: () => _copyMessage(message.text),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          size: 13.sp,
                          color: const Color(0xFF9CA3AF),
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          'Nusxalash',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFF9CA3AF),
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Markdown uchun professional style sheet
  MarkdownStyleSheet _markdownStyleSheet() {
    return MarkdownStyleSheet(
      // Asosiy matn
      p: TextStyle(
        fontSize: 14.sp,
        color: const Color(0xFF1F2937),
        height: 1.6,
        fontFamily: 'Nunito',
      ),

      // Bold
      strong: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF111827),
        fontFamily: 'Nunito',
      ),

      // Italic
      em: TextStyle(
        fontSize: 14.sp,
        fontStyle: FontStyle.italic,
        color: const Color(0xFF374151),
        fontFamily: 'Nunito',
      ),

      // Sarlavhalar
      h1: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF111827),
        fontFamily: 'Nunito',
        height: 1.4,
      ),
      h2: TextStyle(
        fontSize: 17.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1F2937),
        fontFamily: 'Nunito',
        height: 1.4,
      ),
      h3: TextStyle(
        fontSize: 15.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF374151),
        fontFamily: 'Nunito',
        height: 1.4,
      ),

      // Ro'yxatlar
      listBullet: TextStyle(
        fontSize: 14.sp,
        color: const Color(0xFF7C4DFF),
        fontWeight: FontWeight.w700,
      ),

      // Kod bloklari
      code: TextStyle(
        fontSize: 12.sp,
        color: const Color(0xFF7C4DFF),
        backgroundColor: const Color(0xFFF3F0FF),
        fontFamily: 'monospace',
      ),
      codeblockDecoration: BoxDecoration(
        color: const Color(0xFFF8F6FF),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE8E0FF), width: 1),
      ),
      codeblockPadding: EdgeInsets.all(12.w),

      // Blockquote
      blockquote: TextStyle(
        fontSize: 14.sp,
        color: const Color(0xFF6B7280),
        fontStyle: FontStyle.italic,
        fontFamily: 'Nunito',
        height: 1.6,
      ),
      blockquoteDecoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: const Border(
          left: BorderSide(color: Color(0xFF7C4DFF), width: 3),
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(6.r),
          bottomRight: Radius.circular(6.r),
        ),
      ),
      blockquotePadding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),

      // Horizontal rule
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
        ),
      ),

      // Table
      tableBorder: TableBorder.all(
        color: const Color(0xFFE5E7EB),
        width: 1,
        borderRadius: BorderRadius.circular(8.r),
      ),
      tableHead: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF374151),
        fontFamily: 'Nunito',
      ),
      tableBody: TextStyle(
        fontSize: 13.sp,
        color: const Color(0xFF4B5563),
        fontFamily: 'Nunito',
      ),
      tableCellsPadding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 6.h,
      ),

      // Bo'shliqlar
      blockSpacing: 10.h,
      listIndent: 20.w,
      listBulletPadding: EdgeInsets.only(right: 6.w),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30.w,
            height: 30.w,
            margin: EdgeInsets.only(top: 2.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text('🤖', style: TextStyle(fontSize: 14.sp)),
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4.r),
                    topRight: Radius.circular(18.r),
                    bottomLeft: Radius.circular(18.r),
                    bottomRight: Radius.circular(18.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Dot(delay: 0),
                    SizedBox(width: 5.w),
                    _Dot(delay: 150),
                    SizedBox(width: 5.w),
                    _Dot(delay: 300),
                    SizedBox(width: 12.w),
                    Text(
                      'Javob yozilmoqda...',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF9CA3AF),
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
              // Cancel tugmasi
              Padding(
                padding: EdgeInsets.only(top: 6.h),
                child: GestureDetector(
                  onTap: () {
                    context.read<AiChatBloc>().add(
                      const CancelMessageEvent(),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.close_rounded,
                        size: 14.sp,
                        color: const Color(0xFF9CA3AF),
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        'Bekor qilish',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF9CA3AF),
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24.r),
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
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10.h,
                  ),
                ),
                maxLines: 4,
                minLines: 1,
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
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLoading
                          ? [const Color(0xFFD1D5DB), const Color(0xFFE5E7EB)]
                          : [const Color(0xFF2D6A9F), const Color(0xFF4A90D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22.r),
                    boxShadow: isLoading
                        ? []
                        : [
                            BoxShadow(
                              color:
                                  const Color(0xFF2D6A9F).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: isLoading
                      ? Padding(
                          padding: EdgeInsets.all(11.w),
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
              color: const Color.fromRGBO(0, 0, 0, 0.03),
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

// ============= Dots Animation =============
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
              Color.fromRGBO(124, 77, 255, 0.3 + _animation.value * 0.7),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
