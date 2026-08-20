import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;

  static const Color _tiktokRed = Color(0xFFFF2D55);

  @override
  void initState() {
    super.initState();
    _loadFullUserProfile();
  }

  Future<void> _loadFullUserProfile() async {
    try {
      final localUser = await _userService.getUser();
      if (localUser.id != 0) {
        final fullUser = await _userService.fetchFullUserProfile(localUser.id);
        if (!mounted) return;
        setState(() {
          _user = fullUser;
          _isLoading = false;
        });
      } else {
        setState(() {
          _user = localUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      final localUser = await _userService.getUser();
      if (!mounted) return;
      setState(() {
        _user = localUser;
        _isLoading = false;
        _errorMessage = 'Could not sync live details. Displaying cached data.';
      });
    }
  }

  void _handleLogout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _tiktokRed),
      );
    }

    return Container(
      color: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
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
                    child: _user?.image.isEmpty == true
                        ? Icon(Icons.person, size: 36.sp, color: _tiktokRed)
                        : null,
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user?.fullName.isNotEmpty == true
                              ? _user!.fullName
                              : _user?.username ?? '',
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
                        if (_user?.role.isNotEmpty == true)
                          Container(
                            margin: EdgeInsets.only(top: 6.h),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              _user!.role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8.w),
                color: isDarkMode
                    ? Colors.orange[900]?.withValues(alpha: 0.3)
                    : Colors.amber[100],
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDarkMode ? Colors.orange[200] : Colors.brown,
                  ),
                ),
              ),

            SizedBox(height: 12.h),

            // Section: Personal Information
            _buildSection(
              title: 'Personal Information',
              isDarkMode: isDarkMode,
              tiles: [
                _buildTile(Icons.phone, 'Phone', _user?.phone, isDarkMode),
                _buildTile(
                  Icons.cake,
                  'Birth Date',
                  '${_user?.birthDate} (${_user?.age} yrs)',
                  isDarkMode,
                ),
                _buildTile(
                  Icons.person_outline,
                  'Gender',
                  _user?.gender.toUpperCase(),
                  isDarkMode,
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Section: Company / Job
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

            // Section: Address
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

            SizedBox(height: 16.h),

            // Logout Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  onPressed: _handleLogout,
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
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