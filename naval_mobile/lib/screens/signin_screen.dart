import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../services/user_service.dart';
import '../providers/theme_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  static const Color _tiktokRed = Color(0xFFFF2D55);
  static const String _tiktokIconUrl =
      'https://img.icons8.com/?size=100&id=123922&format=png&color=FFFFFF';

  void _loginDummyJson() async {
    if (!_formKey.currentState!.validate()) return;

    final UserService userService = UserService();
    setState(() => _isLoading = true);

    try {
      final response = await userService.loginUser(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushReplacementNamed(context, '/home', arguments: response);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String friendlyMessage = 'Unable to sign in. Please try again.';

      if (error is SocketException || error is TimeoutException) {
        friendlyMessage = 'No internet connection. Please check your network.';
      } else {
        final errorString = error.toString().toLowerCase();
        if (errorString.contains('invalid credentials') ||
            errorString.contains('400')) {
          friendlyMessage = 'Invalid username or password. Please try again.';
        } else if (errorString.contains('500') ||
            errorString.contains('server')) {
          friendlyMessage = 'Server error. Please try again later.';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyMessage),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loginFirebase() async {
    if (!_formKey.currentState!.validate()) return;
    final identifier = _usernameController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(identifier)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firebase login requires an email address.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await UserService().signIn(
        email: identifier,
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(firebaseAuthErrorMessage(error))));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to sign in. Please try again.')),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Sign In', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.network(
                      _tiktokIconUrl,
                      width: 90.w,
                      height: 90.h,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.shopping_bag_outlined,
                        size: 56.sp,
                        color: _tiktokRed,
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),
                  TextFormField(
                    controller: _usernameController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Username or Email',
                      labelStyle: TextStyle(color: Colors.white),
                      hintStyle: TextStyle(color: Colors.white70),
                      errorStyle: const TextStyle(color: Colors.white),
                      prefixIcon: const Icon(Icons.person, color: _tiktokRed),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: _tiktokRed),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[800]! : Colors.grey,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[800]! : Colors.grey,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter your username or email'
                        : null,
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white),
                      hintStyle: TextStyle(color: Colors.white70),
                      errorStyle: const TextStyle(color: Colors.white),
                      prefixIcon: const Icon(Icons.lock, color: _tiktokRed),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: isDarkMode ? Colors.grey[500] : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: _tiktokRed),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[800]! : Colors.grey,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[800]! : Colors.grey,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter your password'
                        : null,
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _loginDummyJson,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tiktokRed,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: const StadiumBorder(),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Login with DummyJSON',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                  ),
                  SizedBox(height: 12.h),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _loginFirebase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tiktokRed,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: const StadiumBorder(),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Login with Firebase',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                  ),
                  SizedBox(height: 12.h),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.pushNamed(context, '/signup'),
                    child: const Text('Create account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
