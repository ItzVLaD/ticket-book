import 'package:flutter/material.dart';
import 'package:tickets_booking/models/event.dart';
import 'package:tickets_booking/models/event_group.dart';
import '../services/ticketmaster_service.dart';

class EventsProvider extends ChangeNotifier {
  final TicketmasterService _service = TicketmasterService();

  List<Event> _events = [];
  List<EventGroup> _groups = [];
  String? _lastKeyword;

  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  List<Event> get events => _events;
  List<EventGroup> get groupedEvents => _groups;

  /// Returns only current (non-expired) events
  List<Event> get currentEvents => _events.where((event) => event.isCurrent).toList();

  /// Returns only event groups that have at least one current event
  List<EventGroup> get currentGroupedEvents =>
      _groups.where((group) => group.hasCurrentEvents).toList();

  /// Returns one representative event from each group except the provided one.
  List<Event> similarEventsFor(EventGroup group) {
    return _groups
        .where((g) => g.id != group.id && g.hasCurrentEvents)
        .map((g) => g.currentSchedules.first) // Take only the first event from each group
        .toList();
  }

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  Future<void> loadEvents({String keyword = 'concert'}) async {
    // Avoid unnecessary API calls for same keyword
    if (_lastKeyword == keyword && _events.isNotEmpty && !_hasError) {
      return;
    }

    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      final raw = await _service.fetchEvents(keyword: keyword);
      _events = raw;
      _groups = _service.groupEvents(raw);
      _lastKeyword = keyword;
      _hasError = false;
    } catch (e) {
      debugPrint('EventsProvider error: $e');
      _hasError = true;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      // Keep previous data if available
      if (_events.isEmpty) {
        _events = [];
        _groups = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Force refresh data
  Future<void> refresh({String keyword = 'concert'}) async {
    _lastKeyword = null; // Force reload
    await loadEvents(keyword: keyword);
  }

  /// Clear all data
  void clear() {
    _events = [];
    _groups = [];
    _lastKeyword = null;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }
}
