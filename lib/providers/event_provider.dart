import 'package:flutter/material.dart';
import 'package:tickets_booking/models/event.dart';
import 'package:tickets_booking/models/event_group.dart';
import '../services/ticketmaster_service.dart';

class EventsProvider extends ChangeNotifier {
  final TicketmasterService _service = TicketmasterService();

  List<Event> _events = [];
  List<EventGroup> _groups = [];

  bool _isLoading = false;
  bool _hasError = false;

  List<Event> get events => _events;
  List<EventGroup> get groupedEvents => _groups;

  /// Returns a flat list of events from all groups except the provided one.
  List<Event> similarEventsFor(EventGroup group) {
    return _groups.where((g) => g.id != group.id).expand((g) => g.schedules).toList();
  }

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  Future<void> loadEvents({String keyword = 'concert'}) async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final raw = await _service.fetchEvents(keyword: keyword);
      _events = raw;
      _groups = _service.groupEvents(raw);
      _hasError = false;
    } catch (e) {
      // TODO: report error to logging/analytics
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
