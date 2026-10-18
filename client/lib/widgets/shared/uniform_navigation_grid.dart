import 'dart:math' as math;
import 'package:flutter/material.dart';

class NavigationCardItem {
  const NavigationCardItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final MaterialColor color;
  final VoidCallback onTap;
}

class NavigationCardSection {
  const NavigationCardSection({required this.title, required this.items});
  final String title;
  final List<NavigationCardItem> items;
}

/// Measures every label at the current width and text scale so all sections
/// share one card size, including sections with an unpaired last item.
class UniformNavigationGrid extends StatelessWidget {
  const UniformNavigationGrid({super.key, required this.sections});
  final List<NavigationCardSection> sections;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const gap = 16.0;
      final columns = box.maxWidth >= 280 ? 2 : 1;
      final width = (box.maxWidth - gap * (columns - 1)) / columns;
      final textWidth = math.max(1.0, width - 40);
      final inherited = DefaultTextStyle.of(context).style;
      final titleStyle = inherited.merge(
        const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      );
      final descriptionStyle = inherited.merge(
        TextStyle(
          color: Colors.black54,
          fontSize: 13,
          fontWeight: MediaQuery.boldTextOf(context) ? FontWeight.bold : null,
        ),
      );
      final scaler = MediaQuery.textScalerOf(context);
      final direction = Directionality.of(context);
      final locale = Localizations.maybeLocaleOf(context);

      double textHeight(String text, TextStyle style) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: direction,
          textScaler: scaler,
          locale: locale,
        )..layout(maxWidth: textWidth);
        final height = painter.height.ceilToDouble();
        painter.dispose();
        return height;
      }

      var titleHeight = 0.0;
      var descriptionHeight = 0.0;
      for (final section in sections) {
        for (final item in section.items) {
          titleHeight = math.max(
            titleHeight,
            textHeight(item.title, titleStyle),
          );
          descriptionHeight = math.max(
            descriptionHeight,
            textHeight(item.description, descriptionStyle),
          );
        }
      }
      final height = 40 + 48 + 16 + titleHeight + 4 + descriptionHeight;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (
            var sectionIndex = 0;
            sectionIndex < sections.length;
            sectionIndex++
          ) ...[
            if (sectionIndex > 0) const SizedBox(height: 24),
            Text(
              sections[sectionIndex].title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final item in sections[sectionIndex].items)
                  SizedBox(
                    width: width,
                    height: height,
                    child: Card(
                      margin: EdgeInsets.zero,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: item.onTap,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: item.color.shade100,
                                child: Icon(
                                  item.icon,
                                  color: item.color.shade800,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: titleHeight,
                                child: Text(item.title, style: titleStyle),
                              ),
                              const SizedBox(height: 4),
                              Text(item.description, style: descriptionStyle),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      );
    },
  );
}
