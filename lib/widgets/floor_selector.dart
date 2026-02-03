import 'package:flutter/material.dart';

class FloorSelector extends StatefulWidget {
  final List<int> floors;
  final int currentFloor;
  final Function(int) onFloorChanged;

  const FloorSelector({
    super.key,
    required this.floors,
    required this.currentFloor,
    required this.onFloorChanged,
  });

  @override
  State<FloorSelector> createState() => _FloorSelectorState();
}

class _FloorSelectorState extends State<FloorSelector> {
  @override
  Widget build(BuildContext context) {
    return floorButton();
  }

  Container floorButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton(
          items: List<DropdownMenuItem<int>>.generate(widget.floors.length, (
            index,
          ) {
            return DropdownMenuItem(
              value: widget.floors[index],
              child: Text("Piso ${widget.floors[index] + 1}"),
            );
          }),
          value: widget.currentFloor,
          icon: Icon(Icons.layers, color: Colors.blue[800]),
          onChanged: (int? value) {
            if (value != null) {
              widget.onFloorChanged(value);
            }
          },
        ),
      ),
    );
  }
}
