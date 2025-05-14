import 'package:flutter/material.dart';
import '../services/ticketmaster_service.dart';

class EventsProvider extends ChangeNotifier {
  final TicketmasterService _service = TicketmasterService();

  List<Event> _events = [];
  bool _isLoading = false;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;

  Future<void> loadEvents({String keyword = 'concert'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _events = await _service.fetchEvents(keyword: keyword);
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
