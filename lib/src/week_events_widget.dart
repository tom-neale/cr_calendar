import 'package:cr_calendar/src/contract.dart';
import 'package:cr_calendar/src/customization/builders.dart';
import 'package:cr_calendar/src/models/drawers.dart';
import 'package:flutter/material.dart';

/// Callback fired when the pointer enters or leaves an event bar.
/// [id] is the [CalendarEventModel.id] that was supplied for the hovered
/// event, or null when the pointer has left any bar.
typedef EventHoverCallback = void Function(String? id);

class WeekEventsWidget extends StatelessWidget {
  WeekEventsWidget({
    required this.itemHeight,
    required this.itemWidth,
    required this.eventLines,
    required this.lineHeight,
    this.topPadding = 0,
    this.bottomPadding = 0,
    this.row = 0,
    this.eventBuilder,
    this.onEventHover,
    EdgeInsets? padding,
    super.key,
  }) {
    this.padding = padding ?? EdgeInsets.zero;
  }

  final double lineHeight;
  final double itemHeight;
  final double itemWidth;
  final double topPadding;

  /// Vertical padding reserved at the bottom of each cell — bars never
  /// extend into this region, so a host can paint custom content there
  /// (e.g. an overflow indicator chip) without the events overlay
  /// covering it.
  final double bottomPadding;

  final int row;
  final List<EventsLineDrawer> eventLines;
  late final EdgeInsets padding;
  final EventBuilder? eventBuilder;

  /// Optional pointer-hover callback. Host apps can use this to
  /// cross-highlight external UI (e.g. a trip pill in a detail panel)
  /// when the user hovers over a bar.
  final EventHoverCallback? onEventHover;

  @override
  Widget build(BuildContext context) {
    // The container keeps its full per-week height (itemHeight -
    // topPadding) so each week's allocation in the ListView still
    // aligns with the day-cell grid below. bottomPadding reduces only
    // the LINE height (in EventsOverlay), so bars stop short of the
    // cell bottom by the reserved amount, leaving the bottom strip
    // empty for the host's overflow indicator.
    return Container(
      margin: EdgeInsets.only(top: topPadding),
      height: itemHeight - topPadding,
      child: Stack(
        children: _makePositionedEvents(),
      ),
    );
  }

  ///Draw events
  List<Widget> _makePositionedEvents() {
    final widgets = <Widget>[];
    for (var i = 0; i < eventLines.length; i++) {
      for (var j = 0; j < eventLines[i].events.length; j++) {
        final item = eventLines[i].events[j];
        final bar = Container(
          height:
              lineHeight - itemHeight / Contract.kDistanceBetweenEventsCoef,
          width: itemWidth * item.size() - Contract.kLinesPadding,
          child: eventBuilder != null
              ? eventBuilder?.call(item)
              : Container(
                  color: item.backgroundColor,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.fitHeight,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
        );
        widgets.add(
          Positioned(
            top: i * lineHeight,
            left: (item.begin - 1) * itemWidth + padding.left,
            right: (Contract.kWeekDaysCount - item.end) * itemWidth +
                padding.right,
            child: onEventHover == null
                ? bar
                : MouseRegion(
                    onEnter: (_) => onEventHover?.call(item.id),
                    onExit: (_) => onEventHover?.call(null),
                    child: bar,
                  ),
          ),
        );
      }
    }
    return widgets;
  }
}
