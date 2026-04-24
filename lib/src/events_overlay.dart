import 'package:cr_calendar/src/customization/builders.dart';
import 'package:cr_calendar/src/models/drawers.dart';
import 'package:cr_calendar/src/week_events_widget.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';

/// Events layer
class EventsOverlay extends StatelessWidget {
  const EventsOverlay({
    required this.weekList,
    required this.begin,
    required this.itemWidth,
    required this.topPadding,
    required this.itemHeight,
    required this.maxLines,
    this.bottomPadding = 0,
    this.padding,
    this.eventBuilder,
    this.onEventHover,
    super.key,
  });

  final List<WeekDrawer> weekList;
  final Jiffy begin;
  final double itemWidth;
  final double itemHeight;
  final double topPadding;

  /// Vertical padding reserved at the bottom of each cell — bars never
  /// extend into this region, so a host can paint custom content there
  /// (e.g. an overflow indicator chip) without the events overlay
  /// covering it.
  final double bottomPadding;

  final int maxLines;
  final EdgeInsets? padding;
  final EventBuilder? eventBuilder;
  final EventHoverCallback? onEventHover;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: weekList.length,
      itemBuilder: (context, index) {
        final lineHeight =
            (itemHeight - topPadding - bottomPadding) / maxLines;

        return WeekEventsWidget(
          eventBuilder: eventBuilder,
          row: index,
          eventLines: weekList[index].lines,
          itemHeight: itemHeight,
          itemWidth: itemWidth,
          topPadding: topPadding,
          bottomPadding: bottomPadding,
          lineHeight: lineHeight,
          padding: padding,
          onEventHover: onEventHover,
        );
      },
    );
  }
}
