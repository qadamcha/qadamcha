import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../bloc/ai_chat_bloc.dart';
import '../bloc/ai_chat_event.dart';
import '../bloc/ai_chat_state.dart';
import 'ai_chat_page.dart';

/// Chatlar ro'yxati — ChatGPT uslubida
class ChatSessionsPage extends StatefulWidget {
  const ChatSessionsPage({super.key});

  @override
  State<ChatSessionsPage> createState() => _ChatSessionsPageState();
}

class _ChatSessionsPageState extends State<ChatSessionsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AiChatBloc>().add(const LoadAllChatsEvent());
    context.read<AiChatBloc>().add(const CheckAiStatusEvent());
  }

  void _openChat(String sessionId) {
    final bloc = context.read<AiChatBloc>();
    bloc.add(LoadChatEvent(sessionId: sessionId));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const AiChatPage(),
        ),
      ),
    );
  }

  void _createNewChat() {
    final bloc = context.read<AiChatBloc>();
    bloc.add(const CreateNewChatEvent());
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const AiChatPage(),
        ),
      ),
    );
  }

  void _deleteChat(String sessionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Chatni o\'chirish',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'Nunito',
          ),
        ),
        content: Text(
          'Bu suhbat butunlay o\'chiriladi. Davom etasizmi?',
          style: TextStyle(
            fontSize: 14.sp,
            fontFamily: 'Nunito',
            color: const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Bekor qilish',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: const Color(0xFF6B7280),
                fontSize: 14.sp,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AiChatBloc>().add(
                DeleteChatEvent(sessionId: sessionId),
              );
            },
            child: Text(
              'O\'chirish',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w700,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
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
              child: BlocBuilder<AiChatBloc, AiChatState>(
                builder: (context, state) {
                  if (state.chatSessions.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildChatList(state.chatSessions);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewChat,
        backgroundColor: const Color(0xFF2D6A9F),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Yangi chat',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: 'Nunito',
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
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
                colors: [Color(0xFF2D6A9F), Color(0xFF4A90D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Center(
              child: Icon(Icons.psychology_rounded, size: 22.sp, color: Colors.white),
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
                    fontSize: 17.sp,
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
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D6A9F), Color(0xFF4A90D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Center(
                child: Icon(Icons.psychology_rounded, size: 44.sp, color: Colors.white),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'AI Maslahatchi bilan suhbatlashing',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
                fontFamily: 'Nunito',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'Farzand tarbiyasi, rivojlanishi va sog\'lig\'i haqida '
              'savollaringizga professional javoblar oling',
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF6B7280),
                fontFamily: 'Nunito',
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(List<ChatSessionSummary> sessions) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildChatCard(session);
      },
    );
  }

  Widget _buildChatCard(ChatSessionSummary session) {
    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        _deleteChat(session.id);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 24.sp),
      ),
      child: GestureDetector(
        onTap: () => _openChat(session.id),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
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
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D6A9F), Color(0xFF4A90D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Icon(Icons.chat_bubble_rounded, size: 20.sp, color: Colors.white),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                        fontFamily: 'Nunito',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      session.lastMessage,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF6B7280),
                        fontFamily: 'Nunito',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(session.updatedAt),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF9CA3AF),
                      fontFamily: 'Nunito',
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20.sp,
                    color: const Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Hozir';
    if (diff.inHours < 1) return '${diff.inMinutes} daq';
    if (diff.inHours < 24) return '${diff.inHours} soat';
    if (diff.inDays < 7) return '${diff.inDays} kun';

    return DateFormat('dd.MM.yy').format(date);
  }
}
