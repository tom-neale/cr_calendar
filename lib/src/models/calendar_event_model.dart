import 'package:flutter/material.dart';

final class CalendarEventModel {
  CalendarEventModel({
    required this.name,
    required this.begin,
    required this.end,
    this.eventColor = Colors.green,
    this.id,
  });

  String name;
  DateTime begin;
  DateTime end;
  Color eventColor;

  /// Optional stable identifier for the event. When provided, it is
  /// threaded through to the event builder via [EventProperties.id] and
  /// surfaced in hover callbacks, allowing host apps to cross-highlight
  /// this event from external UI (e.g. a trip pill in a detail panel).
  String? id;
}
