import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tickets_booking/models/search_filters.dart';
import 'package:tickets_booking/services/ticketmaster_service.dart';
import 'package:tickets_booking/models/event.dart';
import 'package:tickets_booking/models/event_group.dart';
import 'package:tickets_booking/widgets/event_card.dart';
import 'package:tickets_booking/widgets/skeleton_loader.dart';
import 'package:tickets_booking/generated/l10n.dart';
import 'package:tickets_booking/screens/event_detail_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (_) => SearchController(), child: const _SearchView());
  }
}

class SearchController extends ChangeNotifier {
  final TicketmasterService _service = TicketmasterService();
  final TextEditingController queryController = TextEditingController();
  SearchFilters filters = SearchFilters();
  List<Event> _rawResults = [];
  List<EventGroup> results = [];
  bool isLoading = false;
  bool hasError = false;
  bool hasMore = true;
  int _page = 0;
  Timer? _debounce;
  bool _disposed = false;

  SearchController() {
    queryController.addListener(_onQueryChanged);
    // Load default events on initialization
    _loadDefaultEvents();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_disposed) return;
      _page = 0;
      _rawResults.clear();
      results.clear();
      hasMore = true;
      _search();
    });
  }

  Future<void> _loadDefaultEvents() async {
    if (_disposed) return;
    isLoading = true;
    hasError = false;
    notifyListeners();

    try {
      // Load popular events by default (concerts, sports, theatre)
      final defaultEvents = await _service.fetchEvents(keyword: 'concert');
      if (_disposed) return;

      _rawResults = defaultEvents.where((event) => event.isCurrent).toList();
      results = _service.groupEvents(_rawResults);
      hasMore = false; // Default load doesn't support pagination
    } catch (e) {
      if (!_disposed) hasError = true;
    } finally {
      if (_disposed) return;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _search() async {
    if (_disposed || !hasMore) return;

    // If query is empty and no filters applied, show default events
    if (queryController.text.isEmpty && _isFiltersEmpty()) {
      await _loadDefaultEvents();
      return;
    }

    isLoading = true;
    hasError = false;
    notifyListeners();

    try {
      final pageKey = _page + 1;
      final pageResults = await _service.fetchEventsWithFilters(
        keyword: queryController.text.isEmpty ? null : queryController.text,
        filters: filters,
        page: pageKey,
      );
      if (_disposed) return;

      // Filter out expired events
      final currentEvents = pageResults.where((event) => event.isCurrent).toList();

      if (currentEvents.isEmpty) {
        hasMore = false;
      } else {
        _rawResults.addAll(currentEvents);
        // Group all results together for consistent grouping
        results = _service.groupEvents(_rawResults);
        _page = pageKey;
      }
    } catch (e) {
      if (!_disposed) hasError = true;
    } finally {
      if (_disposed) return;
      isLoading = false;
      notifyListeners();
    }
  }

  bool _isFiltersEmpty() {
    return filters.dateRange == null && filters.genres.isEmpty && filters.radius == null;
  }

  Future<void> refresh() async {
    _debounce?.cancel();
    _page = 0;
    _rawResults.clear();
    results.clear();
    hasMore = true;

    if (queryController.text.isEmpty && _isFiltersEmpty()) {
      await _loadDefaultEvents();
    } else {
      await _search();
    }
  }

  void updateFilters(SearchFilters newFilters) {
    filters = newFilters;
    _page = 0;
    _rawResults.clear();
    results.clear();
    hasMore = true;
    _search();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    queryController.removeListener(_onQueryChanged);
    queryController.dispose();
    super.dispose();
  }
}

class _SearchView extends StatelessWidget {
  const _SearchView();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SearchController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: TextField(
          controller: ctrl.queryController,
          decoration: InputDecoration(
            hintText: S.of(context).searchHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            fillColor: theme.colorScheme.surface,
            filled: true,
            prefixIcon: const Icon(Icons.search),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => ctrl.refresh(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: ctrl.refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notif) {
            if (notif.metrics.pixels >= notif.metrics.maxScrollExtent - 200 &&
                !ctrl.isLoading &&
                ctrl.hasMore &&
                ctrl.queryController.text.isNotEmpty) {
              ctrl._search(); // ignore: invalid_use_of_protected_member
            }
            return false;
          },
          child: CustomScrollView(
            slivers: [
              // Show default state message when no search query
              if (ctrl.queryController.text.isEmpty &&
                  ctrl._isFiltersEmpty() &&
                  !ctrl.isLoading &&
                  ctrl.results.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.explore, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Popular events near you',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < ctrl.results.length) {
                      final group = ctrl.results[index];
                      final event = group.schedules.first;
                      return EventCard(
                        event: event,
                        heroTagSuffix: 'search', // Add unique suffix for search screen
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => EventDetailScreen(
                                    event: event,
                                    eventGroup: group.schedules.length > 1 ? group : null,
                                  ),
                            ),
                          );
                        },
                      );
                    }
                    // loader at bottom
                    return ctrl.isLoading ? const SkeletonEventCard() : const SizedBox.shrink();
                  },
                  childCount:
                      ctrl.results.length +
                      (ctrl.hasMore && ctrl.queryController.text.isNotEmpty ? 1 : 0),
                ),
              ),

              if (!ctrl.isLoading &&
                  ctrl.results.isEmpty &&
                  (ctrl.queryController.text.isNotEmpty || !ctrl._isFiltersEmpty()))
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 64, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(S.of(context).noResultsFound, style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search terms or filters',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (ctrl.hasError)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                        const SizedBox(height: 16),
                        Text(S.of(context).errorLoadingEvents, style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: ctrl.refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newFilters = await showModalBottomSheet<SearchFilters>(
            context: context,
            isScrollControlled: true,
            builder:
                (_) => FractionallySizedBox(
                  heightFactor: 0.8,
                  child: _FilterSheet(initial: ctrl.filters),
                ),
          );
          if (newFilters != null) ctrl.updateFilters(newFilters);
        },
        child: const Icon(Icons.filter_list),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final SearchFilters initial;

  const _FilterSheet({required this.initial});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late DateTimeRange? _dateRange;
  late List<String> _genres;
  int? _radius;
  final _allGenres = ['Music', 'Sports', 'Arts & Theatre', 'Film', 'Miscellaneous'];
  final _radiusOptions = [null, 10, 25, 50, 100];

  @override
  void initState() {
    super.initState();
    _dateRange = widget.initial.dateRange;
    _genres = List.from(widget.initial.genres);
    _radius = widget.initial.radius;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(
                  S.of(context).filters,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range Filter
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                S.of(context).dateRange,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final range = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                  initialDateRange: _dateRange,
                                );
                                if (range != null) setState(() => _dateRange = range);
                              },
                              icon: const Icon(Icons.date_range),
                              label: Text(
                                _dateRange != null
                                    ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                                    : S.of(context).selectDate,
                              ),
                            ),
                          ),
                          if (_dateRange != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TextButton.icon(
                                onPressed: () => setState(() => _dateRange = null),
                                icon: const Icon(Icons.clear, size: 16),
                                label: const Text('Clear'),
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.colorScheme.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Genre Filter
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.category, size: 20, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                S.of(context).genres,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _allGenres.map((g) {
                                  final sel = _genres.contains(g);
                                  return FilterChip(
                                    label: Text(g),
                                    selected: sel,
                                    onSelected:
                                        (_) => setState(
                                          () => sel ? _genres.remove(g) : _genres.add(g),
                                        ),
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Radius Filter
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 20, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                S.of(context).radius,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: DropdownButtonFormField<int?>(
                              value: _radius,
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              items:
                                  _radiusOptions
                                      .map(
                                        (r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(r == null ? S.of(context).any : '$r km'),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) => setState(() => _radius = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _dateRange = null;
                        _genres.clear();
                        _radius = null;
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        SearchFilters(dateRange: _dateRange, genres: _genres, radius: _radius),
                      );
                    },
                    child: Text(S.of(context).apply),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
