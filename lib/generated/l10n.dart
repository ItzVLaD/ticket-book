import 'package:flutter/widgets.dart';

class S {
  static S of(BuildContext context) => S();

  String get noEventsFound => 'No events found';
  String get errorLoadingEvents => 'Error loading events';
}