import 'package:dart_jts/dart_jts.dart' as jts;
import 'package:flutter/material.dart';
import 'package:mapa_ule/logic/location_service.dart';
import 'package:mapa_ule/models/destination.dart';
import 'package:mapa_ule/utils/constants.dart';

class DestinationSearchModal extends StatefulWidget {
  final List<Destination> destinations;

  const DestinationSearchModal({super.key, required this.destinations});

  @override
  State<DestinationSearchModal> createState() => _DestinationSearchModalState();
}

class _DestinationSearchModalState extends State<DestinationSearchModal> {
  List<Destination> destinationsFiltered = [];
  final LocationService _locationService = LocationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      onChanged: (value) => setState(() {
                        value.isNotEmpty
                            ? destinationsFiltered = widget.destinations
                                  .where(
                                    (d) => d.name.trim().toLowerCase().contains(
                                      value.trim().toLowerCase(),
                                    ),
                                  )
                                  .toList()
                            : destinationsFiltered = [];
                      }),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (destinationsFiltered.isEmpty) ...[
                    ListTile(
                      title: Text("Usar mi ubicación"),
                      subtitle: Text(
                        "Debido a que estamos en el interior de un edificio esta opción puede fallar.",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      onTap: () async {
                        var coord = await _locationService.getCurrentLocation();
                        var myLocation = jts.Coordinate(
                          coord.longitude,
                          coord.latitude,
                        );
                        Destination destination = Destination(
                          name: AppConstants.myLocationName,
                          coordinate: myLocation,
                          type: AppConstants.typeGPS,
                        );
                        if (!mounted) return;
                        Navigator.pop(context, destination);
                      },
                    ),
                    ListTile(
                      title: Text("Seleccionar en el mapa:"),
                      onTap: () =>
                          Navigator.pop(context, AppConstants.typeMapSelection),
                    ),
                  ] else
                    ...destinationsFiltered.map(
                      (d) => ListTile(
                        title: Text(d.name),
                        onTap: () {
                          Navigator.pop(context, d);
                        },
                      ),
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
