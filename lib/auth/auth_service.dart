// lib/auth/auth_service.dart

import '../models/user.dart';
import '../services/local_database_service.dart';
import '../services/history_service.dart';

/// خدمة التحقق من هوية المدير وإدارة كلمة المرور
class AuthService {
  AuthService._privateConstructor() {
    _initSavedPassword();
  }
  static final AuthService instance = AuthService._privateConstructor();

  User? _currentUser;
  String _customPassword = '';

  Future<void> _initSavedPassword() async {
    try {
      final data = await LocalDatabaseService.instance.loadData();
      if (data != null && data['adminPassword'] != null) {
        _customPassword = data['adminPassword'].toString().trim();
      }
    } catch (_) {}
  }

  void setAdminPassword(String newPass) {
    _customPassword = newPass.trim();
  }

  /// التحقق من مطابقة كلمة المرور المدخلة
  bool verifyPassword(String input) {
    final clean = input.trim();
    if (_customPassword.isNotEmpty) {
      return clean == _customPassword;
    }
    // كلمات المرور الافتراضية المقبولة قبل أول تغيير
    return clean == 'admin' ||
        clean == '123456' ||
        clean == '1234' ||
        clean == 'admin123';
  }

  /// تغيير وتحديث كلمة المرور مع الحفظ الدائم
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final curr = currentPassword.trim();
    final newP = newPassword.trim();

    if (_customPassword.isEmpty) {
      await _initSavedPassword();
    }

    if (!verifyPassword(curr)) {
      throw Exception('كلمة المرور الحالية غير صحيحة');
    }

    if (newP.isEmpty) {
      throw Exception('كلمة المرور الجديدة لا يمكن أن تكون فارغة');
    }

    if (newP.length < 3) {
      throw Exception('يجب أن تتكون كلمة المرور من 3 خانات أو أكثر');
    }

    _customPassword = newP;

    // حفظ في قاعدة البيانات المحلية
    try {
      final db = LocalDatabaseService.instance;
      final data = await db.loadData() ?? <String, dynamic>{};
      data['adminPassword'] = newP;
      await db.saveData(data);
    } catch (_) {}
  }

  /// تسجيل دخول المدير
  Future<User> signIn({String? username, String? email, String? password}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final cleanPass = (password ?? '').trim();

    if (_customPassword.isEmpty) {
      await _initSavedPassword();
    }

    if (verifyPassword(cleanPass)) {
      _currentUser = User(
        id: '1',
        username: 'المدير العام',
        email: 'admin@factory.com',
        role: 'admin',
      );
      HistoryService.instance.logEvent(
        type: 'login',
        title: 'تسجيل دخول',
        details: 'المستخدم: المدير العام',
        user: 'المدير العام',
      );
      return _currentUser!;
    } else {
      throw Exception('كلمة المرور غير صحيحة');
    }
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
    HistoryService.instance.logEvent(
      type: 'logout',
      title: 'تسجيل خروج',
      details: 'المستخدم: المدير العام',
      user: 'المدير العام',
    );
    _currentUser = null;
  }

  User? get currentUser => _currentUser;
}
