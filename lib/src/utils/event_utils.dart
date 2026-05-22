import 'package:cr_calendar/src/contract.dart';
import 'package:cr_calendar/src/cr_calendar.dart';
import 'package:cr_calendar/src/extensions/datetime_ext.dart';
import 'package:cr_calendar/src/models/calendar_event_model.dart';
import 'package:cr_calendar/src/models/drawers.dart';
import 'package:cr_calendar/src/models/event_count_keeper.dart';
import 'package:jiffy/jiffy.dart';

/// Event with its begin/end normalized to UTC midnight. Materialized
/// once per render so per-week / per-day queries can compare raw
/// DateTimes instead of rebuilding Jiffy instances per event.
class PrecomputedEventBounds {
  PrecomputedEventBounds(this.event)
      : beginUtc = DateTime.utc(
          event.begin.year,
          event.begin.month,
          event.begin.day,
        ),
        endUtc = DateTime.utc(
          event.end.year,
          event.end.month,
          event.end.day,
        );

  final CalendarEventModel event;
  final DateTime beginUtc;
  final DateTime endUtc;
}

/// Materialize UTC-midnight bounds for every event. Call once per
/// render — subsequent week/day queries operate on the precomputed
/// list and skip per-event DateTime/Jiffy construction.
List<PrecomputedEventBounds> precomputeEventBounds(
    List<CalendarEventModel> events) {
  return [for (final e in events) PrecomputedEventBounds(e)];
}

///Returns list of events for [date]
List<CalendarEventModel> calculateAvailableEventsForDate(
    List<CalendarEventModel> events, Jiffy date) {
  final dateUtc = DateTime.utc(date.year, date.month, date.date);
  final eventsHappen = <CalendarEventModel>[];
  for (final event in events) {
    final beginUtc =
        DateTime.utc(event.begin.year, event.begin.month, event.begin.day);
    final endUtc =
        DateTime.utc(event.end.year, event.end.month, event.end.day);
    if (!dateUtc.isBefore(beginUtc) && !dateUtc.isAfter(endUtc)) {
      eventsHappen.add(event);
    }
  }
  return eventsHappen;
}

List<CalendarEventModel> calculateAvailableEventsForRange(
    List<CalendarEventModel> events, Jiffy? start, Jiffy? end) {
  final startUtc =
      start == null ? null : DateTime.utc(start.year, start.month, start.date);
  final endUtc =
      end == null ? null : DateTime.utc(end.year, end.month, end.date);

  final eventsHappen = <CalendarEventModel>[];
  for (final event in events) {
    final beginUtc =
        DateTime.utc(event.begin.year, event.begin.month, event.begin.day);
    final eEndUtc =
        DateTime.utc(event.end.year, event.end.month, event.end.day);

    final eventBeginInRange = _isInRange(beginUtc, startUtc, endUtc);
    final eventEndInRange = _isInRange(eEndUtc, startUtc, endUtc);
    final startInsideEvent =
        startUtc != null && _isInRange(startUtc, beginUtc, eEndUtc);
    final endInsideEvent =
        endUtc != null && _isInRange(endUtc, beginUtc, eEndUtc);

    if (eventBeginInRange ||
        eventEndInRange ||
        startInsideEvent ||
        endInsideEvent) {
      eventsHappen.add(event);
    }
  }
  return eventsHappen;
}

bool _isInRange(DateTime probe, DateTime? lower, DateTime? upper) {
  if (lower != null && probe.isBefore(lower)) {
    return false;
  }
  if (upper != null && probe.isAfter(upper)) {
    return false;
  }
  return true;
}

/// Returns drawers for [week]. Operates on precomputed UTC-midnight
/// event bounds so per-week resolution skips DateTime/Jiffy
/// reconstruction.
List<EventProperties> resolveEventDrawersForWeek(
    int week,
    Jiffy monthStart,
    List<PrecomputedEventBounds> events,
    ) {
  final beginDate = Jiffy.parseFromJiffy(monthStart).add(weeks: week);
  final endDate =
      Jiffy.parseFromJiffy(beginDate).add(days: Contract.kWeekDaysCount - 1);

  // Week boundary in UTC midnight, used for raw-DateTime overlap test.
  final weekBeginUtc =
      DateTime.utc(beginDate.year, beginDate.month, beginDate.date);
  final weekEndUtc = DateTime.utc(endDate.year, endDate.month, endDate.date);

  final drawers = <EventProperties>[];
  for (final p in events) {
    if (p.endUtc.isBefore(weekBeginUtc) || p.beginUtc.isAfter(weekEndUtc)) {
      continue;
    }
    drawers.add(_mapEventToDrawer(p, beginDate, endDate));
  }
  return drawers;
}

EventProperties _mapEventToDrawer(
    PrecomputedEventBounds p, Jiffy begin, Jiffy end) {
  final jBegin = p.beginUtc.toJiffy();
  final jEnd = p.endUtc.toJiffy();

  var beginDay = 1;
  if (jBegin.isSameOrAfter(begin)) {
    beginDay = (begin.dayOfWeek - jBegin.dayOfWeek < 1)
        ? 1 - (begin.dayOfWeek - jBegin.dayOfWeek)
        : 1 - (begin.dayOfWeek - jBegin.dayOfWeek) + WeekDay.values.length;
  }

  var endDay = Contract.kWeekDaysCount;
  if (jEnd.isSameOrBefore(end)) {
    endDay = (begin.dayOfWeek - jEnd.dayOfWeek < 1)
        ? 1 - (begin.dayOfWeek - jEnd.dayOfWeek)
        : 1 - (begin.dayOfWeek - jEnd.dayOfWeek) + WeekDay.values.length;
  }

  return EventProperties(
      begin: beginDay,
      end: endDay,
      name: p.event.name,
      backgroundColor: p.event.eventColor,
      id: p.event.id);
}

/// Map EventDrawers to EventsLineDrawer and sort them by duration on current week
List<EventsLineDrawer> placeEventsToLines(
    List<EventProperties> events, int maxLines) {
  final copy = <EventProperties>[...events]
    ..sort((a, b) => b.size().compareTo(a.size()));

  final lines = List.generate(maxLines, (index) {
    final lineDrawer = EventsLineDrawer();
    for (var day = 1; day <= Contract.kWeekDaysCount; day++) {
      final candidates = <EventProperties>[];
      copy.forEach((e) {
        if (day == e.begin) {
          candidates.add(e);
        }
      });
      candidates.sort((a, b) => b.size().compareTo(a.size()));
      if (candidates.isNotEmpty) {
        lineDrawer.events.add(candidates.first);
        copy.remove(candidates.first);
        day += candidates.first.size() - 1;
      }
    }
    return lineDrawer;
  });
  return lines;
}

///Return list of not fitted events
List<NotFittedWeekEventCount> calculateOverflowedEvents(
    List<List<EventProperties>> monthEvents, int maxLines) {
  final weeks = <NotFittedWeekEventCount>[];
  for (final week in monthEvents) {
    var countList = List.filled(WeekDay.values.length, 0);

    for (final event in week) {
      for (var i = event.begin - 1; i < event.end; i++) {
        countList[i]++;
      }
    }
    countList = countList.map((count) {
      final notFitCount = count - maxLines;
      return notFitCount <= 0 ? 0 : notFitCount;
    }).toList();
    weeks.add(NotFittedWeekEventCount(countList));
  }
  return weeks;
}
