import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../widgets/custom_text.dart';

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    super.key,
    required this.currentUserEmail,
    required this.tappedUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _shownMessageIds = <String>{};
  late final Future<String> _currentUserIdFuture;
  bool _receivedInitialSnapshot = false;
  bool _isSendingMessage = false;

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _resolveCurrentUserId();
  }

  Future<String> _resolveCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No Firebase user is signed in.');
    return user.uid;
  }

  String get _otherUserId => (widget.tappedUser['uid'] ?? '').toString();

  String get _otherUserName {
    final firstName =
        (widget.tappedUser['fName'] ?? widget.tappedUser['firstName'] ?? '')
            .toString()
            .trim();
    final lastName =
        (widget.tappedUser['lName'] ?? widget.tappedUser['lastName'] ?? '')
            .toString()
            .trim();
    final fullName = [firstName, lastName]
        .where((part) => part.isNotEmpty)
        .join(' ');
    if (fullName.isNotEmpty) return fullName;
    for (final key in ['username', 'email']) {
      final value = (widget.tappedUser[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return 'Unknown';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String currentUserId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSendingMessage) return;

    setState(() => _isSendingMessage = true);
    try {
      await _chatService.sendMessage(_otherUserId, text);
      _messageController.clear();
      _messageFocusNode.requestFocus();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSendingMessage = false);
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _currentUserIdFuture,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (userSnapshot.hasError || !userSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }

        final currentUserId = userSnapshot.data!;
        final primaryColor = Theme.of(context).colorScheme.primary;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                _Avatar(name: _otherUserName),
                SizedBox(width: 10.w),
                Expanded(
                  child: CustomText(
                    text: _otherUserName,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _chatService.getMessage(
                    currentUserId,
                    _otherUserId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      _receivedInitialSnapshot = true;
                      return const AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        child: _EmptyChatState(key: ValueKey('empty-chat')),
                      );
                    }

                    if (!_receivedInitialSnapshot) {
                      _shownMessageIds.addAll(docs.map((doc) => doc.id));
                      _receivedInitialSnapshot = true;
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 16.h,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();
                        final isMine =
                            (data['senderId'] ?? '').toString() ==
                            currentUserId;
                        final shouldAnimate = !_shownMessageIds.contains(
                          doc.id,
                        );
                        _shownMessageIds.add(doc.id);
                        return _AnimatedMessage(
                          key: ValueKey(doc.id),
                          animate: shouldAnimate,
                          isMine: isMine,
                          child: _MessageBubble(
                            message: (data['message'] ?? '').toString(),
                            isMine: isMine,
                            isPending: doc.metadata.hasPendingWrites,
                            time: _formatTime(data['timestamp'] as Timestamp?),
                            primaryColor: primaryColor,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              _MessageComposer(
                controller: _messageController,
                focusNode: _messageFocusNode,
                isSending: _isSendingMessage,
                primaryColor: primaryColor,
                onSubmitted: (_) => _sendMessage(currentUserId),
                onSend: () => _sendMessage(currentUserId),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: 18.r,
      child: CustomText(text: initial, fontSize: 15.sp),
    );
  }
}

class _AnimatedMessage extends StatelessWidget {
  const _AnimatedMessage({
    super.key,
    required this.animate,
    required this.isMine,
    required this.child,
  });

  final bool animate;
  final bool isMine;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? 0 : 1, end: 1),
      duration: animate
          ? const Duration(milliseconds: 300)
          : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset((isMine ? 24 : -24) * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isPending,
    required this.time,
    required this.primaryColor,
  });

  final String message;
  final bool isMine;
  final bool isPending;
  final String time;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isMine ? Colors.white : Colors.black87;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        child: Container(
          margin: EdgeInsets.only(
            bottom: 10.h,
            left: isMine ? 48.w : 0,
            right: isMine ? 0 : 48.w,
          ),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isMine ? const Color(0xFFFF2D55) : Colors.grey.shade200,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              CustomText(
                text: message,
                fontSize: 15.sp,
                color: foregroundColor,
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text: time,
                    fontSize: 10.sp,
                    color: isMine ? Colors.white70 : Colors.black54,
                  ),
                  if (isMine) ...[
                    SizedBox(width: 5.w),
                    if (isPending) ...[
                      Icon(Icons.access_time, size: 12.sp, color: Colors.white70),
                      SizedBox(width: 3.w),
                      CustomText(
                        text: 'Sending...',
                        fontSize: 10.sp,
                        color: Colors.white70,
                      ),
                    ] else
                      Icon(Icons.check, size: 14.sp, color: Colors.white),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.primaryColor,
    required this.onSubmitted,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final Color primaryColor;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 10.h),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: onSubmitted,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.white70, fontSize: 14.sp),
                  filled: true,
                  fillColor: Colors.black,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 11.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: const BorderSide(color: Color(0xFFFF2D55)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: const BorderSide(color: Color(0xFFFF2D55)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF2D55),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            IconButton.filled(
              onPressed: isSending ? null : onSend,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFF2D55),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFFF2D55).withValues(alpha: 0.65),
              ),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isSending
                    ? SizedBox(
                        key: const ValueKey('sending'),
                        width: 18.w,
                        height: 18.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        key: const ValueKey('send'),
                        color: Colors.white,
                        size: 20.sp,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 350),
        child: CustomText(
          text: 'No messages yet',
          fontSize: 16.sp,
          color: Colors.grey,
        ),
      ),
    );
  }
}