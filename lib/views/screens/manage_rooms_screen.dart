import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../controllers/kost_controller.dart';
import '../../models/kost_model.dart';

class ManageRoomsScreen extends StatefulWidget {
  final Kost kost;

  const ManageRoomsScreen({super.key, required this.kost});

  @override
  State<ManageRoomsScreen> createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends State<ManageRoomsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  
  Room? _selectedRoom;
  Position _roomPosition = Position(x: 0, y: 0);
  Size _roomSize = Size(width: 80, height: 80);
  Map<String, bool> _facilities = {
    'AC': false,
    'Bathroom': false,
    'Bed': false,
    'Desk': false,
    'Wardrobe': false,
  };
  int _selectedFloor = 1;
  final GlobalKey _floorPlanKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Set initial floor if available
    if (widget.kost.floors.isNotEmpty) {
      _selectedFloor = widget.kost.floors.keys.first;
    }
  }

  void _addRoom() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Room'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Room Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter room name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Get floor plan size
                final RenderBox renderBox = _floorPlanKey.currentContext?.findRenderObject() as RenderBox;
                final size = renderBox.size;
                
                // Set initial position at center
                _roomPosition = Position(
                  x: (size.width - _roomSize.width) / 2,
                  y: (size.height - _roomSize.height) / 2,
                );

                final room = Room(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: _nameController.text,
                  status: 'available',
                  price: double.parse(_priceController.text),
                  facilities: _facilities,
                  position: _roomPosition,
                  size: _roomSize,
                  floor: _selectedFloor,
                );

                context.read<KostController>().addRoom(widget.kost.id, room).then((_) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Room added. Now drag to position it on the floor plan.')),
                  );
                });
                Navigator.pop(context);

                _nameController.clear();
                _priceController.clear();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editRoom(Room room) {
    _selectedRoom = room;
    _nameController.text = room.name;
    _priceController.text = room.price.toString();
    _facilities = Map<String, bool>.from(room.facilities);
    _roomPosition = room.position;
    _roomSize = room.size;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Room'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Room Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter room name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final updates = {
                  'name': _nameController.text,
                  'price': double.parse(_priceController.text),
                  'facilities': _facilities,
                  'position': _roomPosition.toMap(),
                  'size': _roomSize.toMap(),
                  'floor': _selectedFloor,
                };

                context.read<KostController>().updateRoom(
                  widget.kost.id,
                  room.id,
                  updates,
                );
                Navigator.pop(context);

                _selectedRoom = null;
                _nameController.clear();
                _priceController.clear();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteRoom(Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Are you sure you want to delete ${room.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<KostController>().deleteRoom(widget.kost.id, room.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Rooms - ${widget.kost.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addRoom,
          ),
        ],
      ),
      body: Column(
        children: [
          // Floor Selection
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Select Floor',
                border: OutlineInputBorder(),
              ),
              value: _selectedFloor,
              items: widget.kost.floors.keys.map((floor) {
                return DropdownMenuItem(
                  value: floor,
                  child: Text('Floor $floor'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFloor = value;
                  });
                }
              },
            ),
          ),

          // Floor Plan
          Expanded(
            flex: 2,
            child: Container(
              key: _floorPlanKey,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  // Floor Plan Image
                  if (widget.kost.floors[_selectedFloor]?.imageUrl != null)
                    Positioned.fill(
                      child: Image.memory(
                        _base64ToBytes(widget.kost.floors[_selectedFloor]!.imageUrl),
                        fit: BoxFit.contain,
                      ),
                    ),

                  // Rooms
                  ...widget.kost.floors[_selectedFloor]?.rooms.map((room) {
                    return Positioned(
                      left: room.position.x,
                      top: room.position.y,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          final RenderBox box = _floorPlanKey.currentContext?.findRenderObject() as RenderBox;
                          final Offset localPosition = box.globalToLocal(details.globalPosition);
                          
                          // Ensure room stays within bounds
                          double newX = localPosition.dx - (room.size.width / 2);
                          double newY = localPosition.dy - (room.size.height / 2);
                          
                          newX = newX.clamp(0, box.size.width - room.size.width);
                          newY = newY.clamp(0, box.size.height - room.size.height);
                          
                          // Update room position
                          context.read<KostController>().updateRoom(
                            widget.kost.id,
                            room.id,
                            {
                              'position': {
                                'x': newX,
                                'y': newY,
                              },
                            },
                          );
                        },
                        child: Container(
                          width: room.size.width,
                          height: room.size.height,
                          decoration: BoxDecoration(
                            color: _getRoomColor(room.status).withOpacity(0.5),
                            border: Border.all(
                              color: _getRoomColor(room.status),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                room.name,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Rp ${room.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList() ?? [],
                ],
              ),
            ),
          ),

          // Room List
          Expanded(
            flex: 1,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.kost.floors[_selectedFloor]?.rooms.length ?? 0,
              itemBuilder: (context, index) {
                final room = widget.kost.floors[_selectedFloor]!.rooms[index];
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getRoomColor(room.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(room.name),
                    subtitle: Text(
                      'Rp ${room.price.toStringAsFixed(0)} - ${room.status}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.color_lens),
                          onSelected: (status) {
                            context.read<KostController>().updateRoom(
                              widget.kost.id,
                              room.id,
                              {'status': status},
                            );
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'available',
                              child: Text('Available (Green)'),
                            ),
                            const PopupMenuItem(
                              value: 'booked',
                              child: Text('Booked (Yellow)'),
                            ),
                            const PopupMenuItem(
                              value: 'occupied',
                              child: Text('Occupied (Red)'),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editRoom(room),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteRoom(room),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoomColor(String status) {
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

  Uint8List _base64ToBytes(String base64String) {
    String base64Image = base64String.split(',').last;
    return base64Decode(base64Image);
  }
} 