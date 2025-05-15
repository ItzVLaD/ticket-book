import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tickets_booking/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Center(child: Text("Користувач не знайдений"));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Профіль')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(backgroundImage: NetworkImage(user.photoURL ?? ''), radius: 50),
              const SizedBox(height: 10),
              Text(
                user.displayName ?? 'Без імені',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 5),
              Text(user.email ?? 'Email не вказано'),
              const SizedBox(height: 20),
              ElevatedButton(
                child: const Text("Вийти з акаунту"),
                onPressed: () => context.read<AuthProvider>().signOut(),
              ),
              const Divider(height: 30),
              const Text(
                'Ваші бронювання:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildBookingsList(user.uid),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsList(String userId) {
    final bookingsCollection = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('bookedAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: bookingsCollection.snapshots(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('Ви поки що нічого не забронювали.');
        }

        final bookings = snapshot.data!.docs;

        return Column(
          children:
              bookings.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(data['eventName'] ?? 'Невідомий івент'),
                  subtitle: Text(
                    "Кількість квитків: ${data['ticketsCount']} \nДата: ${data['eventDate']}",
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}
