import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:tickets_booking/providers/event_provider.dart';
import 'package:tickets_booking/screens/event_detail_screen.dart';
import 'package:tickets_booking/generated/l10n.dart';
import 'package:tickets_booking/widgets/hero_carousel.dart';
import 'package:tickets_booking/widgets/genre_chips.dart';
import 'package:tickets_booking/widgets/event_card.dart';
import 'package:tickets_booking/widgets/skeleton_loader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  String? _selectedGenre;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsProvider>().loadEvents();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<EventsProvider>().loadEvents(keyword: _selectedGenre ?? 'concert');
  }

  void _onGenreSelected(String genre) {
    setState(() => _selectedGenre = genre);
    context.read<EventsProvider>().loadEvents(keyword: genre);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventsProvider>();
    final events = provider.events;
    final topEvents = events.length > 5 ? events.sublist(0, 5) : events;
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
                  provider.isLoading
                      ? const SkeletonCarousel()
                      : HeroCarousel(
                        events: topEvents,
                        pageController: _pageController,
                        indicator: SmoothPageIndicator(
                          controller: _pageController,
                          count: topEvents.length,
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
                  final event = events[index];
                  return EventCard(
                    event: event,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
                      );
                    },
                  );
                }, childCount: events.length),
              ),
        ],
      ),
    );
  }
}
