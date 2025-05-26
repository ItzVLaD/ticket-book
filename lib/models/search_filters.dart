import 'package:flutter/material.dart';

class SearchFilters {
  DateTimeRange? dateRange;
  RangeValues priceRange;
  List<String> genres;
  int? radius; // in km, null for any

  SearchFilters({this.dateRange, RangeValues? priceRange, List<String>? genres, this.radius})
    : priceRange = priceRange ?? const RangeValues(0, 1000),
      genres = genres ?? [];
}
