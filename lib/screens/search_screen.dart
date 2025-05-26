import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tickets_booking/models/search_filters.dart';
import 'package:tickets_booking/services/ticketmaster_service.dart';
import 'package:tickets_booking/models/event.dart';
import 'package:tickets_booking/widgets/event_card.dart';
import 'package:tickets_booking/widgets/skeleton_loader.dart';
import 'package:tickets_booking/generated/l10n.dart';

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
  List<Event> results = [];
  bool isLoading = false;
  bool hasError = false;
  bool hasMore = true;
  int _page = 0;
  Timer? _debounce;
  bool _disposed = false;

  SearchController() {
    queryController.addListener(_onQueryChanged);
    _search();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_disposed) return;
      _page = 0;
      results.clear();
      hasMore = true;
      _search();
    });
  }

  Future<void> _search() async {
    if (_disposed || !hasMore) return;
    isLoading = true;
    hasError = false;
    notifyListeners();

    try {
      final pageKey = _page + 1;
      final pageResults = await _service.fetchEvents(keyword: queryController.text);
      if (_disposed) return;
      if (pageResults.isEmpty) {
        hasMore = false;
      } else {
        results.addAll(pageResults);
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

  Future<void> refresh() async {
    _debounce?.cancel();
    _page = 0;
    results.clear();
    hasMore = true;
    await _search();
  }

  void updateFilters(SearchFilters newFilters) {
    filters = newFilters;
    _page = 0;
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
  const _SearchView({super.key});

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
                ctrl.hasMore) {
              ctrl._search(); // ignore: invalid_use_of_protected_member
            }
            return false;
          },
          child: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index < ctrl.results.length) {
                    return EventCard(event: ctrl.results[index], onTap: () {});
                  }
                  // loader at bottom
                  return ctrl.isLoading ? const SkeletonEventCard() : const SizedBox.shrink();
                }, childCount: ctrl.results.length + (ctrl.hasMore ? 1 : 0)),
              ),
              if (!ctrl.isLoading && ctrl.results.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 64, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(S.of(context).noResultsFound, style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ),
              if (ctrl.hasError)
                SliverFillRemaining(child: Center(child: Text(S.of(context).errorLoadingEvents))),
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
  const _FilterSheet({required this.initial, super.key});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late DateTimeRange? _dateRange;
  late RangeValues _price;
  late List<String> _genres;
  int? _radius;
  final _allGenres = ['Concerts', 'Theatre', 'Sports', 'Exhibitions', 'Other'];
  final _radiusOptions = [null, 10, 25, 50];

  @override
  void initState() {
    super.initState();
    _dateRange = widget.initial.dateRange;
    _price = widget.initial.priceRange;
    _genres = List.from(widget.initial.genres);
    _radius = widget.initial.radius;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          ListTile(
            title: Text(S.of(context).filters),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.of(context).dateRange),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        initialDateRange: _dateRange,
                      );
                      if (range != null) setState(() => _dateRange = range);
                    },
                    child: Text(
                      _dateRange != null
                          ? '${S.of(context).from} ${_dateRange!.start.toLocal()} to ${_dateRange!.end.toLocal()}'
                          : S.of(context).selectDate,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(S.of(context).priceRange),
                  RangeSlider(
                    values: _price,
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    labels: RangeLabels(
                      _price.start.toStringAsFixed(0),
                      _price.end.toStringAsFixed(0),
                    ),
                    onChanged: (v) => setState(() => _price = v),
                  ),
                  const SizedBox(height: 16),
                  Text(S.of(context).genres),
                  Wrap(
                    spacing: 8,
                    children:
                        _allGenres.map((g) {
                          final sel = _genres.contains(g);
                          return ChoiceChip(
                            label: Text(g),
                            selected: sel,
                            onSelected:
                                (_) => setState(() => sel ? _genres.remove(g) : _genres.add(g)),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(S.of(context).radius),
                  DropdownButton<int?>(
                    value: _radius,
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
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    SearchFilters(
                      dateRange: _dateRange,
                      priceRange: _price,
                      genres: _genres,
                      radius: _radius,
                    ),
                  );
                },
                child: Text(S.of(context).apply),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
