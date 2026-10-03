import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable dialog widget with consistent styling and many optional enhancements:
/// - Optional header with title and logo.
/// - Fade‑in animation.
/// - Dark‑mode aware background.
/// - Unsaved‑changes guard.
/// - Optional countdown timer that auto‑closes the dialog.
/// - Optional language toggle (Arabic/English) for static strings.
/// - Optional drag‑and‑drop file support.
/// - Optional resizable dialog via drag handles.
class StyledDialog extends StatefulWidget {
  final Widget child;
  final String? title; // optional title displayed in the header
  final String? logoAssetPath; // optional logo asset path
  final bool hasUnsavedChanges; // if true, will prompt on close
  final bool enableTimer; // show a countdown timer when true
  final int timerSeconds; // duration of the timer (seconds)
  final VoidCallback? onTimerExpire; // callback when timer expires
  final bool enableLanguageToggle; // show a button to toggle language
  final bool enableDragDrop; // enable drag‑and‑drop file handling
  final Function(List<String> files)? onFilesDropped; // files dropped callback
  final bool resizable; // allow user to resize the dialog

  const StyledDialog({
    super.key,
    required this.child,
    this.title,
    this.logoAssetPath,
    this.hasUnsavedChanges = false,
    this.enableTimer = false,
    this.timerSeconds = 0,
    this.onTimerExpire,
    this.enableLanguageToggle = false,
    this.enableDragDrop = false,
    this.onFilesDropped,
    this.resizable = false,
  });

  @override
  State<StyledDialog> createState() => _StyledDialogState();
}

class _StyledDialogState extends State<StyledDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _isArabic = true; // default language is Arabic
  double _dialogWidth = 600;
  double _dialogHeight = 400;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    WidgetsBinding.instance.addPostFrameCallback((_) => _animCtrl.forward());

    if (widget.enableTimer && widget.timerSeconds > 0) {
      _remainingSeconds = widget.timerSeconds;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            t.cancel();
            widget.onTimerExpire?.call();
            Navigator.of(context).pop();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!widget.hasUnsavedChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تأكيد الإغلاق'),
        content: const Text('هل تريد إغلاق الحوار بدون حفظ التغييرات؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('متأكد')),
        ],
      ),
    );
    return result == true;
  }

  // Helper to return Arabic or English version of a static string.
  String _t(String arabic, String english) => _isArabic ? arabic : english;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? Colors.grey[900] : AppTheme.surfaceWhite;

    Widget dialogBody = Dialog(
      backgroundColor: background,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: widget.resizable ? _dialogWidth : null,
        height: widget.resizable ? _dialogHeight : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.title != null || widget.logoAssetPath != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    if (widget.logoAssetPath != null)
                      Image.asset(
                        widget.logoAssetPath!,
                        height: 32,
                        width: 32,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    if (widget.logoAssetPath != null) const SizedBox(width: 8),
                    if (widget.title != null)
                      Expanded(
                        child: Text(
                          widget.title!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    if (widget.enableTimer && _remainingSeconds > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          _t('\$_remainingSeconds ث', '\$_remainingSeconds s'),
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    if (widget.enableLanguageToggle)
                      IconButton(
                        tooltip: _t('تبديل اللغة', 'Toggle language'),
                        icon: const Icon(Icons.language),
                        onPressed: () => setState(() => _isArabic = !_isArabic),
                      ),
                  ],
                ),
              ),
            widget.resizable
                ? Expanded(
                    child: widget.enableDragDrop && widget.onFilesDropped != null
                        ? DragTarget<List<String>>(
                            onAcceptWithDetails: (details) => widget.onFilesDropped?.call(details.data),
                            builder: (context, candidateData, rejectedData) => widget.child,
                          )
                        : widget.child,
                  )
                : Flexible(
                    child: widget.enableDragDrop && widget.onFilesDropped != null
                        ? DragTarget<List<String>>(
                            onAcceptWithDetails: (details) => widget.onFilesDropped?.call(details.data),
                            builder: (context, candidateData, rejectedData) => widget.child,
                          )
                        : widget.child,
                  ),
            if (widget.resizable)
              Align(
                alignment: Alignment.bottomRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: (details) {
                    setState(() {
                      _dialogWidth = (_dialogWidth + details.delta.dx)
                          .clamp(300.0, MediaQuery.of(context).size.width - 40);
                      _dialogHeight = (_dialogHeight + details.delta.dy)
                          .clamp(200.0, MediaQuery.of(context).size.height - 80);
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.open_in_full, size: 16, color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: !widget.hasUnsavedChanges,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: FadeTransition(
          opacity: _fadeAnim,
          child: dialogBody,
        ),
      ),
    );
  }
}
