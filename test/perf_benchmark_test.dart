// Microbenchmark for cr_calendar event-layout hot paths.
//
// Run with:   flutter test test/perf_benchmark_test.dart
//
// Reports wall time for placeEventsToLines, resolveEventDrawersForWeek,
// and calculateAvailableEventsForDate across a realistic event-volume
// sweep (50/100/200 events). Each measurement is the median of a warm
// loop after discarding warm-up iterations, so results stabilize even on
// a noisy laptop.
import 'package:cr_calendar/cr_calendar.dart';
import 'package:cr_calendar/src/extensions/datetime_ext.dart';
import 'package:cr_calendar/src/utils/event_utils.dart';
import 'package:flutter_test/flutter_test.dart';

List<CalendarEventModel> _generateEvents(int count, {int seed = 42}) {
  // Deterministic LCG so reruns hit identical event sets.
  var state = seed;
  int next(int max) {
    state = (state * 1103515245 + 12345) & 0x7fffffff;
    return state % max;
  }

  final base = DateTime.utc(2026, 1, 1);
  return List.generate(count, (i) {
    final startOffset = next(365);
    final duration = next(28) + 1;
    final begin = base.add(Duration(days: startOffset));
    final end = begin.add(Duration(days: duration));
    return CalendarEventModel(
      name: 'event_$i',
      begin: begin,
      end: end,
      id: 'id_$i',
    );
  });
}

Duration _median(List<Duration> samples) {
  final sorted = [...samples]..sort();
  return sorted[sorted.length ~/ 2];
}

({Duration median, Duration min, Duration max}) _benchmark(
  String label,
  void Function() body, {
  int warmup = 50,
  int iterations = 200,
}) {
  for (var i = 0; i < warmup; i++) {
    body();
  }
  final samples = <Duration>[];
  for (var i = 0; i < iterations; i++) {
    final sw = Stopwatch()..start();
    body();
    sw.stop();
    samples.add(sw.elapsed);
  }
  final med = _median(samples);
  final min = samples.reduce((a, b) => a < b ? a : b);
  final max = samples.reduce((a, b) => a > b ? a : b);
  // ignore: avoid_print
  print(
    '$label: median=${med.inMicroseconds}us '
    'min=${min.inMicroseconds}us max=${max.inMicroseconds}us '
    '(n=$iterations)',
  );
  return (median: med, min: min, max: max);
}

void main() {
  group('cr_calendar perf', () {
    for (final size in [50, 100, 200]) {
      test('event_utils @ $size events', () {
        final events = _generateEvents(size);
        final monthStart = DateTime.utc(2026, 3, 1).toJiffy();

        _benchmark(
          'resolveEventDrawersForWeek(${size}ev,6wk)',
          () {
            // Mirror MonthItem._calculateWeeks: precompute once per
            // render, reuse across weeks.
            final precomputed = precomputeEventBounds(events);
            for (var week = 0; week < 6; week++) {
              resolveEventDrawersForWeek(week, monthStart, precomputed);
            }
          },
        );

        // Realistic per-week drawer count — pre-build once outside the
        // hot loop so we measure placeEventsToLines in isolation.
        final precomputedForWeeks = precomputeEventBounds(events);
        final weekDrawers = [
          for (var w = 0; w < 6; w++)
            resolveEventDrawersForWeek(w, monthStart, precomputedForWeeks),
        ];
        _benchmark(
          'placeEventsToLines(${size}ev,6wk,maxLines=4)',
          () {
            for (final drawers in weekDrawers) {
              placeEventsToLines(drawers, 4);
            }
          },
        );

        final probeDate = DateTime.utc(2026, 4, 15).toJiffy();
        _benchmark(
          'calculateAvailableEventsForDate(${size}ev)',
          () {
            calculateAvailableEventsForDate(events, probeDate);
          },
        );
      });
    }
  });
}
