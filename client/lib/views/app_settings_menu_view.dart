import 'package:flutter/material.dart';
import '../l10n/l10n_extension.dart';
import '../services/app_appearance_controller.dart';
import '../widgets/shared/approved_app_style.dart';
import 'app_appearance_view.dart';
import 'settings_view.dart';

class AppSettingsMenuView extends StatelessWidget {
  const AppSettingsMenuView({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n, appearance = AppAppearanceScope.maybeOf(context);
    return ApprovedPage(
      title: l.appSettingsConnection,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        children: [
          if (appearance != null) ...[
            ApprovedRow(
              title: l.appAppearance,
              subtitle: l.appAppearanceDescription,
              icon: Icons.palette_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AppAppearanceView(controller: appearance),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          ApprovedRow(
            title: l.appServerConnection,
            subtitle: l.appServerDescription,
            icon: Icons.dns_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsView()),
            ),
          ),
        ],
      ),
    );
  }
}
