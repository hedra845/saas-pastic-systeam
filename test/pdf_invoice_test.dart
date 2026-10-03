import 'package:flutter_test/flutter_test.dart';
import 'package:systeam_plastic/services/pdf_report_service.dart';
import 'package:systeam_plastic/state/factory_store.dart';
import 'package:systeam_plastic/models/sale_order.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Generate invoice PDF test', () async {
    final store = FactoryStore();
    final order = SaleOrder(
      id: 'test-order-1',
      invoiceNumber: 'INV-W-245621',
      saleType: 'جملة',
      customerName: 'GHVGHH',
      date: DateTime.now(),
      paymentMethod: 'نقدي',
      paymentStatus: 'مدفوع بالكامل',
      paidAmount: 450,
      items: [
        SaleOrderItem(
          productId: 'prod-1',
          productName: 'أكياس نايلون 10 كجم',
          quantityKg: 10,
          unitPrice: 45,
          unitCost: 35,
        ),
      ],
    );

    try {
      final doc = await PdfReportService.generateInvoicePdf(store: store, order: order);
      final bytes = await doc.save();
      expect(bytes.isNotEmpty, true);
      print('PDF generated successfully, size: ${bytes.length} bytes');
    } catch (e, st) {
      print('ERROR GENERATING PDF: $e\n$st');
      rethrow;
    }
  });
}
