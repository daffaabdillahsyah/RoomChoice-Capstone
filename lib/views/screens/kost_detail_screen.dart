import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../models/kost_model.dart';
import '../../models/booking_model.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/auth_controller.dart';

class BookingDialog extends StatefulWidget {
  final Room room;
  final String kostId;

  const BookingDialog({
    super.key,
    required this.room,
    required this.kostId,
  });

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Book ${widget.room.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Price: Rp ${widget.room.price.toStringAsFixed(0)} / month'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _startDate = date;
                        // Reset end date if it's before new start date
                        if (_endDate != null && _endDate!.isBefore(_startDate!.add(const Duration(days: 30)))) {
                          _endDate = null;
                        }
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_startDate != null 
                    ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                    : 'Start Date'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  onPressed: _startDate == null
                    ? null
                    : () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate!.add(const Duration(days: 30)),
                          firstDate: _startDate!.add(const Duration(days: 30)),
                          lastDate: _startDate!.add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_endDate != null 
                    ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                    : 'End Date'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        Consumer<BookingController>(
          builder: (context, controller, child) {
            return ElevatedButton(
              onPressed: controller.isLoading || _startDate == null || _endDate == null
                  ? null
                  : () async {
                      final user = context.read<AuthController>().currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please login first')),
                        );
                        return;
                      }

                      final booking = Booking(
                        id: '', // Will be set by Firestore
                        kostId: widget.kostId,
                        roomId: widget.room.id,
                        userId: user.id,
                        startDate: _startDate!,
                        endDate: _endDate!,
                        status: 'pending',
                        totalPrice: widget.room.price,
                        createdAt: DateTime.now(),
                      );

                      final success = await controller.createBooking(booking);
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success 
                              ? 'Booking request sent successfully' 
                              : 'Failed to create booking: ${controller.error}'),
                          ),
                        );
                      }
                    },
              child: controller.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Book Now'),
            );
          },
        ),
      ],
    );
  }
}

class KostDetailScreen extends StatefulWidget {
  final Kost kost;

  const KostDetailScreen({super.key, required this.kost});

  @override
  State<KostDetailScreen> createState() => _KostDetailScreenState();
}

class _KostDetailScreenState extends State<KostDetailScreen> {
  int _selectedFloor = 1;
  Room? _selectedRoom;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.kost.floors.isNotEmpty) {
      _selectedFloor = widget.kost.floors.keys.first;
    }
    // Initialize the booking controller for the current user
    final user = context.read<AuthController>().currentUser;
    if (user != null) {
      context.read<BookingController>().initializeUserBookings(user.id);
    }
  }

  Color _getRoomStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'booked':
        return Colors.orange;
      case 'occupied':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showBookingDialog(BuildContext context, Room room) {
    showDialog(
      context: context,
      builder: (context) => BookingDialog(
        room: room,
        kostId: widget.kost.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedFloorPlan = widget.kost.floors[_selectedFloor];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kost.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kost Image
            if (widget.kost.images.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: widget.kost.images.first.startsWith('data:image')
                  ? Image.memory(
                      base64Decode(widget.kost.images.first.split(',')[1]),
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      widget.kost.images.first,
                      fit: BoxFit.cover,
                    ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kost Details
                  Text(
                    widget.kost.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.kost.address,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rp ${widget.kost.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.kost.description,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Floor Selection
                  Text(
                    'Select Floor',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.kost.floors.keys.map((floor) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('Floor $floor'),
                            selected: _selectedFloor == floor,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedFloor = floor);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Floor Plan
                  if (selectedFloorPlan != null) ...[
                    Text(
                      'Floor Plan',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.width,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 2.0,
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Floor Plan Image
                              if (selectedFloorPlan.imageUrl != null)
                                Positioned.fill(
                                  child: Image.memory(
                                    base64Decode(selectedFloorPlan.imageUrl.split(',')[1]),
                                    fit: BoxFit.contain,
                                  ),
                                )
                              else
                                const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                ),
                              // Room Positions
                              ...selectedFloorPlan.rooms.map((room) {
                                return Positioned(
                                  left: room.position.x,
                                  top: room.position.y,
                                  child: GestureDetector(
                                    onTap: room.status == 'available'
                                        ? () => _showBookingDialog(context, room)
                                        : null,
                                    child: Container(
                                      width: room.size.width,
                                      height: room.size.height,
                                      decoration: BoxDecoration(
                                        color: _getRoomStatusColor(room.status).withOpacity(0.5),
                                        border: Border.all(
                                          color: _getRoomStatusColor(room.status),
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          room.name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  // Room List
                  Text(
                    'Available Rooms',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...selectedFloorPlan?.rooms.map((room) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _getRoomStatusColor(room.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(room.name),
                        subtitle: Text(
                          'Rp ${room.price.toStringAsFixed(0)} / month',
                        ),
                        trailing: room.status == 'available'
                            ? ElevatedButton(
                                onPressed: () => _showBookingDialog(context, room),
                                child: const Text('Book'),
                              )
                            : Text(
                                room.status.toUpperCase(),
                                style: TextStyle(
                                  color: _getRoomStatusColor(room.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  }).toList() ?? [],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 