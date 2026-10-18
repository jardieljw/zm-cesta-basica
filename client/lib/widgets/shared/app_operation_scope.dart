import 'package:flutter/widgets.dart';

/// Keeps the area navigation still while a reviewed financial request is in
/// flight. Server coordinators remain responsible for replay and idempotency.
class AppOperationLock extends ChangeNotifier {
  final Set<Object> _owners = {};
  bool _closed = false;
  bool get locked => _owners.isNotEmpty;
  void setActive(Object owner, bool active) {
    if (_closed) return;
    final wasLocked = locked;
    if (active) {
      _owners.add(owner);
    } else {
      _owners.remove(owner);
    }
    if (locked != wasLocked) notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    _owners.clear();
    super.dispose();
  }
}

class AppOperationScope extends InheritedWidget {
  final AppOperationLock lock;
  const AppOperationScope({
    super.key,
    required this.lock,
    required super.child,
  });
  static AppOperationLock? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppOperationScope>()?.lock;
  @override
  bool updateShouldNotify(AppOperationScope oldWidget) =>
      oldWidget.lock != lock;
}
