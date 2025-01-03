import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../controllers/kost_controller.dart';
import '../../models/kost_model.dart';

class EditKostScreen extends StatefulWidget {
  final Kost? kost;

  const EditKostScreen({super.key, this.kost});

  @override
  State<EditKostScreen> createState() => _EditKostScreenState();
}

class _EditKostScreenState extends State<EditKostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  Map<int, File?> _floorPlanFiles = {};
  List<File> _imageFiles = [];
  Map<String, bool> _facilities = {
    'WiFi': false,
    'AC': false,
    'Parking': false,
    'Security': false,
    'Laundry': false,
    'Kitchen': false,
  };
  int _totalFloors = 1;

  @override
  void initState() {
    super.initState();
    if (widget.kost != null) {
      _nameController.text = widget.kost!.name;
      _addressController.text = widget.kost!.address;
      _descriptionController.text = widget.kost!.description;
      _priceController.text = widget.kost!.price.toString();
      _totalFloors = widget.kost!.floors.length;
      
      // Load facilities
      final facilities = widget.kost!.facilities;
      facilities.forEach((key, value) {
        if (_facilities.containsKey(key)) {
          _facilities[key] = value as bool;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickFloorPlan(int floor) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _floorPlanFiles[floor] = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  Future<void> _saveKost() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate floor plans
    for (int i = 1; i <= _totalFloors; i++) {
      if (_floorPlanFiles[i] == null && widget.kost?.floors[i]?.imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a floor plan for floor $i')),
        );
        return;
      }
    }

    if (_imageFiles.isEmpty && (widget.kost?.images.isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }

    final kost = Kost(
      id: widget.kost?.id ?? '',
      name: _nameController.text,
      address: _addressController.text,
      description: _descriptionController.text,
      ownerId: 'admin', // TODO: Get from auth controller
      price: double.parse(_priceController.text),
      status: widget.kost?.status ?? 'pending',
      images: widget.kost?.images ?? [],
      facilities: _facilities,
      createdAt: widget.kost?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      floors: widget.kost?.floors ?? {},
      rooms: widget.kost?.rooms ?? [],
    );

    final controller = context.read<KostController>();
    bool success;

    if (widget.kost == null) {
      // Create new kost
      success = await controller.createKostWithFloors(kost, _floorPlanFiles, _imageFiles);
    } else {
      // Update existing kost
      final updates = kost.toMap();
      success = await controller.updateKostWithFloors(
        widget.kost!.id, 
        updates, 
        _floorPlanFiles,
        _imageFiles,
      );
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.error ?? 'Failed to save kost')),
        );
      }
    }
  }

  Widget _buildFloorPlanCard(int floor) {
    final existingFloorPlan = widget.kost?.floors[floor];
    final newFloorPlan = _floorPlanFiles[floor];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Floor $floor',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (floor == _totalFloors && floor > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      setState(() {
                        _totalFloors--;
                        _floorPlanFiles.remove(floor);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (existingFloorPlan != null && newFloorPlan == null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  existingFloorPlan.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            if (newFloorPlan != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.file(
                  newFloorPlan,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _pickFloorPlan(floor),
              icon: const Icon(Icons.upload),
              label: Text('Upload Floor $floor Plan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kost == null ? 'Add New Kost' : 'Edit Kost'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Kost Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter kost name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Price
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
            const SizedBox(height: 16),

            // Facilities
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Facilities',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _facilities.entries.map((entry) {
                        return FilterChip(
                          label: Text(entry.key),
                          selected: entry.value,
                          onSelected: (selected) {
                            setState(() {
                              _facilities[entry.key] = selected;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Floor Plans
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Floor Plans',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _totalFloors++;
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Floor'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_totalFloors, (index) => 
                      _buildFloorPlanCard(index + 1)
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Images
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Images',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.kost?.images != null)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.kost!.images.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Image.network(
                                  widget.kost!.images[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    if (_imageFiles.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imageFiles.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Image.file(
                                  _imageFiles[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload Images'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _saveKost,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Kost'),
            ),
          ],
        ),
      ),
    );
  }
} 