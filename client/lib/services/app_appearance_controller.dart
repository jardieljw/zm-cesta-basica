import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppMaterialMode { glass, solid }
enum AppMotionMode { standard, reduced }

/// Device preferences only. No company data, credentials or domain rules.
class AppAppearanceController extends ChangeNotifier {
  static const storageKey = 'zm.appearance.v1';
  ThemeMode mode = ThemeMode.system;
  Color accent = const Color(0xff2866ae);
  bool pureBackground = false;
  AppMaterialMode material = AppMaterialMode.glass;
  AppMotionMode motion = AppMotionMode.standard;
  bool _closed = false;
  int _generation = 0;
  Future<void> _writes = Future.value();

  Future<void> load() async {
    final generation = _generation;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw == null || _closed || generation != _generation) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      mode = ThemeMode.values.firstWhere(
        (m) => m.name == data['theme'],
        orElse: () => ThemeMode.system,
      );
      final value = data['accent'];
      if (value is int && value >= 0xff000000 && value <= 0xffffffff) {
        accent = Color(value);
      }
      pureBackground = data['pure'] == true;
      final mat = data['material'];
      if (mat is String) {
        material = AppMaterialMode.values.firstWhere(
          (m) => m.name == mat,
          orElse: () => AppMaterialMode.glass,
        );
      }
      final mot = data['motion'];
      if (mot is String) {
        motion = AppMotionMode.values.firstWhere(
          (m) => m.name == mot,
          orElse: () => AppMotionMode.standard,
        );
      }
      notifyListeners();
    } catch (_) {
      // Invalid/unavailable preferences leave the approved defaults intact.
    }
  }

  Future<void> save({
    ThemeMode? theme,
    Color? color,
    bool? pure,
    AppMaterialMode? material,
    AppMotionMode? motion,
  }) {
    _generation++;
    final operation = _writes.catchError((Object _) {}).then((_) async {
      final requested = jsonEncode({
        'theme': (theme ?? mode).name,
        'accent': (color ?? accent).toARGB32(),
        'pure': pure ?? pureBackground,
        'material': (material ?? this.material).name,
        'motion': (motion ?? this.motion).name,
      });
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(storageKey, requested)) {
        throw StateError('Appearance preference was not saved');
      }
      if (_closed) return;
      final data = jsonDecode(requested) as Map<String, dynamic>;
      mode = ThemeMode.values.firstWhere((m) => m.name == data['theme']);
      accent = Color(data['accent'] as int);
      pureBackground = data['pure'] as bool;
      if (data['material'] is String) {
        this.material = AppMaterialMode.values.firstWhere(
          (m) => m.name == data['material'],
          orElse: () => AppMaterialMode.glass,
        );
      }
      if (data['motion'] is String) {
        this.motion = AppMotionMode.values.firstWhere(
          (m) => m.name == data['motion'],
          orElse: () => AppMotionMode.standard,
        );
      }
      notifyListeners();
    });
    _writes = operation;
    return operation;
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}

class AppAppearanceScope extends InheritedNotifier<AppAppearanceController> {
  const AppAppearanceScope({
    super.key,
    required AppAppearanceController controller,
    required super.child,
  }) : super(notifier: controller);
  static AppAppearanceController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AppAppearanceScope>()
      ?.notifier;
}
