import 'package:flutter/material.dart';
import 'package:mapa_ule/models/destination.dart';
import 'package:mapa_ule/utils/constants.dart';
import 'package:mapa_ule/widgets/destination_search_modal.dart';

class RoutePlannerInputs extends StatefulWidget {
  final Destination? start;
  final Destination? destination;
  final VoidCallback onSwapPressed;
  final List<Destination> destinations;
  final Function(Destination?) onStartChanged;
  final Function(Destination) onDestChanged;

  const RoutePlannerInputs({
    super.key,
    this.destination,
    this.start,
    required this.onSwapPressed,
    required this.destinations,
    required this.onStartChanged,
    required this.onDestChanged,
  });

  @override
  State<RoutePlannerInputs> createState() => _RoutePlannerInputsState();
}

class _RoutePlannerInputsState extends State<RoutePlannerInputs> {
  @override
  Widget build(BuildContext context) {
    return drawRoutePlannerInputs();
  }

  Card drawRoutePlannerInputs() {
    return Card(
      color: Colors.white,
      shadowColor: Colors.black,
      margin: EdgeInsets.symmetric(horizontal: 20.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.my_location_rounded),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            var result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DestinationSearchModal(
                                  destinations: widget.destinations,
                                ),
                              ),
                            );
                            if (result != null && result is Destination) {
                              widget.onStartChanged(result);
                            } else if (result ==
                                AppConstants.typeMapSelection) {
                              widget.onStartChanged(null);
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 5.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: widget.start != null
                                ? Text(widget.start!.name)
                                : Text(" Inicio:"),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.0),
                  Row(
                    children: [
                      Icon(Icons.location_pin, color: Colors.red),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            var result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DestinationSearchModal(
                                  destinations: widget.destinations,
                                ),
                              ),
                            );
                            if (result != null && result is Destination) {
                              widget.onDestChanged(result);
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 5.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: widget.destination != null
                                ? Text(widget.destination!.name)
                                : Text(" Destino:"),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: widget.onSwapPressed,
              icon: Icon(Icons.swap_vert_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
