import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/login_type.dart';
import '../models/user.dart' as app_user;

ValueNotifier<UserService> userService = ValueNotifier(UserService());

class UserService {
  static const String _baseUrl = 'https://dummyjson.com';
  Map<String, dynamic> data = {};

  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      await saveUserData(data);
      await _saveLoginType(LoginType.dummyJson);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = app_user.User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);

    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (await getLoginType() == LoginType.firebase) {
      final user = currentUser;
      if (user == null) return {};
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final profile = snapshot.data() ?? <String, dynamic>{};
      final createdAt = profile['createdAt'];
      return {
        'id': 0,
        'uid': user.uid,
        'username': profile['username'] ?? user.displayName ?? '',
        'email': user.email ?? profile['email'] ?? '',
        'firstName': profile['fName'] ?? '',
        'lastName': profile['lName'] ?? '',
        'age': profile['age'] ?? 0,
        'phone': profile['contactNo'] ?? '',
        'image': '',
        'memberSince': createdAt is Timestamp
            ? createdAt.toDate().toIso8601String()
            : createdAt?.toString() ?? '',
      };
    }
    return {
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
      'phone': prefs.getString('phone') ?? '',
      'age': prefs.getInt('age') ?? 0,
    };
  }

  Future<void> updateLocalUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  Future<app_user.User> getUser() async {
    final userData = await getUserData();
    return app_user.User.fromJson(userData);
  }

  /// Fetches full profile details from the DummyJSON API
  Future<app_user.User> fetchFullUserProfile(int userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/users/$userId'));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return app_user.User.fromJson(json);
    } else {
      throw Exception('Failed to fetch full user profile');
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await signOutAll();
  }

  Future<LoginType?> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(loginTypeKey);
    for (final type in LoginType.values) {
      if (type.name == value) return type;
    }
    return null;
  }

  Future<void> _saveLoginType(LoginType loginType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(loginTypeKey, loginType.name);
  }

  Future<firebase_auth.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _saveLoginType(LoginType.firebase);
    return credential;
  }

  Future<firebase_auth.UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _saveLoginType(LoginType.firebase);
    return credential;
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> updateUsername({required String username}) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('No Firebase user is signed in.');
    }
    await user.updateDisplayName(username);
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'username': username,
    }, SetOptions(merge: true));
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('No Firebase user is signed in.');
    }
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
    await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
    await user.delete();
    await firebaseAuth.signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('No Firebase user is signed in.');
    }
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<String?> refreshFirebaseToken() async {
    return currentUser?.getIdToken(true);
  }

  Future<void> signOutAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (currentUser != null) {
        await firebaseAuth.signOut();
      }
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }
}

final firebase_auth.FirebaseAuth firebaseAuth =
    firebase_auth.FirebaseAuth.instance;

firebase_auth.User? get currentUser => firebaseAuth.currentUser;

Stream<firebase_auth.User?> get authStateChanges =>
    firebaseAuth.authStateChanges();

String firebaseAuthErrorMessage(Object error) {
  if (error is! firebase_auth.FirebaseAuthException) {
    return 'Something went wrong. Please try again.';
  }

  switch (error.code) {
    case 'email-already-in-use':
      return 'That email address is already in use.';
    case 'weak-password':
      return 'That password is too weak.';
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'user-not-found':
      return 'No account was found for that email address.';
    case 'wrong-password':
      return 'The password is incorrect.';
    case 'invalid-credential':
      return 'The email or password is incorrect.';
    case 'requires-recent-login':
      return 'Please sign in again before trying that action.';
    case 'network-request-failed':
      return 'Network error. Check your connection and try again.';
    default:
      return error.message ?? 'Something went wrong. Please try again.';
  }
}
