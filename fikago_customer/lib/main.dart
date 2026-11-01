// ============================================================
// FIKAGO CUSTOMER APP - Main Entry
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';

import 'screens/splash_screen.dart';
import 'screens/auth/staff_access_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('sw'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('sw'),
      child: const FikaGoApp(),
    ),
  );
}

class FikaGoApp extends StatelessWidget {
  const FikaGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        // LanguageProvider imeondolewa kwa sababu EasyLocalization inatosha
      ],
      child: MaterialApp(
        title: 'FikaGo',
        debugShowCheckedModeBanner: false,
        theme: FikaGoTheme.lightTheme,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: const SplashScreen(),
        routes: {
          '/staff-access': (_) => const StaffAccessScreen(),
        },
      ),
    );
  }
}
