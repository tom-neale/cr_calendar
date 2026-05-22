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
    this.defaultBottomPadding = 0,
    this.bottomPaddingBuilder,
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

  /// Bottom padding to apply when [bottomPaddingBuilder] is null. Bars
  /// stop short of the cell bottom by this amount on every week,
  /// leaving the bottom strip available for the host's overflow
  /// indicator.
  final double defaultBottomPadding;

  /// Per-week bottom padding. Called with the cell height and the
  /// active-line count for the week being rendered (the highest
  /// non-empty track index + 1, or 0 if the week has no events). When
  /// supplied, this takes precedence over [defaultBottomPadding] and
  /// lets the host vary the reserved bottom strip — typically to cap a
  /// lone-track bar at a fixed pixel height while keeping busy weeks
  /// at their natural full-cell allocation.
  final double Function(double itemHeight, int activeLines)?
      bottomPaddingBuilder;

  /// Global track cap. Drives event packing (events beyond this cap
  /// are dropped and reported as overflow); per-week bar height is
  /// derived from the actual occupied track count, not this value.
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
        final week = weekList[index];
        // Highest non-empty track index + 1. placeEventsToLines packs
        // greedily from track 0 upward, so an empty intermediate track
        // never occurs and this is equivalent to a count of non-empty
        // entries.
        var activeLines = 0;
        for (var i = 0; i < week.lines.length; i++) {
          if (week.lines[i].events.isNotEmpty) {
            activeLines = i + 1;
          }
        }
        // Empty weeks divide by 1 to dodge a div-by-zero; nothing is
        // rendered anyway so the chosen value is cosmetic.
        final divisor = activeLines == 0 ? 1 : activeLines;
        final bottomPadding =
            bottomPaddingBuilder?.call(itemHeight, activeLines) ??
                defaultBottomPadding;
        final lineHeight =
            (itemHeight - topPadding - bottomPadding) / divisor;

        return WeekEventsWidget(
          eventBuilder: eventBuilder,
          row: index,
          eventLines: week.lines,
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
