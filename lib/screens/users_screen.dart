// lib/screens/users_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../models/user.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final User? user = auth.currentUser;

    if (user == null) {
      return const Center(child: Text('لم يتم تسجيل أي مستخدم'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('المستخدمون والصلاحيات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('معرّف: ${user.id}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('البريد الإلكتروني: ${user.email}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('الصلاحية: ${user.role}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            if (user.role == 'admin') ...[
              const Text('إدارة التطبيق', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              // TODO: Add admin‑only widgets here
            ] else ...[
              const Text('مستخدم عادي', style: TextStyle(fontSize: 20)),
            ],
          ],
        ),
      ),
    );
  }
}
