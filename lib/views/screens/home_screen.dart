import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RoomChoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
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
              leading: const Icon(Icons.favorite_border),
              title: const Text('Favorites'),
              onTap: () {
                // TODO: Navigate to favorites
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.book_online),
              title: const Text('My Bookings'),
              onTap: () {
                // TODO: Navigate to bookings
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () {
                // TODO: Navigate to history
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                // TODO: Navigate to profile
                Navigator.pop(context);
              },
            ),
            if (user?.role == 'owner') ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add_home_work),
                title: const Text('Add New Kost'),
                onTap: () {
                  // TODO: Navigate to add kost form
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.manage_accounts),
                title: const Text('Manage My Kosts'),
                onTap: () {
                  // TODO: Navigate to kost management
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for kosts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                // TODO: Implement search functionality
              },
            ),
          ),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('Price Range'),
                const SizedBox(width: 8),
                _buildFilterChip('Location'),
                const SizedBox(width: 8),
                _buildFilterChip('Room Type'),
                const SizedBox(width: 8),
                _buildFilterChip('Facilities'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Kost Listings
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 10, // TODO: Replace with actual kost data
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(
                        'https://picsum.photos/seed/$index/400/200',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kost Name ${index + 1}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Location address of the kost',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Rp 1.500.000 / month',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      // TODO: Add to favorites
                                    },
                                    icon: const Icon(Icons.favorite_border),
                                    label: const Text('Save'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      // TODO: Navigate to detail page
                                    },
                                    icon: const Icon(Icons.visibility),
                                    label: const Text('View'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
      onPressed: () {
        // TODO: Show filter dialog
      },
    );
  }
} 