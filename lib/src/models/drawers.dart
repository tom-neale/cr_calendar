import 'dart:ui';

import 'package:cr_calendar/cr_calendar.dart';
import 'package:flutter/material.dart';

final class WeekDrawer {
  WeekDrawer(this.lines) : activeLines = _countActiveLines(lines);

  List<EventsLineDrawer> lines;

  /// Highest non-empty track index + 1. placeEventsToLines packs greedily
  /// from track 0 upward, so an empty intermediate track never occurs and
  /// this is equivalent to a count of non-empty entries. Precomputed at
  /// build time so EventsOverlay doesn't recount on every frame.
  final int activeLines;

  static int _countActiveLines(List<EventsLineDrawer> lines) {
    var active = 0;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].events.isNotEmpty) {
        active = i + 1;
      }
    }
    return active;
  }
}

final class EventsLineDrawer {
  List<EventProperties> events = []; // max 7
}

/// Event widget properties used in [EventBuilder].
final class EventProperties {
  EventProperties({
    required this.begin,
    required this.end,
    required this.name,
    required this.backgroundColor,
    this.id,
  });

  /// Begin day number.
  int begin; // min 1 / max 7
  /// End day number.
  int end; // min 1 / max 7
  /// Background color.
  Color backgroundColor;

  /// Name displayed at start of the event widget.
  String name;

  /// Optional stable identifier, forwarded from [CalendarEventModel.id].
  /// Null for events that weren't given an id.
  String? id;

  int size() => end - begin + 1;
}
