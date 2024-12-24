import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Management System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthController>().logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.username ?? ''),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.person),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room),
              title: const Text('Rooms'),
              onTap: () {
                // TODO: Navigate to rooms screen
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.book_online),
              title: const Text('Bookings'),
              onTap: () {
                // TODO: Navigate to bookings screen
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                // TODO: Navigate to notifications screen
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                // TODO: Navigate to settings screen
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildDashboardCard(
            context,
            'Room Status',
            Icons.meeting_room,
            Colors.blue,
            () {
              // TODO: Navigate to room status
            },
          ),
          _buildDashboardCard(
            context,
            'Bookings',
            Icons.book_online,
            Colors.green,
            () {
              // TODO: Navigate to bookings
            },
          ),
          _buildDashboardCard(
            context,
            'Notifications',
            Icons.notifications,
            Colors.orange,
            () {
              // TODO: Navigate to notifications
            },
          ),
          _buildDashboardCard(
            context,
            'Reports',
            Icons.assessment,
            Colors.purple,
            () {
              // TODO: Navigate to reports
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
} 