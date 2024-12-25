import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  Size _roomSize = Size(width: 100, height: 100);
  Map<String, bool> _facilities = {
    'AC': false,
    'Bathroom': false,
    'Bed': false,
    'Desk': false,
    'Wardrobe': false,
  };
  int _selectedFloor = 1;

  void _addRoom() {
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

                context.read<KostController>().addRoom(widget.kost.id, room);
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
                      child: Image.network(
                        widget.kost.floors[_selectedFloor]!.imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),

                  // Rooms
                  ...widget.kost.floors[_selectedFloor]?.rooms.map((room) {
                    return Positioned(
                      left: room.position.x,
                      top: room.position.y,
                      child: GestureDetector(
                        onTap: () => _editRoom(room),
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
                          child: Center(
                            child: Text(
                              room.name,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
} 