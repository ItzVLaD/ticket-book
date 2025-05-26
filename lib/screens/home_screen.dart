import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:tickets_booking/providers/event_provider.dart';
import 'package:tickets_booking/screens/event_detail_screen.dart';
import 'package:tickets_booking/models/event_group.dart';
import 'package:tickets_booking/generated/l10n.dart';
import 'package:tickets_booking/widgets/hero_carousel.dart';
import 'package:tickets_booking/widgets/genre_chips.dart';
import 'package:tickets_booking/widgets/event_card.dart';
import 'package:tickets_booking/widgets/skeleton_loader.dart';
import 'package:tickets_booking/services/ticketmaster_service.dart';

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
    final groups = provider.groupedEvents;
    // hero uses initial groups only
    final heroGroups = _heroGroups ?? groups;
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
          provider.isLoading
              ? SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const SkeletonEventCard(),
                  childCount: 6,
                ),
              )
              : provider.hasError
              ? SliverFillRemaining(child: Center(child: Text(S.of(context).errorLoadingEvents)))
              : SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final group = groups[index];
                  final event = group.schedules.first;
                  return EventCard(
                    event: event,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
                      );
                    },
                  );
                }, childCount: groups.length),
              ),
        ],
      ),
    );
  }
}
