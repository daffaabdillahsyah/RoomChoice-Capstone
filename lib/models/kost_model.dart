import 'package:cloud_firestore/cloud_firestore.dart';

class Kost {
  final String id;
  final String name;
  final String address;
  final String description;
  final String ownerId;
  final double price;
  final String status; // 'verified', 'pending', 'rejected'
  final List<String> images;
  final Map<String, dynamic> facilities;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<int, FloorPlan> floors; // Map of floor number to floor plan
  final List<Room> rooms;

  Kost({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.ownerId,
    required this.price,
    required this.status,
    required this.images,
    required this.facilities,
    required this.createdAt,
    required this.updatedAt,
    required this.floors,
    required this.rooms,
  });

  factory Kost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Kost(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      description: data['description'] ?? '',
      ownerId: data['ownerId'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      images: List<String>.from(data['images'] ?? []),
      facilities: Map<String, dynamic>.from(data['facilities'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      floors: (data['floors'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(
          int.parse(key),
          FloorPlan.fromMap(value as Map<String, dynamic>),
        ),
      ),
      rooms: (data['rooms'] as List? ?? [])
          .map((room) => Room.fromMap(room))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'description': description,
      'ownerId': ownerId,
      'price': price,
      'status': status,
      'images': images,
      'facilities': facilities,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'floors': floors.map(
        (key, value) => MapEntry(key.toString(), value.toMap()),
      ),
      'rooms': rooms.map((room) => room.toMap()).toList(),
    };
  }
}

class FloorPlan {
  final String imageUrl;
  final String name;
  final List<Room> rooms;

  FloorPlan({
    required this.imageUrl,
    required this.name,
    required this.rooms,
  });

  factory FloorPlan.fromMap(Map<String, dynamic> map) {
    return FloorPlan(
      imageUrl: map['imageUrl'] ?? '',
      name: map['name'] ?? '',
      rooms: (map['rooms'] as List? ?? [])
          .map((room) => Room.fromMap(room))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'name': name,
      'rooms': rooms.map((room) => room.toMap()).toList(),
    };
  }
}

class Room {
  final String id;
  final String name;
  final String status; // 'available', 'booked', 'occupied'
  final double price;
  final Map<String, dynamic> facilities;
  final Position position; // Position in floor plan
  final Size size; // Size in floor plan
  final int floor; // Floor number where the room is located

  Room({
    required this.id,
    required this.name,
    required this.status,
    required this.price,
    required this.facilities,
    required this.position,
    required this.size,
    required this.floor,
  });

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      status: map['status'] ?? 'available',
      price: (map['price'] ?? 0).toDouble(),
      facilities: Map<String, dynamic>.from(map['facilities'] ?? {}),
      position: Position.fromMap(map['position'] ?? {}),
      size: Size.fromMap(map['size'] ?? {}),
      floor: map['floor'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'price': price,
      'facilities': facilities,
      'position': position.toMap(),
      'size': size.toMap(),
      'floor': floor,
    };
  }
}

class Position {
  final double x;
  final double y;

  Position({
    required this.x,
    required this.y,
  });

  factory Position.fromMap(Map<String, dynamic> map) {
    return Position(
      x: (map['x'] ?? 0).toDouble(),
      y: (map['y'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
    };
  }
}

class Size {
  final double width;
  final double height;

  Size({
    required this.width,
    required this.height,
  });

  factory Size.fromMap(Map<String, dynamic> map) {
    return Size(
      width: (map['width'] ?? 0).toDouble(),
      height: (map['height'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'width': width,
      'height': height,
    };
  }
} 