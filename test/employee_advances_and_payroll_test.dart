import 'package:flutter_test/flutter_test.dart';
import 'package:systeam_plastic/models/employee.dart';
import 'package:systeam_plastic/models/employee_advance.dart';
import 'package:systeam_plastic/models/salary_payment.dart';
import 'package:systeam_plastic/state/factory_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('اختبارات نظام سلف الموظفين ومسيرات الرواتب (قبض الموظفين)', () {
    late FactoryStore store;

    setUp(() {
      store = FactoryStore();
    });

    test('تسجيل سلفة نقدية لموظف وخصمها من الخزنة وحساب المتبقي', () {
      final initialVaultBalance = store.currentVaultBalance;

      final emp = Employee(
        id: 'test-emp-101',
        name: 'أحمد محمود فني فيلم',
        role: 'فني ماكينة فيلم',
        department: 'خطوط الفيلم',
        shift: 'صباحية',
        monthlySalary: 8000.0,
      );
      store.addEmployee(emp);

      expect(store.getEmployeePendingAdvances(emp.id), equals(0.0));

      // صرف سلفة أولى بقيمة 1500 جنيه
      final advance1 = EmployeeAdvance(
        id: 'adv-test-1',
        employeeId: emp.id,
        employeeName: emp.name,
        amount: 1500.0,
        date: DateTime.now(),
        notes: 'سلفة علاجية',
        deductedFromTreasury: true,
      );

      store.addEmployeeAdvance(advance1, deductFromTreasury: true);

      expect(store.employeeAdvances.length, greaterThanOrEqualTo(1));
      expect(store.getEmployeePendingAdvances(emp.id), equals(1500.0));
      expect(store.currentVaultBalance, equals(initialVaultBalance - 1500.0));

      // التحقق من حالة السلفة
      final retrievedAdv = store.employeeAdvances.firstWhere((a) => a.id == 'adv-test-1');
      expect(retrievedAdv.status, equals('معلقة'));
      expect(retrievedAdv.remainingAmount, equals(1500.0));
      expect(retrievedAdv.isFullySettled, isFalse);
    });

    test('سداد يدوي جزئي أو كلي للسلفة', () {
      final emp = Employee(
        id: 'test-emp-102',
        name: 'سعيد التعبئة',
        role: 'عامل تعبئة',
        department: 'قسم التقطيع',
        shift: 'مسائية',
        monthlySalary: 6000.0,
      );
      store.addEmployee(emp);

      final advance = EmployeeAdvance(
        id: 'adv-test-2',
        employeeId: emp.id,
        employeeName: emp.name,
        amount: 2000.0,
        date: DateTime.now(),
      );
      store.addEmployeeAdvance(advance, deductFromTreasury: false);

      expect(store.getEmployeePendingAdvances(emp.id), equals(2000.0));

      // سداد يدوي بمبلغ 800 جنيه
      store.settleEmployeeAdvanceManually(advance.id, 800.0);
      expect(store.getEmployeePendingAdvances(emp.id), equals(1200.0));

      var updated = store.employeeAdvances.firstWhere((a) => a.id == advance.id);
      expect(updated.settledAmount, equals(800.0));
      expect(updated.remainingAmount, equals(1200.0));
      expect(updated.status, equals('مسددة جزئياً'));

      // سداد المتبقي (1200 جنيه)
      store.settleEmployeeAdvanceManually(advance.id, 1200.0);
      expect(store.getEmployeePendingAdvances(emp.id), equals(0.0));

      updated = store.employeeAdvances.firstWhere((a) => a.id == advance.id);
      expect(updated.settledAmount, equals(2000.0));
      expect(updated.remainingAmount, equals(0.0));
      expect(updated.isFullySettled, isTrue);
      expect(updated.status, equals('مسددة بالكامل'));
    });

    test('صرف راتب موظف مع استقطاع السلفة واحتساب صافي المستحق وتأثيره على الخزنة', () {
      final emp = Employee(
        id: 'test-emp-103',
        name: 'محمود عبد السلام',
        role: 'مشرف وردية',
        department: 'إدارة المصنع',
        shift: 'صباحية',
        monthlySalary: 9000.0,
      );
      store.addEmployee(emp);

      // موظف أخذ سلفة 2000 جنيه
      store.addEmployeeAdvance(
        EmployeeAdvance(
          id: 'adv-test-3',
          employeeId: emp.id,
          employeeName: emp.name,
          amount: 2000.0,
          date: DateTime.now(),
        ),
        deductFromTreasury: false,
      );

      expect(store.getEmployeePendingAdvances(emp.id), equals(2000.0));

      final vaultBeforeSalary = store.currentVaultBalance;

      // صرف الراتب: أساسي 9000، حوافز 500، جزاءات 200، استقطاع سلفة 1500
      // صافي الراتب المستحق = 9000 + 500 - 200 - 1500 = 7800
      final payment = SalaryPayment(
        id: 'sal-test-1',
        voucherNumber: 'PAY-SAL-2026-TEST',
        employeeId: emp.id,
        employeeName: emp.name,
        role: emp.role,
        department: emp.department,
        monthYear: 'سبتمبر 2026',
        baseSalary: 9000.0,
        incentives: 500.0,
        deductions: 200.0,
        advancesDeducted: 1500.0,
        paymentMethod: 'نقدي كاش',
        paidFromTreasury: true,
      );

      expect(payment.netSalary, equals(7800.0));

      store.addSalaryPayment(payment, payFromTreasury: true);

      // تم صرف 7800 من الخزنة
      expect(store.currentVaultBalance, equals(vaultBeforeSalary - 7800.0));

      // تم خصم 1500 من السلفة المعلقة (متبقي 500)
      expect(store.getEmployeePendingAdvances(emp.id), equals(500.0));

      final adv = store.employeeAdvances.firstWhere((a) => a.id == 'adv-test-3');
      expect(adv.settledAmount, equals(1500.0));
      expect(adv.remainingAmount, equals(500.0));
      expect(adv.status, equals('مسددة جزئياً'));

      // التحقق من حالة الراتب
      expect(store.isEmployeeSalaryPaidForMonth(emp.id, 'سبتمبر 2026'), isTrue);
      expect(store.isEmployeeSalaryPaidForMonth(emp.id, 'أكتوبر 2026'), isFalse);
    });

    test('التراجع وحذف سند صرف راتب يعيد رصيد السلفة المستقطعة تلقائياً', () {
      final emp = Employee(
        id: 'test-emp-104',
        name: 'كريم خالد',
        role: 'فني مقصات',
        department: 'قسم التقطيع',
        shift: 'ليلية',
        monthlySalary: 7000.0,
      );
      store.addEmployee(emp);

      store.addEmployeeAdvance(
        EmployeeAdvance(
          id: 'adv-test-4',
          employeeId: emp.id,
          employeeName: emp.name,
          amount: 1000.0,
          date: DateTime.now(),
        ),
        deductFromTreasury: false,
      );

      // صرف الراتب واستقطاع كامل السلفة (1000 جنيه)
      final payment = SalaryPayment(
        id: 'sal-test-2',
        voucherNumber: 'PAY-SAL-2026-REVERT',
        employeeId: emp.id,
        employeeName: emp.name,
        role: emp.role,
        department: emp.department,
        monthYear: 'سبتمبر 2026',
        baseSalary: 7000.0,
        advancesDeducted: 1000.0,
      );

      store.addSalaryPayment(payment, payFromTreasury: false);
      expect(store.getEmployeePendingAdvances(emp.id), equals(0.0));

      // الآن حذف سند الراتب
      store.deleteSalaryPayment(payment.id);

      // السلفة عادت معلقة بمبلغ 1000 جنيه
      expect(store.getEmployeePendingAdvances(emp.id), equals(1000.0));
      final adv = store.employeeAdvances.firstWhere((a) => a.id == 'adv-test-4');
      expect(adv.settledAmount, equals(0.0));
      expect(adv.status, equals('معلقة'));
    });
  });
}
