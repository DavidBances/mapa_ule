import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NavigationCard extends StatefulWidget {
  final int distance;
  final int time;
  final VoidCallback onFinished;
  final VoidCallback onCancel;
  final Function(int) onNextFloor;
  final int? nextFloorNumber;

  const NavigationCard({
    super.key,
    required this.distance,
    required this.time,
    required this.onFinished,
    required this.onCancel,
    required this.onNextFloor,
    this.nextFloorNumber,
  });

  @override
  State<NavigationCard> createState() => _NavigationCardState();
}

class _NavigationCardState extends State<NavigationCard> {
  @override
  Widget build(BuildContext context) {
    return drawNavigationCard();
  }

  Card drawNavigationCard() {
    return Card(
      color: Colors.white,
      shadowColor: Colors.black,
      margin: EdgeInsets.symmetric(horizontal: 20.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.hourglass_full_rounded,
                        color: Colors.greenAccent[400],
                      ),
                      Text(
                        "${widget.time} min",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent[400],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "${widget.distance} metros",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      " · ",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      DateFormat.Hm().format(
                        DateTime.now().add(Duration(minutes: widget.time)),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10.0),
            Row(
              children: [
                if (widget.nextFloorNumber != null) ...{
                  drawNextFloorButton(),
                  SizedBox(width: 10.0),
                  drawCancelButton(),
                } else ...{
                  drawFinishedButton(),
                  SizedBox(width: 10.0),
                  drawCancelButton(),
                },
              ],
            ),
          ],
        ),
      ),
    );
  }

  Expanded drawFinishedButton() {
    return Expanded(
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.teal[700],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        onPressed: widget.onFinished,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(Icons.check_box_rounded), Text(" FINALIZAR")],
        ),
      ),
    );
  }

  Expanded drawCancelButton() {
    return Expanded(
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.redAccent[700],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        onPressed: widget.onCancel,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(Icons.close_rounded), Text(" CANCELAR")],
        ),
      ),
    );
  }

  Expanded drawNextFloorButton() {
    return Expanded(
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.indigoAccent[700],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        onPressed: () => widget.onNextFloor(widget.nextFloorNumber!),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.elevator_rounded),
            Text(" Ir al piso ${widget.nextFloorNumber}"),
          ],
        ),
      ),
    );
  }
}
