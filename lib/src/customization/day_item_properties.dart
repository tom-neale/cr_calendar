import 'package:cr_calendar/cr_calendar.dart';

/// Class with properties for building custom day item widget.
///
/// For making [CrCalendar] constructor more readable and smaller.
///
/// Used in [DayItemBuilder] typedef.
final class DayItemProperties {
  DayItemProperties({
    required this.dayNumber,
    required this.isInMonth,
    required this.isCurrentDay,
    required this.notFittedEventsCount,
    required this.isSelected,
    required this.isInRange,
    required this.isFirstInRange,
    required this.isLastInRange,
    required this.date,
    this.isInBand = false,
  });

  final int dayNumber;
  final bool isInMonth;
  final bool isCurrentDay;
  final int notFittedEventsCount;
  final bool isSelected;
  final bool isInRange;
  final bool isFirstInRange;
  final bool isLastInRange;
  final DateTime date;

  /// True when this day falls within the `bandRange` supplied to
  /// [CrCalendar]. Host apps can use this from [DayItemBuilder] to paint
  /// a subtle background tint across the range (e.g. a rolling-window
  /// highlight). Ignored when no `bandRange` is supplied — always false.
  final bool isInBand;
}
