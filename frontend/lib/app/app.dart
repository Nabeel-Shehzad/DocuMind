import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_theme.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/upload/upload_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/summary/summary_screen.dart';
import 'routes.dart';
import 'bindings.dart';

class DocuMindApp extends StatelessWidget {
  const DocuMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title:                    'DocuMind AI',
      debugShowCheckedModeBanner: false,
      theme:                    AppTheme.dark,
      initialBinding:           InitialBinding(),
      initialRoute:             AppRoutes.splash,
      getPages: [
        GetPage(name: AppRoutes.splash,   page: () => const SplashScreen()),
        GetPage(name: AppRoutes.login,    page: () => const LoginScreen()),
        GetPage(name: AppRoutes.register, page: () => const RegisterScreen()),
        GetPage(
          name:       AppRoutes.home,
          page:       () => const HomeScreen(),
          transition: Transition.fade,
        ),
        GetPage(
          name:       AppRoutes.upload,
          page:       () => const UploadScreen(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name:       AppRoutes.chat,
          page:       () => const ChatScreen(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name:       AppRoutes.summary,
          page:       () => const SummaryScreen(),
          transition: Transition.rightToLeft,
        ),
      ],
      defaultTransition: Transition.fade,
    );
  }
}
