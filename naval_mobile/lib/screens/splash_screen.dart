import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/login_type.dart';
import '../services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();
  static const Color _tiktokRed = Color(0xFFFF2D55);
  static const String _tiktokIconUrl =
      'https://img.icons8.com/?size=100&id=123922&format=png&color=FFFFFF';
  StreamSubscription? _authSubscription;
  bool _hasRouted = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = authStateChanges.listen((user) {
      if (user == null && !_hasRouted && mounted) {
        _routeToSignIn();
      }
    });
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final loginType = await _userService.getLoginType();
    if (!mounted) return;

    if (loginType == LoginType.firebase) {
      if (currentUser != null) {
        await _userService.refreshFirebaseToken();
        if (!mounted) return;
        _routeToHome();
      } else {
        _routeToSignIn();
      }
    } else if (loginType == LoginType.dummyJson &&
        await _userService.isLoggedIn()) {
      if (!mounted) return;
      final userData = await _userService.getUserData();
      if (!mounted) return;
      _routeToHome(arguments: userData);
    } else {
      _routeToSignIn();
    }
  }

  void _routeToHome({Object? arguments}) {
    if (_hasRouted || !mounted) return;
    _hasRouted = true;
    Navigator.pushReplacementNamed(context, '/home', arguments: arguments);
  }

  void _routeToSignIn() {
    if (_hasRouted || !mounted) return;
    _hasRouted = true;
    Navigator.pushReplacementNamed(context, '/signin');
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              _tiktokIconUrl,
              width: 120.w,
              height: 120.h,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.shopping_bag_rounded,
                size: 72.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              'TikTok Shop',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 24.h),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_tiktokRed),
            ),
          ],
        ),
      ),
    );
  }
}
