import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:systeam_plastic/main.dart';

import 'package:systeam_plastic/auth/auth_service.dart';

void main() {
  testWidgets('Plastic Factory App smoke test', (WidgetTester tester) async {
    // محاكاة شاشة كمبيوتر مكتبية أو تابلت عريض لنظام إدارة المصنع
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // تسجيل الدخول المسبق للوصول للواجهة الرئيسية
    await AuthService.instance.signIn(username: 'admin', password: 'admin');

    await tester.pumpWidget(const PlasticFactoryApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // التأكد من ظهور عناصر السايدبار ولوحة التحكم الرئيسية
    expect(find.text('النجمة بلاست'), findsWidgets);
    expect(find.text('لوحة التحكم'), findsWidgets);
    expect(find.text('إجمالي الإنتاج (كجم)'), findsOneWidget);
    expect(find.text('إجمالي المبيعات (جنيه)'), findsOneWidget);
    expect(find.text('صافي الربح (جنيه)'), findsOneWidget);
    expect(find.text('إجمالي الهالك (كجم)'), findsOneWidget);
    expect(find.text('إجراءات سريعة'), findsOneWidget);
  });
}
