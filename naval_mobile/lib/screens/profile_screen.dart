import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/login_type.dart';
import '../models/user.dart';
import '../providers/theme_provider.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  User? _user;
  LoginType? _loginType;
  String _memberSince = '';
  String? _errorMessage;
  bool _isLoading = true;
  bool _isLoggingOut = false;
  bool _isActionLoading = false;
  ScaffoldMessengerState? _scaffoldMessenger;

  // For DummyJSON accounts the API only simulates updates, so the locally
  // saved username is kept here and shown instead of rebuilding the User
  // (which used to drop company and address).
  String? _usernameOverride;

  static const Color _tiktokRed = Color(0xFFFF2D55);

  String? get _displayUsername => _usernameOverride ?? _user?.username;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
  }

  Future<void> _loadProfile() async {
    try {
      final loginType = await _userService.getLoginType();
      if (!mounted) return;
      final profileData = await _userService.getUserData();
      if (!mounted) return;
      final localUser = User.fromJson(profileData);
      User profileUser = localUser;
      if (loginType == LoginType.dummyJson && localUser.id != 0) {
        profileUser = await _userService.fetchFullUserProfile(localUser.id);
        if (!mounted) return;
      }
      setState(() {
        _loginType = loginType;
        _user = profileUser;
        _usernameOverride =
            loginType == LoginType.dummyJson && localUser.username.isNotEmpty
                ? localUser.username
                : null;
        _memberSince = profileData['memberSince']?.toString() ?? '';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load your profile. Please try again.';
      });
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    try {
      await _userService.signOutAll();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      _showMessage('Could not log out. Please try again.');
    }
  }

  Future<void> _updateUsername() async {
    final username = await showDialog<String>(
      context: context,
      builder: (_) => _UsernameDialog(initialValue: _displayUsername ?? ''),
    );
    if (!mounted || username == null || username.isEmpty) return;
    if (!RegExp(r'^[A-Za-z0-9_]{3,20}$').hasMatch(username)) {
      _showMessage('Use 3-20 letters, numbers, or underscores.');
      return;
    }

    setState(() => _isActionLoading = true);
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Changing username...')));
    try {
      if (_loginType == LoginType.firebase) {
        await _userService.updateUsername(username: username);
        final profileData = await _userService.getUserData();
        if (!mounted) return;
        setState(() {
          _user = User.fromJson(profileData);
          _memberSince = profileData['memberSince']?.toString() ?? '';
        });
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        _showMessage('Username updated successfully.');
      } else {
        await _userService.updateLocalUsername(username);
        if (!mounted) return;
        setState(() => _usernameOverride = username);
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        _showMessage(
          'Username updated locally. DummyJSON only simulates updates.',
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      _showMessage(firebaseAuthErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final values = await showDialog<List<String>>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (!mounted || values == null) return;
    final passwordError = _passwordError(values[1]);
    if (passwordError != null) {
      _showMessage(passwordError);
      return;
    }
    if (values[1] != values[2]) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() => _isActionLoading = true);
    try {
      await _userService.resetPasswordFromCurrentPassword(
        currentPassword: values[0],
        newPassword: values[1],
        email: currentUser?.email ?? _user?.email ?? '',
      );
      if (!mounted) return;
      _showMessage('Password updated successfully.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(firebaseAuthErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (!mounted || password == null || password.isEmpty) return;

    setState(() => _isActionLoading = true);
    try {
      await _userService.deleteAccount(
        email: currentUser?.email ?? _user?.email ?? '',
        password: password,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isActionLoading = false);
      _showMessage(firebaseAuthErrorMessage(error));
    }
  }

  String? _passwordError(String password) {
    if (password.length < 8) {
      return 'Password needs at least 8 characters.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password needs an uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password needs a lowercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password needs a number.';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Password needs a special character.';
    }
    return null;
  }

  void _showMessage(String message) {
    _scaffoldMessenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _tiktokRed));
    }
    final isFirebase = _loginType == LoginType.firebase;
    final name = _user?.fullName.isNotEmpty == true
        ? _user!.fullName
        : _displayUsername ?? '';

    return Container(
      color: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: _tiktokRed,
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36.r,
                    backgroundColor: Colors.white,
                    backgroundImage: _user?.image.isNotEmpty == true
                        ? NetworkImage(_user!.image)
                        : null,
                    child: _user?.image.isEmpty != false
                        ? Text(
                            _initials(name),
                            style: TextStyle(
                              color: _tiktokRed,
                              fontSize: 24.sp,
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _user?.email ?? '',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Chip(
                          label: Text(isFirebase ? 'Firebase' : 'DummyJSON'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: EdgeInsets.all(12.w),
                child: Text(_errorMessage!),
              ),
            SizedBox(height: 12.h),
            _buildSection(
              title: 'Personal Information',
              isDarkMode: isDarkMode,
              tiles: [
                _buildTile(
                  Icons.person_outline,
                  'Username',
                  _displayUsername,
                  isDarkMode,
                ),
                _buildTile(Icons.phone, 'Phone', _user?.phone, isDarkMode),
                _buildTile(
                  Icons.cake,
                  'Age',
                  _user == null || _user!.age == 0
                      ? null
                      : '${_user!.age} years',
                  isDarkMode,
                ),
                _buildTile(
                  Icons.calendar_today,
                  'Member since',
                  _memberSince,
                  isDarkMode,
                ),
                if (!isFirebase)
                  _buildTile(
                    Icons.person,
                    'Gender',
                    _user?.gender.toUpperCase(),
                    isDarkMode,
                  ),
              ],
            ),
            if (!isFirebase) ...[
              SizedBox(height: 12.h),
              _buildSection(
                title: 'Employment Details',
                isDarkMode: isDarkMode,
                tiles: [
                  _buildTile(
                    Icons.business,
                    'Company',
                    _user?.company.name,
                    isDarkMode,
                  ),
                  _buildTile(
                    Icons.work_outline,
                    'Job Title',
                    _user?.company.title,
                    isDarkMode,
                  ),
                  _buildTile(
                    Icons.category,
                    'Department',
                    _user?.company.department,
                    isDarkMode,
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _buildSection(
                title: 'Shipping Address',
                isDarkMode: isDarkMode,
                tiles: [
                  _buildTile(
                    Icons.location_on_outlined,
                    'Address',
                    _user?.address.fullAddress,
                    isDarkMode,
                  ),
                ],
              ),
            ],
            _buildActions(isFirebase),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: Text(
                    _isLoggingOut ? 'Logging out...' : 'Log Out',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  onPressed: _isLoggingOut || _isActionLoading
                      ? null
                      : _handleLogout,
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(bool isFirebase) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: _isActionLoading ? null : _updateUsername,
            icon: const Icon(Icons.edit),
            label: const Text('Update username'),
          ),
          OutlinedButton.icon(
            onPressed: !isFirebase || _isActionLoading ? null : _changePassword,
            icon: const Icon(Icons.lock_reset),
            label: Text(
              isFirebase
                  ? 'Change password'
                  : 'Change password (Firebase only)',
            ),
          ),
          OutlinedButton.icon(
            onPressed: !isFirebase || _isActionLoading ? null : _deleteAccount,
            icon: const Icon(Icons.delete_outline),
            label: Text(
              isFirebase ? 'Delete account' : 'Delete account (Firebase only)',
            ),
          ),
          if (!isFirebase)
            const Text(
              'Password changes and account deletion are unavailable for DummyJSON demo accounts.',
              textAlign: TextAlign.center,
            ),
          if (_isActionLoading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildSection({
    required String title,
    required bool isDarkMode,
    required List<Widget> tiles,
  }) {
    return Container(
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Divider(
            height: 1,
            color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
          ),
          ...tiles,
        ],
      ),
    );
  }

  Widget _buildTile(
    IconData iconData,
    String label,
    String? value,
    bool isDarkMode,
  ) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return ListTile(
      dense: true,
      leading: Icon(iconData, color: _tiktokRed, size: 20.sp),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13.sp,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 14.sp,
          color: isDarkMode ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogs
//
// Each dialog owns its TextEditingController(s) and disposes them in its own
// State.dispose(), which only runs after the dialog route has fully left the
// tree. Disposing right after `await showDialog(...)` (the old code) happens
// while the exit animation is still running, which caused the
// '_dependents.isEmpty' assertion.
// ---------------------------------------------------------------------------

class _UsernameDialog extends StatefulWidget {
  const _UsernameDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends State<_UsernameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update username'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: 'Username'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _currentController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
          TextField(
            controller: _newController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
          TextField(
            controller: _confirmController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm password'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, [
            _currentController.text,
            _newController.text,
            _confirmController.text,
          ]),
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete account?'),
      content: TextField(
        controller: _controller,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Password'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}