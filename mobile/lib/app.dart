import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_routes.dart';
import 'features/home/presentation/home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FirstAid',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (context) => const HomePage(),
        // TODO: Thêm routes cho các màn hình khác sau khi build
        // AppRoutes.triage: (context) => const TriagePage(),
      },
      onGenerateRoute: (settings) {
        // Fallback route nếu không tìm thấy named route
        return MaterialPageRoute(
          builder: (context) => const HomePage(),
        );
      },
    );
  }
}