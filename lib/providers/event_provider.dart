import 'package:flutter/material.dart';
import 'package:tickets_booking/models/event.dart';
import '../services/ticketmaster_service.dart';

class EventsProvider extends ChangeNotifier {
  final TicketmasterService _service = TicketmasterService();

  List<Event> _events = [];
  bool _isLoading = false;
  bool _hasError = false;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  Future<void> loadEvents({String keyword = 'concert'}) async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      _events = await _service.fetchEvents(keyword: keyword);
    } catch (e) {
      // TODO: report error to logging/analytics
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
