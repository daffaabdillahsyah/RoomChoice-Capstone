import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/kost_controller.dart';
import '../../models/kost_model.dart';
import 'edit_kost_screen.dart';
import 'manage_rooms_screen.dart';
import 'dart:convert';

class ManageKostScreen extends StatelessWidget {
  const ManageKostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Kosts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditKostScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<KostController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.kosts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home_work_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No kosts available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditKostScreen(),
                        ),
                      );
                    },
                    child: const Text('Add New Kost'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.kosts.length,
            itemBuilder: (context, index) {
              final kost = controller.kosts[index];
              return _buildKostCard(context, kost);
            },
          );
        },
      ),
    );
  }

  Widget _buildKostCard(BuildContext context, Kost kost) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kost Image
          if (kost.images.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: kost.images.first.startsWith('data:image')
                ? Image.memory(
                    base64Decode(kost.images.first.split(',')[1]),
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    kost.images.first,
                    fit: BoxFit.cover,
                  ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(kost.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    kost.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusTextColor(kost.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Kost Name
                Text(
                  kost.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // Address
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        kost.address,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Price
                Text(
                  'Rp ${kost.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Room Count
                Text(
                  '${kost.totalRooms} Rooms',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditKostScreen(kost: kost),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageRoomsScreen(kost: kost),
                            ),
                          );
                        },
                        icon: const Icon(Icons.room_preferences),
                        label: const Text('Rooms'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        _showDeleteConfirmation(context, kost);
                      },
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green[100]!;
      case 'pending':
        return Colors.orange[100]!;
      case 'rejected':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green[900]!;
      case 'pending':
        return Colors.orange[900]!;
      case 'rejected':
        return Colors.red[900]!;
      default:
        return Colors.grey[900]!;
    }
  }

  void _showDeleteConfirmation(BuildContext context, Kost kost) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Kost'),
        content: Text('Are you sure you want to delete ${kost.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<KostController>().deleteKost(kost.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 