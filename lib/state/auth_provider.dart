// lib/state/auth_provider.dart

import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../models/user.dart';

/// Exposes authentication state to the UI.
class AuthProvider extends ChangeNotifier {
  User? get currentUser => AuthService.instance.currentUser;

  Future<void> signIn({String? username, String? email, String? password}) async {
    await AuthService.instance.signIn(
      username: username,
      email: email,
      password: password,
    );
    notifyListeners();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await AuthService.instance.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    await AuthService.instance.signOut();
    notifyListeners();
  }
}
