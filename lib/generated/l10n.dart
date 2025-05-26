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
  String get shareFeatureComingSoon => 'Share feature coming soon';
  String get ticketsLeft => 'tickets left';
  String get showLess => 'Show less';
  String get showMore => 'Show more';
  String get similarEvents => 'Similar events';
  String get bookTickets => 'Book tickets';
  String get selectQuantity => 'Select quantity';
  String get cancel => 'Cancel';
  String get confirm => 'Confirm';
  String bookingSuccess(String name) => 'Successfully booked tickets for $name';
  String get yourBookings => 'Your bookings';
  String get theme => 'Theme';
  String get logout => 'Log out';
  String get wishlist => 'Wishlist';
  String get noBookings => 'No bookings yet';
  String get cancelBooking => 'Cancel booking?';
  String get confirmCancel => 'Are you sure you want to cancel?';
  String get no => 'No';
  String get yes => 'Yes';
}
