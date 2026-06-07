import 'package:flutter/material.dart';
import '../localization/l10n_extension.dart';
import '../theme/app_colors.dart';

class CustomToast extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback onDismiss;

  const CustomToast({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.onDismiss,
  });

  @override
  State<CustomToast> createState() => _CustomToastState();

  static void showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    show(
      context,
      title: isError ? context.tr('error') : context.tr('success'),
      message: message,
      icon: isError ? Icons.error_outline : Icons.check_circle_outline,
      color: isError ? AppColors.error : AppColors.success,
    );
  }

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 32,
          right: 32,
          child: Material(
            color: Colors.transparent,
            child: CustomToast(
              title: title,
              message: message,
              icon: icon,
              color: color,
              onDismiss: () {
                overlayEntry.remove();
              },
            ),
          ),
        );
      },
    );

    overlayState.insert(overlayEntry);

    // Auto dismiss
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class _CustomToastState extends State<CustomToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                onPressed: () {
                  _controller.reverse().then((_) => widget.onDismiss());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}