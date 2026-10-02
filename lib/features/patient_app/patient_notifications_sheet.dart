import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/mock_data.dart';
import '../../core/demo/demo_session_provider.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/platform_state_view.dart';

class PatientNotificationsSheet extends StatelessWidget {
  const PatientNotificationsSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const PatientNotificationsSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final patientId = context.watch<DemoSessionProvider>().patientId;
    final data = context.watch<DataProvider>();
    final notifications = data.notificationsFor(patientId);
    return SafeArea(
      child: SizedBox(
        height: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                context.isArabic ? 'الإشعارات' : 'Notifications',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: notifications.isEmpty
                  ? PlatformStateView(
                      kind: PlatformStateKind.empty,
                      title: context.isArabic
                          ? 'لا توجد إشعارات'
                          : 'No notifications',
                      message: context.isArabic
                          ? 'ستظهر هنا تحديثات العلاج والمواعيد عند توفرها.'
                          : 'Treatment and appointment updates will appear here.',
                    )
                  : ListView.separated(
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return ListTile(
                          leading: Icon(
                            item.isRead
                                ? Icons.notifications_none_outlined
                                : Icons.notifications_active_outlined,
                            color: item.isRead
                                ? AppColors.textSecondary
                                : AppColors.primary,
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: item.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(item.detail),
                          trailing: item.isRead
                              ? null
                              : Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: AppColors.primary,
                                ),
                          onTap: () =>
                              data.markNotificationRead(patientId, item.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
