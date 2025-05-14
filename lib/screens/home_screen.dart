import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tickets_booking/providers/event_provider.dart';
import 'package:tickets_booking/screens/event_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsProvider>().loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Культурні події')),
      body:
          provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: provider.events.length,
                itemBuilder: (context, index) {
                  final event = provider.events[index];
                  return ListTile(
                    leading:
                        event.imageUrl != null
                            ? Image.network(event.imageUrl!, width: 50, fit: BoxFit.cover)
                            : null,
                    title: Text(event.name),
                    subtitle: Text(event.venue ?? 'Невідоме місце'),
                    trailing: Text(event.date ?? ''),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
                      );
                    },
                  );
                },
              ),
    );
  }
}
