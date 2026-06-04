import 'package:flutter/material.dart';
import '../../core/utils/responsive_layout.dart';
import 'mobile/mobile_admin_shell.dart';
import 'web/web_admin_shell.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: MobileAdminShell(),
      web: WebAdminShell(),
    );
  }
}
