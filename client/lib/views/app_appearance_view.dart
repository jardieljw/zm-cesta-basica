import 'package:flutter/material.dart';
import '../l10n/l10n_extension.dart';
import '../services/app_appearance_controller.dart';
import '../widgets/shared/approved_app_style.dart';

class AppAppearanceView extends StatefulWidget {
  final AppAppearanceController controller;
  const AppAppearanceView({super.key, required this.controller});
  @override
  State<AppAppearanceView> createState() => _AppAppearanceViewState();
}

class _AppAppearanceViewState extends State<AppAppearanceView> {
  bool _saving = false;
  Future<void> _save({
    ThemeMode? theme,
    Color? color,
    bool? pure,
    AppMaterialMode? material,
    AppMotionMode? motion,
  }) async {
    setState(() => _saving = true);
    try {
      await widget.controller.save(
        theme: theme,
        color: color,
        pure: pure,
        material: material,
        motion: motion,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.appAppearanceSaveError)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _chooseColor() async {
    var color = widget.controller.accent;
    final picked = await showDialog<Color>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) {
          final l = context.l10n;
          final components = [color.r, color.g, color.b];
          return AlertDialog(
            title: Text(l.appAccent),
            content: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    for (var index = 0; index < 3; index++) ...[
                      const SizedBox(height: 12),
                      Text(
                        [l.appColorRed, l.appColorGreen, l.appColorBlue][index],
                      ),
                      Slider(
                        value: components[index],
                        min: 0,
                        max: 1,
                        label: (components[index] * 255).round().toString(),
                        onChanged: (value) => update(() {
                          final values = [...components]..[index] = value;
                          color = Color.from(
                            alpha: 1,
                            red: values[0],
                            green: values[1],
                            blue: values[2],
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, color),
                child: Text(l.commonConfirm),
              ),
            ],
          );
        },
      ),
    );
    if (picked != null && mounted) await _save(color: picked);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final l = context.l10n, c = widget.controller;
      return ApprovedPage(
        title: l.appAppearance,
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.appAppearanceContext,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  ApprovedSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<ThemeMode>(
                          key: ValueKey('appearance-${c.mode.name}'),
                          initialValue: c.mode,
                          isExpanded: true,
                          itemHeight: null,
                          decoration: InputDecoration(
                            labelText: l.appAppearance,
                          ),
                          items: [
                            for (final mode in ThemeMode.values)
                              DropdownMenuItem(
                                value: mode,
                                child: Text(switch (mode) {
                                  ThemeMode.system => l.appFollowDevice,
                                  ThemeMode.light => l.appLight,
                                  ThemeMode.dark => l.appDark,
                                }),
                              ),
                          ],
                          onChanged: _saving
                              ? null
                              : (value) => _save(theme: value),
                        ),
                        const SizedBox(height: 20),
                        Text(l.appAccent),
                        const SizedBox(height: 9),
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _chooseColor,
                          icon: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: c.accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                          label: Text(l.appChooseColor),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          l.appAccentHelp,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<bool>(
                          key: ValueKey('appearance-pure-${c.pureBackground}'),
                          initialValue: c.pureBackground,
                          isExpanded: true,
                          itemHeight: null,
                          decoration: InputDecoration(
                            labelText: l.appBackground,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: false,
                              child: Text(l.appSoftBackground),
                            ),
                            DropdownMenuItem(
                              value: true,
                              child: Text(l.appPureBackground),
                            ),
                          ],
                          onChanged: _saving
                              ? null
                              : (value) => _save(pure: value),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<AppMaterialMode>(
                          key: ValueKey('appearance-mat-${c.material.name}'),
                          initialValue: c.material,
                          isExpanded: true,
                          itemHeight: null,
                          decoration: const InputDecoration(
                            labelText: 'Material',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: AppMaterialMode.glass,
                              child: Text('Vidro fosco (efeito suave)'),
                            ),
                            DropdownMenuItem(
                              value: AppMaterialMode.solid,
                              child: Text('Sólido (opaco)'),
                            ),
                          ],
                          onChanged: _saving
                              ? null
                              : (value) => _save(material: value),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<AppMotionMode>(
                          key: ValueKey('appearance-mot-${c.motion.name}'),
                          initialValue: c.motion,
                          isExpanded: true,
                          itemHeight: null,
                          decoration: const InputDecoration(
                            labelText: 'Movimento',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: AppMotionMode.standard,
                              child: Text('Padrão (animações ativas)'),
                            ),
                            DropdownMenuItem(
                              value: AppMotionMode.reduced,
                              child: Text('Reduzido (sem transições)'),
                            ),
                          ],
                          onChanged: _saving
                              ? null
                              : (value) => _save(motion: value),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
