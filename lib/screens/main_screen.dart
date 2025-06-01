import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'wishlist_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToHome() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _selectedIndex,
      children: [
        const HomeScreen(),
        const SearchScreen(),
        WishlistScreen(onNavigateToHome: _navigateToHome),
        const ProfileScreen(),
      ],
    ),
    bottomNavigationBar: BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'WishList'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: _onItemTapped,
    ),
  );
}
