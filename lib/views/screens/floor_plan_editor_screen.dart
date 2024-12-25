import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/kost_controller.dart';
import '../../models/kost_model.dart';

class FloorPlanEditorScreen extends StatefulWidget {
  final Kost kost;
  final Room room;

  const FloorPlanEditorScreen({
    super.key,
    required this.kost,
    required this.room,
  });

  @override
  State<FloorPlanEditorScreen> createState() => _FloorPlanEditorScreenState();
}

class _FloorPlanEditorScreenState extends State<FloorPlanEditorScreen> {
  late Position _position;
  late Size _size;
  bool _isDragging = false;
  bool _isResizing = false;
  Offset? _startPosition;
  Size? _startSize;

  @override
  void initState() {
    super.initState();
    _position = widget.room.position;
    _size = widget.room.size;
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _startPosition = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDragging) {
      setState(() {
        final dx = details.localPosition.dx - (_startPosition?.dx ?? 0);
        final dy = details.localPosition.dy - (_startPosition?.dy ?? 0);
        
        _position = Position(
          x: (_position.x + dx).clamp(0, MediaQuery.of(context).size.width - _size.width),
          y: (_position.y + dy).clamp(0, MediaQuery.of(context).size.height - _size.height),
        );
        
        _startPosition = details.localPosition;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _startPosition = null;
    });

    // Save position
    final updates = {
      'position': _position.toMap(),
    };
    context.read<KostController>().updateRoom(
      widget.kost.id,
      widget.room.id,
      updates,
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    setState(() {
      _isResizing = true;
      _startSize = Size(width: _size.width, height: _size.height);
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_isResizing && _startSize != null) {
      setState(() {
        _size = Size(
          width: (_startSize!.width * details.horizontalScale)
              .clamp(50, MediaQuery.of(context).size.width - _position.x),
          height: (_startSize!.height * details.verticalScale)
              .clamp(50, MediaQuery.of(context).size.height - _position.y),
        );
      });
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    setState(() {
      _isResizing = false;
      _startSize = null;
    });

    // Save size
    final updates = {
      'size': _size.toMap(),
    };
    context.read<KostController>().updateRoom(
      widget.kost.id,
      widget.room.id,
      updates,
    );
  }

  @override
  Widget build(BuildContext context) {
    final floorPlan = widget.kost.floors[widget.room.floor];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.room.name} Position'),
      ),
      body: Stack(
        children: [
          // Floor Plan
          if (floorPlan?.imageUrl != null)
            Positioned.fill(
              child: Image.network(
                floorPlan!.imageUrl,
                fit: BoxFit.contain,
              ),
            ),

          // Other Rooms (disabled)
          ...floorPlan?.rooms
              .where((room) => room.id != widget.room.id)
              .map((room) {
            return Positioned(
              left: room.position.x,
              top: room.position.y,
              child: Container(
                width: room.size.width,
                height: room.size.height,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(77),
                  border: Border.all(color: Colors.grey),
                ),
                child: Center(
                  child: Text(
                    room.name,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList() ?? [],

          // Selected Room
          Positioned(
            left: _position.x,
            top: _position.y,
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
              child: Container(
                width: _size.width,
                height: _size.height,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(77),
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        widget.room.name,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Resize handles
                    ...List.generate(8, (index) {
                      final isTop = index < 3;
                      final isBottom = index > 4;
                      final isLeft = index % 3 == 0;
                      final isRight = index % 3 == 2;

                      return Positioned(
                        top: isTop ? -4 : isBottom ? null : (_size.height - 8) / 2,
                        bottom: isBottom ? -4 : null,
                        left: isLeft ? -4 : isRight ? null : (_size.width - 8) / 2,
                        right: isRight ? -4 : null,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'Position: (${_position.x.toStringAsFixed(0)}, ${_position.y.toStringAsFixed(0)})',
              ),
              Text(
                'Size: ${_size.width.toStringAsFixed(0)} x ${_size.height.toStringAsFixed(0)}',
              ),
            ],
          ),
        ),
      ),
    );
  }
} 