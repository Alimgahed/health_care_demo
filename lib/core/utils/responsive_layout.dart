import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget web;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    required this.web,
  }) : super(key: key);

  static bool isWeb(BuildContext context) => MediaQuery.of(context).size.width >= 900;
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 900;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return web;
        } else {
          return mobile;
        }
      },
    );
  }
}
