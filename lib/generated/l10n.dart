import 'package:flutter/widgets.dart';

class S {
  static S of(BuildContext context) => S();

  String get noEventsFound => 'No events found';
  String get errorLoadingEvents => 'Error loading events';
  String get searchHint => 'Search events';
  String get noResultsFound => 'No results match your filters';
  String get filters => 'Filters';
  String get dateRange => 'Date Range';
  String get from => 'From';
  String get selectDate => 'Select date';
  String get priceRange => 'Price Range';
  String get genres => 'Genres';
  String get radius => 'Radius';
  String get any => 'Any';
  String get apply => 'Apply';
}