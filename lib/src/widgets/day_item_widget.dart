import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

///Represent day in calendar
class DayItemWidget extends StatelessWidget {
  const DayItemWidget({
    this.body,
    this.dayItemMargin,
    this.width,
    this.height,
    super.key,
  });

  final Widget? body;
  final EdgeInsets? dayItemMargin;
  final double? width;

  /// Optional explicit height. When supplied, the host's [body]
  /// receives tight vertical constraints equal to this value —
  /// required when the body uses a [LayoutBuilder] to read the real
  /// cellH (e.g. to compute bar geometry that matches cr_calendar's
  /// own events overlay sizing).
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: dayItemMargin,
      child: body,
    );
  }
}
