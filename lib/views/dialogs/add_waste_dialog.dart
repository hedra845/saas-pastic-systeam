import 'package:flutter/material.dart';
import '../../widgets/styled_dialog.dart';
import '../../models/waste_record.dart';
import '../../state/factory_store.dart';
import '../../theme/app_theme.dart';

class AddWasteDialog extends StatefulWidget {
  final FactoryStore store;

  const AddWasteDialog({super.key, required this.store});

  @override
  State<AddWasteDialog> createState() => _AddWasteDialogState();
}

class _AddWasteDialogState extends State<AddWasteDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedProductId;
  final _wasteKgController = TextEditingController(text: '75');
  final _notesController = TextEditingController();
  String _wasteType = 'هالك مطلع فيلم';
  bool _isRecycled = true;

  final FocusNode _wasteKgFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.store.products.isNotEmpty) {
      _selectedProductId = widget.store.products.first.id;
    } else {
      _selectedProductId = '';
    }
    // Auto‑focus on waste amount field.
    WidgetsBinding.instance.addPostFrameCallback((_) => _wasteKgFocusNode.requestFocus());
  }

  @override
  void dispose() {
    _wasteKgController.dispose();
    _notesController.dispose();
    _wasteKgFocusNode.dispose();
    super.dispose();
  }

  void _saveWaste() {
    if (_formKey.currentState!.validate()) {
      final prod = widget.store.products.firstWhere((p) => p.id == _selectedProductId);
      widget.store.addWasteRecord(
        WasteRecord(
          id: 'waste-${DateTime.now().millisecondsSinceEpoch}',
          productId: _selectedProductId,
          productName: prod.name,
          wasteKg: double.parse(_wasteKgController.text),
          wasteType: _wasteType,
          date: DateTime.now(),
          isRecycled: _isRecycled,
          notes: _notesController.text.trim(),
        ),
      );
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل الهالك وتحديث معدل هالك الصنف بنجاح!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: 'تسجيل هالك / سكراب بلاستيك',
      hasUnsavedChanges: true,
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header moved to StyledDialog; keep close button inside child for consistency
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.wasteRedSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: AppTheme.wasteRed),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'تسجيل هالك / سكراب بلاستيك',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const Divider(height: 24),

              const Text('الصنف التابع له الهالك', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedProductId.isNotEmpty ? _selectedProductId : null,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: widget.store.products.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.name} (${p.category})'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedProductId = val);
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  // كمية الهالك
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('كمية الهالك (كجم)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.wasteRed)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _wasteKgController,
                          focusNode: _wasteKgFocusNode,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _saveWaste(),
                          decoration: InputDecoration(
                            suffixText: 'كجم',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل وزن صحيح' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // نوع الهالك
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('نوع الهالك / السبب', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _wasteType,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'هالك مطلع فيلم', child: Text('هالك مطلع فيلم')),
                            DropdownMenuItem(value: 'هالك تقطيع وتخريم', child: Text('هالك تقطيع وتخريم')),
                            DropdownMenuItem(value: 'عيوب طباعة ولحام', child: Text('عيوب طباعة ولحام')),
                            DropdownMenuItem(value: 'اختلاف سمك وميكرون', child: Text('اختلاف سمك وميكرون')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _wasteType = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('إرسال للمخرزة للراجع وإعادة التدوير', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('إضافته تلقائياً لرصيد الراجع لإعادة استخدامه في التصنيع', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                value: _isRecycled,
                activeColor: AppTheme.primaryBlue,
                onChanged: (val) => setState(() => _isRecycled = val),
              ),
              const SizedBox(height: 12),

              const Text('ملاحظات إضافية', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'مثال: سبب الهالك أو رقم الوردية...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.wasteRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('تسجيل الهالك', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _saveWaste,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
