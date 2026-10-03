import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/factory_store.dart';
import 'main_layout.dart';

/// شاشة تمهيدية (Splash Screen) تُظهر الشعار لمدة قصيرة ثم تنتقل إلى الواجهة الرئيسية.
class SplashScreen extends StatefulWidget {
  final FactoryStore store;
  const SplashScreen({super.key, required this.store});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
    // بعد 2.5 ثانية ننتقل للواجهة الرئيسية
    Future.delayed(const Duration(seconds: 3), _goToHome);
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainLayout(store: widget.store)),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[900] : AppTheme.surfaceWhite;
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              // ضع مسار الشعار الموجود في المشروع (assets/logo.png)
              ImageAssetLogo(),
              SizedBox(height: 20),
              Text(
                'النجمة بلاست',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// عنصر وصفي لعرض الشعار من assets. سيتأكد من صحة المسار عند الإقلاع.
class ImageAssetLogo extends StatelessWidget {
  final double size;
  const ImageAssetLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.factory,
        size: size,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
