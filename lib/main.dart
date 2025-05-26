import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tickets_booking/providers/auth_provider.dart';
import 'package:tickets_booking/providers/event_provider.dart';
import 'package:tickets_booking/providers/wishlist_provider.dart';
import 'package:tickets_booking/providers/theme_mode_notifier.dart';
import 'package:tickets_booking/screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventsProvider()),
        ChangeNotifierProvider(create: (context) => WishlistProvider(context.read<AuthProvider>())),
        ChangeNotifierProvider(create: (_) => ThemeModeNotifier()),
      ],
      child: Builder(
        builder: (context) => MaterialApp(
          title: 'Ticket Booking App',
          theme: ThemeData(useMaterial3: true, primarySwatch: Colors.blue),
          darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
          themeMode: context.watch<ThemeModeNotifier>().mode,
          home: const AuthWrapper(),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isAuthenticated) {
      return const MainScreen();
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text("Авторизація")),
        body: Center(
          child: ElevatedButton(
            onPressed: () => authProvider.signInWithGoogle(),
            child: const Text("Увійти через Google"),
          ),
        ),
      );
    }
  }
}
