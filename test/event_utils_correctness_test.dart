// Verify event_utils refactor preserves the original behavior for the
// schengen-calculator usage shape: realistic events spanning weeks,
// month-week resolution, and point-in-time day membership.
import 'package:cr_calendar/cr_calendar.dart';
import 'package:cr_calendar/src/extensions/datetime_ext.dart';
import 'package:cr_calendar/src/utils/event_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateAvailableEventsForDate', () {
    test('includes events whose range covers the probe date', () {
      final events = [
        CalendarEventModel(
          name: 'covers',
          begin: DateTime.utc(2026, 3, 1),
          end: DateTime.utc(2026, 3, 10),
        ),
        CalendarEventModel(
          name: 'before',
          begin: DateTime.utc(2026, 2, 1),
          end: DateTime.utc(2026, 2, 5),
        ),
        CalendarEventModel(
          name: 'after',
          begin: DateTime.utc(2026, 4, 1),
          end: DateTime.utc(2026, 4, 5),
        ),
        CalendarEventModel(
          name: 'edge_begin',
          begin: DateTime.utc(2026, 3, 5),
          end: DateTime.utc(2026, 3, 5),
        ),
        CalendarEventModel(
          name: 'edge_end',
          begin: DateTime.utc(2026, 3, 5),
          end: DateTime.utc(2026, 3, 7),
        ),
      ];
      final result = calculateAvailableEventsForDate(
        events,
        DateTime.utc(2026, 3, 5).toJiffy(),
      );
      expect(
        result.map((e) => e.name).toList(),
        unorderedEquals(['covers', 'edge_begin', 'edge_end']),
      );
    });

    test('inclusive on both ends', () {
      final event = CalendarEventModel(
        name: 'e',
        begin: DateTime.utc(2026, 3, 5),
        end: DateTime.utc(2026, 3, 7),
      );
      // Day before begin → excluded.
      expect(
        calculateAvailableEventsForDate(
          [event],
          DateTime.utc(2026, 3, 4).toJiffy(),
        ),
        isEmpty,
      );
      // Begin day → included.
      expect(
        calculateAvailableEventsForDate(
          [event],
          DateTime.utc(2026, 3, 5).toJiffy(),
        ),
        hasLength(1),
      );
      // End day → included.
      expect(
        calculateAvailableEventsForDate(
          [event],
          DateTime.utc(2026, 3, 7).toJiffy(),
        ),
        hasLength(1),
      );
      // Day after end → excluded.
      expect(
        calculateAvailableEventsForDate(
          [event],
          DateTime.utc(2026, 3, 8).toJiffy(),
        ),
        isEmpty,
      );
    });
  });

  group('calculateAvailableEventsForRange', () {
    test('any-overlap semantics: event begin, event end, or range inside', () {
      final events = [
        CalendarEventModel(
          name: 'event_begin_in_range',
          begin: DateTime.utc(2026, 3, 5),
          end: DateTime.utc(2026, 3, 15),
        ),
        CalendarEventModel(
          name: 'event_end_in_range',
          begin: DateTime.utc(2026, 2, 25),
          end: DateTime.utc(2026, 3, 3),
        ),
        CalendarEventModel(
          name: 'event_envelops_range',
          begin: DateTime.utc(2026, 2, 1),
          end: DateTime.utc(2026, 4, 1),
        ),
        CalendarEventModel(
          name: 'event_disjoint',
          begin: DateTime.utc(2026, 5, 1),
          end: DateTime.utc(2026, 5, 5),
        ),
      ];
      final result = calculateAvailableEventsForRange(
        events,
        DateTime.utc(2026, 3, 1).toJiffy(),
        DateTime.utc(2026, 3, 7).toJiffy(),
      );
      expect(
        result.map((e) => e.name).toList(),
        unorderedEquals([
          'event_begin_in_range',
          'event_end_in_range',
          'event_envelops_range',
        ]),
      );
    });
  });

  group('resolveEventDrawersForWeek with precomputed bounds', () {
    test('matches per-week filtering for events that overlap', () {
      // Month of March 2026 starts on a Sunday. Use Sunday-start week.
      final monthStart = DateTime.utc(2026, 3, 1).toJiffy();
      final events = [
        // Week 0: 2026-03-01 .. 2026-03-07
        CalendarEventModel(
          name: 'wk0_full',
          begin: DateTime.utc(2026, 3, 1),
          end: DateTime.utc(2026, 3, 7),
        ),
        // Week 1: 2026-03-08 .. 2026-03-14
        CalendarEventModel(
          name: 'wk1_mid',
          begin: DateTime.utc(2026, 3, 10),
          end: DateTime.utc(2026, 3, 12),
        ),
        // Spans wk0..wk1
        CalendarEventModel(
          name: 'spans_wk0_wk1',
          begin: DateTime.utc(2026, 3, 5),
          end: DateTime.utc(2026, 3, 12),
        ),
        // Outside month entirely
        CalendarEventModel(
          name: 'far_future',
          begin: DateTime.utc(2026, 6, 1),
          end: DateTime.utc(2026, 6, 5),
        ),
      ];
      final precomputed = precomputeEventBounds(events);
      final wk0 = resolveEventDrawersForWeek(0, monthStart, precomputed);
      final wk1 = resolveEventDrawersForWeek(1, monthStart, precomputed);
      final wk5 = resolveEventDrawersForWeek(5, monthStart, precomputed);

      expect(wk0.map((d) => d.name), unorderedEquals(['wk0_full', 'spans_wk0_wk1']));
      expect(wk1.map((d) => d.name), unorderedEquals(['wk1_mid', 'spans_wk0_wk1']));
      expect(wk5, isEmpty);
    });
  });
}
