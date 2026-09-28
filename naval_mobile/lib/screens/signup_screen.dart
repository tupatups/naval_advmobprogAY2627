import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  String? _validateAge(String? value) {
    final age = int.tryParse(value?.trim() ?? '');
    if (age == null) return 'Age must be a number.';
    if (age < 1 || age > 120) return 'Age must be between 1 and 120.';
    return null;
  }

  String? _validateContact(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Contact number is required.';
    }
    if (!RegExp(r'^\+?[0-9]{10,13}$').hasMatch(value.trim())) {
      return 'Use 10-13 digits, with an optional leading +.';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) return 'Username is required.';
    if (!RegExp(r'^[A-Za-z0-9_]{3,20}$').hasMatch(value.trim())) {
      return 'Use 3-20 letters, numbers, or underscores.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 8) return 'Password needs at least 8 characters.';
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

  String? _validateConfirmation(String? value) {
    if (value != _passwordController.text) return 'Passwords do not match.';
    return null;
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Creating account...')));
    User? createdUser;

    try {
      final credential = await UserService().createAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      createdUser = credential.user;
      if (createdUser == null) throw StateError('Account creation failed.');

      await createdUser.updateDisplayName(_usernameController.text.trim());
      await FirebaseFirestore.instance
          .collection('users')
          .doc(createdUser.uid)
          .set({
            'uid': createdUser.uid,
            'fName': _fNameController.text.trim(),
            'lName': _lNameController.text.trim(),
            'age': int.parse(_ageController.text.trim()),
            'contactNo': _contactController.text.trim(),
            'username': _usernameController.text.trim(),
            'email': _emailController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully.')),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } on FirebaseAuthException catch (error) {
      await _removeOrphanedUser(createdUser);
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(firebaseAuthErrorMessage(error))));
    } catch (error) {
      await _removeOrphanedUser(createdUser);
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not create the account. Please try again.'),
        ),
      );
    }
  }

  Future<void> _removeOrphanedUser(User? user) async {
    if (user == null) return;
    try {
      await user.delete();
    } catch (_) {
      await UserService().signOut();
    }
  }

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(24.w),
            children: [
              TextFormField(
                controller: _fNameController,
                decoration: _decoration('First name'),
                validator: (value) => _required(value, 'First name'),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _lNameController,
                decoration: _decoration('Last name'),
                validator: (value) => _required(value, 'Last name'),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: _decoration('Age'),
                validator: _validateAge,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: _decoration('Contact number'),
                validator: _validateContact,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _usernameController,
                decoration: _decoration('Username'),
                validator: _validateUsername,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoration('Email address'),
                validator: _validateEmail,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _decoration('Password').copyWith(
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                validator: _validatePassword,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: _decoration('Confirm password').copyWith(
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                validator: _validateConfirmation,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: _isLoading ? null : _createAccount,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Firebase account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
