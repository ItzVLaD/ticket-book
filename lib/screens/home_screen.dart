import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../generated/l10n.dart';
import '../models/event_group.dart';
import '../providers/event_provider.dart';
import '../services/ticketmaster_service.dart';
import '../widgets/event_card.dart';
import '../widgets/genre_chips.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/skeleton_loader.dart';
import 'event_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  // first genre selected by default
  String _selectedGenre = 'Concerts';
  // hero carousel groups loaded initially, unchanged by chip selection
  List<EventGroup>? _heroGroups;

  @override
  void initState() {
    super.initState();
    // initial load: fetch unfiltered events for hero, then load selected genre for list
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final service = TicketmasterService();
      // 1. fetch and group unfiltered events for carousel
      final rawDefault = await service.fetchEvents();
      setState(() {
        _heroGroups = service.groupEvents(rawDefault);
      });
      // 2. load filtered list for initial chip selection
      var initialKey = _selectedGenre.toLowerCase();
      if (initialKey.endsWith('s')) {
        initialKey = initialKey.substring(0, initialKey.length - 1);
      }
      await context.read<EventsProvider>().loadEvents(keyword: initialKey);
    });
  }

  Future<void> _onRefresh() async {
    // normalize selected genre to API keyword
    var key = _selectedGenre.toLowerCase();
    if (key.endsWith('s')) key = key.substring(0, key.length - 1);
    await context.read<EventsProvider>().loadEvents(keyword: key);
  }

  void _onGenreSelected(String genre) {
    // Update selected genre and reload list; hero carousel uses initial data only
    setState(() => _selectedGenre = genre);
    // normalize genre label to keyword
    var key = genre.toLowerCase();
    if (key.endsWith('s')) key = key.substring(0, key.length - 1);
    context.read<EventsProvider>().loadEvents(keyword: key);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventsProvider>();
    final groups = provider.currentGroupedEvents; // Use filtered current events only
    // hero uses initial groups only, but filter for current events
    final heroGroups = _heroGroups?.where((group) => group.hasCurrentEvents).toList() ?? groups;
    final topHero = heroGroups.length > 5 ? heroGroups.sublist(0, 5) : heroGroups;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            collapsedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background:
                  // Show initial hero skeleton until _heroGroups is loaded, then static carousel
                  (_heroGroups == null)
                      ? const SkeletonCarousel()
                      : HeroCarousel(
                        groups: topHero,
                        pageController: _pageController,
                        indicator: SmoothPageIndicator(
                          controller: _pageController,
                          count: topHero.length,
                          effect: WormEffect(
                            dotColor: theme.colorScheme.onSurface.withOpacity(0.3),
                            activeDotColor: theme.colorScheme.primary,
                          ),
                        ),
                      ),
            ),
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: GenreChips(
              genres: const ['Concerts', 'Theatre', 'Sports', 'Exhibitions', 'Other'],
              selected: _selectedGenre,
              onSelected: _onGenreSelected,
            ),
          ),
          if (provider.isLoading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, __) => const SkeletonEventCard(),
                childCount: 6,
              ),
            )
          else if (provider.hasError)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load events',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.errorMessage,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed:
                            () => provider.refresh(keyword: _getKeywordFromGenre(_selectedGenre)),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (groups.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_busy, size: 64, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(S.of(context).noEventsFound, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Try selecting a different category',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final group = groups[index];
                final event = group.schedules.first;
                return EventCard(
                  event: event,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => EventDetailScreen(
                              event: event,
                              eventGroup: group, // Pass the group for grouped events
                            ),
                      ),
                    );
                  },
                );
              }, childCount: groups.length),
            ),
        ],
      ),
    );
  }

  String _getKeywordFromGenre(String genre) {
    var key = genre.toLowerCase();
    if (key.endsWith('s')) key = key.substring(0, key.length - 1);
    return key;
  }
}
