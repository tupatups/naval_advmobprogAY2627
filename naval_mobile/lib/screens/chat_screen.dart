import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../widgets/custom_text.dart';
import 'chat_detailscreen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  final String _currentUserEmail =
      FirebaseAuth.instance.currentUser?.email ?? '';
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _displayName(Map<String, dynamic> user) {
    final firstName =
        (user['fName'] ?? user['firstName'] ?? '').toString().trim();
    final lastName =
        (user['lName'] ?? user['lastName'] ?? '').toString().trim();
    final fullName = [firstName, lastName]
        .where((part) => part.isNotEmpty)
        .join(' ');
    if (fullName.isNotEmpty) return fullName;

    for (final key in ['username', 'email']) {
      final value = (user[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return 'Unknown';
  }

  bool _matchesSearch(Map<String, dynamic> user) {
    if (_searchText.isEmpty) return true;
    final searchableText = [
      _displayName(user),
      user['username'],
      user['email'],
    ].map((value) => value?.toString().toLowerCase() ?? '').join(' ');
    return searchableText.contains(_searchText);
  }

  void _openChat(Map<String, dynamic> user) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          currentUserEmail: _currentUserEmail,
          tappedUser: user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 10.h),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(
                () => _searchText = value.trim().toLowerCase(),
              ),
              decoration: InputDecoration(
                hintText: 'Search chat...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchText = '');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: CustomText(
                      text: 'Error loading users: ${snapshot.error}',
                      fontSize: 16.sp,
                    ),
                  );
                }

                final allUsers = snapshot.data ?? <Map<String, dynamic>>[];
                if (allUsers.isEmpty) {
                  return Center(
                    child: CustomText(text: 'No users found', fontSize: 16.sp),
                  );
                }

                final users = allUsers.where(_matchesSearch).toList();
                if (users.isEmpty) {
                  return Center(
                    child: CustomText(
                      text: 'No users match your search',
                      fontSize: 16.sp,
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _UserTile(
                      name: _displayName(user),
                      email: (user['email'] ?? 'No email').toString(),
                      onTap: () => _openChat(user),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.name,
    required this.email,
    required this.onTap,
  });

  final String name;
  final String email;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: CustomText(
            text: initial,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        title: CustomText(
          text: name,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
        subtitle: CustomText(text: email, fontSize: 12.sp),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}