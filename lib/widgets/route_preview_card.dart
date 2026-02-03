import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mapa_ule/models/destination.dart';

class RoutePreviewCard extends StatefulWidget {
  final Destination? plannerStart;
  final Destination? selectedDestination;
  final int distance;
  final int time;
  final bool isSameFloor;
  final VoidCallback onNavigationStart;
  final VoidCallback onWaySelected;
  final bool isElevatorSelected;
  final VoidCallback onClose;

  const RoutePreviewCard({
    super.key,
    this.plannerStart,
    this.selectedDestination,
    required this.distance,
    required this.time,
    required this.isSameFloor,
    required this.onNavigationStart,
    required this.onWaySelected,
    required this.isElevatorSelected,
    required this.onClose,
  });

  @override
  State<RoutePreviewCard> createState() => _RoutePreviewCardState();
}

class _RoutePreviewCardState extends State<RoutePreviewCard> {
  @override
  Widget build(BuildContext context) {
    return drawRoutePreviewCard();
  }

  Card drawRoutePreviewCard() {
    return Card(
      color: Colors.white,
      shadowColor: Colors.black,
      margin: EdgeInsets.symmetric(horizontal: 20.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: widget.plannerStart == null
                      ? SizedBox(child: Text("Selecciona un punto de partida:"))
                      : widget.selectedDestination == null
                      ? SizedBox(child: Text("Selecciona un destino:"))
                      : SizedBox.shrink(),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(Icons.close_rounded),
                  constraints: BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            SizedBox(height: 5.0),
            !widget.isSameFloor &&
                    widget.plannerStart != null &&
                    widget.selectedDestination != null
                ? Row(
                    children: [
                      ChoiceChip(
                        label: Icon(Icons.stairs_rounded),
                        selected: !widget.isElevatorSelected,
                        onSelected: (value) {
                          widget.onWaySelected();
                        },
                      ),
                      ChoiceChip(
                        label: Icon(Icons.elevator_rounded),
                        selected: widget.isElevatorSelected,
                        onSelected: (value) {
                          widget.onWaySelected();
                        },
                      ),
                    ],
                  )
                : SizedBox.shrink(),
            SizedBox(height: 10.0),
            widget.distance != 0 && widget.time != 0
                ? Row(
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
                              DateTime.now().add(
                                Duration(minutes: widget.time),
                              ),
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
                  )
                : SizedBox.shrink(),
            SizedBox(height: 10.0),
            FilledButton(
              onPressed: widget.onNavigationStart,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded),
                  Text(
                    " INICIAR",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
