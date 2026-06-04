import 'package:flutter/material.dart';
import '../../core/utils/responsive_layout.dart';
import 'mobile/mobile_login_screen.dart';
import 'web/web_login_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: MobileLoginScreen(),
      web: WebLoginScreen(),
    );
  }
}
