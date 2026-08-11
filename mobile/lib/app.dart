import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'core/app_services.dart';
import 'theme/app_theme.dart';

class LooplyApp extends StatelessWidget {
  const LooplyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Looply',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final results = await Future.wait([
      AppServices.instance.session.restore(),
      Future<void>.delayed(const Duration(milliseconds: 900))
    ]);
    if (!mounted) return;
    final authenticated = results.first as bool;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) =>
            authenticated ? const HomeScreen() : const AuthScreen()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: .12),
                Theme.of(context).scaffoldBackgroundColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.center,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandMark(size: 82),
                SizedBox(height: 20),
                Text('looply',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1)),
                SizedBox(height: 8),
                Text('Keep the conversation close',
                    style: TextStyle(color: Color(0xFF77758A))),
              ],
            ),
          ),
        ),
      );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 50});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF1463FF), Color(0xFF0A39D8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(size * .34),
          boxShadow: const [
            BoxShadow(
                color: Color(0x400C4CF5), blurRadius: 22, offset: Offset(0, 9))
          ],
        ),
        child: Icon(Icons.forum_rounded, color: Colors.white, size: size * .52),
      );
}

void openHome(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (_) => false);
}
