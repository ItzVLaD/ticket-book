import 'package:flutter/material.dart';

class SearchFilters {
  DateTimeRange? dateRange;
  List<String> genres;
  int? radius; // in km, null for any

  SearchFilters({this.dateRange, List<String>? genres, this.radius})
      : genres = genres ?? [];
}
