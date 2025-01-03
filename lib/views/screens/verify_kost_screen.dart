import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/kost_controller.dart';
import '../../models/kost_model.dart';

class VerifyKostScreen extends StatelessWidget {
  const VerifyKostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<KostController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendingKosts = controller.kosts.where((k) => k.status == 'pending').toList();

        if (pendingKosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending verifications',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingKosts.length,
          itemBuilder: (context, index) {
            final kost = pendingKosts[index];
            return _buildKostCard(context, kost, controller);
          },
        );
      },
    );
  }

  Widget _buildKostCard(BuildContext context, Kost kost, KostController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kost Images
          if (kost.images.isNotEmpty)
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: kost.images.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    kost.images[index],
                    fit: BoxFit.cover,
                  );
                },
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
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.orange[900],
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

                // Facilities
                Wrap(
                  spacing: 8,
                  children: kost.facilities.entries
                      .where((f) => f.value == true)
                      .map((f) => Chip(
                            label: Text(
                              f.key,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showRejectDialog(context, kost.id, controller),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showVerifyDialog(context, kost.id, controller),
                        child: const Text('Verify'),
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
  }

  void _showVerifyDialog(BuildContext context, String kostId, KostController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Kost'),
        content: const Text('Are you sure you want to verify this kost?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await controller.verifyKost(kostId);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kost verified successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String kostId, KostController controller) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Kost'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              final success = await controller.rejectKost(kostId, reasonController.text);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kost rejected'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
} 