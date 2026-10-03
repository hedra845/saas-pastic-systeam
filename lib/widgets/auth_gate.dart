// lib/widgets/auth_gate.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../state/factory_store.dart';
import '../screens/login_screen.dart';
import '../views/main_layout.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.currentUser == null) {
      return const LoginScreen();
    }
    final store = Provider.of<FactoryStore>(context);
    return MainLayout(store: store);
  }
}
