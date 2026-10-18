import 'package:flutter/material.dart';
import 'approved_icon_paths.dart';

/// Same 24-unit strokes and vectors as the approved reference, painted natively.
class ApprovedIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  const ApprovedIcon(this.name, {super.key, this.size = 20, this.color});
  @override
  Widget build(BuildContext context) => Center(
    widthFactor: 1,
    heightFactor: 1,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _ApprovedIconPainter(
          name,
          color ??
              IconTheme.of(context).color ??
              Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ),
  );
}

Widget approvedRoleIcon(IconData role, {double size = 20, Color? color}) {
  final roles = <IconData, String>{
    Icons.home_outlined: 'house',
    Icons.account_balance_wallet_outlined: 'wallet',
    Icons.shopping_bag_outlined: 'shopping-bag',
    Icons.inventory_2_outlined: 'package',
    Icons.manage_search_outlined: 'package-search',
    Icons.more_horiz: 'ellipsis',
    Icons.event_outlined: 'calendar-clock',
    Icons.local_shipping_outlined: 'truck',
    Icons.shopping_basket_outlined: 'shopping-basket',
    Icons.history: 'history',
    Icons.bar_chart: 'chart-no-axes-combined',
    Icons.print_outlined: 'printer',
    Icons.settings_outlined: 'settings',
    Icons.backup_outlined: 'database-backup',
    Icons.folder_copy_outlined: 'files',
    Icons.account_balance_outlined: 'landmark',
  };
  final name = roles[role];
  return name == null
      ? Icon(role, size: size, color: color)
      : ApprovedIcon(name, size: size, color: color);
}

class _ApprovedIconPainter extends CustomPainter {
  final String name;
  final Color color;
  const _ApprovedIconPainter(this.name, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final path in approvedIconPaths[name] ?? const <Path>[]) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ApprovedIconPainter oldDelegate) =>
      oldDelegate.name != name || oldDelegate.color != color;
}
