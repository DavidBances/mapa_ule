import 'package:collection/collection.dart';
import 'package:dart_jts/dart_jts.dart' as jts;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:mapa_ule/models/destination.dart';
import 'package:mapa_ule/utils/map_utils.dart';
import 'package:mapa_ule/logic/nav_mesh_system.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:geolocator/geolocator.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final navMeshSystem = NavMeshSystem();
  bool isLoading = true;
  LatLng? start;
  LatLng? destination;
  List<jts.Coordinate> route = [];
  List<Marker> markers = [];
  List<Destination> destinations = [];
  int distance = 0;
  String time = "0";

  LatLngBounds bounds = LatLngBounds(
    LatLng(42.614764802, -5.561775800),
    LatLng(42.613773767, -5.560411363),
  );

  LatLngBounds limitBounds = LatLngBounds(
    LatLng(42.6150, -5.5625),
    LatLng(42.6135, -5.5595),
  );

  LatLng initialCenter = LatLng(42.614434, -5.561000);

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _chargeData();
  }

  Future<void> _chargeData() async {
    await navMeshSystem.initialize();
    destinations = navMeshSystem.obtainDestinations();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _useMyLocation,
        child: Icon(Icons.my_location),
      ),
      body: SlidingUpPanel(
        minHeight: 0.0,
        maxHeight: 200.0,
        panel: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (isLoading) ...{
              CircularProgressIndicator(),
            } else ...{
              if (route.isEmpty) ...{
                Center(child: Text("Toca el mapa o busca un destino")),
              } else ...{
                Text(
                  "Navegando hacia el destino...",
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10.0),
                Text(
                  "Distancia: $distance m",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 10.0),
                Text(
                  "Tiempo aproximado: $time",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
                ),
                ElevatedButton(
                  onPressed: _resetNavigation,
                  child: Icon(Icons.delete_forever_outlined),
                ),
              },
            },
          ],
        ),
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                //cameraConstraint: CameraConstraint.contain(bounds: limitBounds),
                minZoom: 10.0,
                maxZoom: 20.0,
                initialZoom: 19.0,
                onTap: (tapPosition, point) {
                  _computeClick(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.david.mapaUle',
                ),
                OverlayImageLayer(
                  overlayImages: [
                    OverlayImage(
                      imageProvider: AssetImage('assets/Planta_0_final.png'),
                      bounds: bounds,
                    ),
                  ],
                ),
                PolylineLayer(polylines: MapUtils.getRoutePolylines(route)),
                MarkerLayer(markers: markers),
              ],
            ),
            Positioned(
              right: 20,
              left: 20,
              child: SafeArea(
                child: Container(
                  margin: EdgeInsets.all(10.0),
                  padding: EdgeInsets.all(10.0),
                  width: double.infinity,
                  alignment: Alignment.topCenter,
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
                  child: Autocomplete(
                    fieldViewBuilder:
                        (
                          context,
                          textEditingController,
                          focusNode,
                          onFieldSubmitted,
                        ) {
                          return TextFormField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: 'Buscar destino',
                              prefixIcon: IconButton(
                                icon: Icon(Icons.search),
                                onPressed: () {
                                  if (textEditingController.text.isNotEmpty) {
                                    var match = destinations.firstWhereOrNull(
                                      (d) => d.name.toLowerCase().contains(
                                        textEditingController.text
                                            .toLowerCase(),
                                      ),
                                    );
                                    if (match != null) {
                                      _selectDestinationFromSearch(
                                        LatLng(
                                          match.coordinate.y,
                                          match.coordinate.x,
                                        ),
                                      );
                                      FocusScope.of(context).unfocus();
                                    }
                                  }
                                },
                              ),
                            ),
                            onFieldSubmitted: (value) {
                              if (value.isNotEmpty) {
                                var match = destinations.firstWhereOrNull(
                                  (d) => d.name.toLowerCase().contains(
                                    textEditingController.text.toLowerCase(),
                                  ),
                                );
                                if (match != null) {
                                  _selectDestinationFromSearch(
                                    LatLng(
                                      match.coordinate.y,
                                      match.coordinate.x,
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        },
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Destination>.empty();
                      } else {
                        return destinations.where((destination) {
                          return destination.name.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          );
                        });
                      }
                    },
                    optionsViewBuilder: (context, onSelected, options) => Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: 200,
                            maxWidth: MediaQuery.of(context).size.width,
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final Destination option = options.elementAt(
                                index,
                              );
                              return ListTile(
                                title: Text(option.name),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    displayStringForOption: (Destination option) => option.name,
                    onSelected: (option) => {
                      _selectDestinationFromSearch(
                        LatLng(option.coordinate.y, option.coordinate.x),
                      ),
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reconstruye la lista de marcadores basándose en el estado actual
  void _updateMarkers() {
    markers = [
      if (start != null)
        Marker(
          key: const ValueKey('start'),
          point: start!,
          child: const Icon(Icons.circle, color: Colors.black, size: 15),
          width: 40,
          height: 40,
          rotate: true,
        ),
      if (destination != null)
        Marker(
          key: const ValueKey('dest'),
          point: destination!,
          child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
          alignment: Alignment.topCenter,
          width: 40,
          height: 40,
          rotate: true,
        ),
    ];
  }

  void _setStartPoint(LatLng point) {
    setState(() {
      start = point;
      _updateMarkers();
    });
  }

  void _setDestinationPoint(LatLng point) {
    setState(() {
      destination = point;
      _updateMarkers();
    });
  }

  void _resetNavigation() {
    setState(() {
      start = null;
      destination = null;
      route = [];
      _updateMarkers();
    });
  }

  Future<void> _setRouteOrClear(LatLng start, LatLng destination) async {
    if (route.isEmpty) {
      var calculatedRoute = await navMeshSystem.obtainRoute(
        jts.Coordinate(start.longitude, start.latitude),
        jts.Coordinate(destination.longitude, destination.latitude),
      );
      if (calculatedRoute.isEmpty) {
        _resetNavigation();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "No se pudo encontrar una ruta válida desde este punto.",
              ),
            ),
          );
        }
        return;
      }

      setState(() {
        route = calculatedRoute;
        distance = MapUtils.calculateDistance(route);
        time = MapUtils.calculateTime(distance);
        _centerCameraOnRoute();
      });
    } else {
      _resetNavigation();
    }
  }

  void _centerCameraOnRoute() {
    if (route.isNotEmpty) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: MapUtils.getRouteBounds(route),
          padding: EdgeInsets.all(100.0),
        ),
      );
    }
  }

  void _computeClick(LatLng point) {
    var coord = jts.Coordinate(point.longitude, point.latitude);
    var snappedCoord = navMeshSystem.getSnappedPoint(coord);
    LatLng finalPoint = LatLng(snappedCoord.y, snappedCoord.x);

    if (route.isNotEmpty) {
      _resetNavigation();
    }
    if (start == null) {
      _setStartPoint(finalPoint);
    } else if (destination == null) {
      _setDestinationPoint(finalPoint);
    }
    if (start != null && destination != null) {
      _setRouteOrClear(start!, destination!);
    }
  }

  void _selectDestinationFromSearch(LatLng point) {
    _setDestinationPoint(point);
    if (start != null) {
      _setRouteOrClear(start!, destination!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "📍 Destino fijado. Ahora toca el mapa para indicar dónde estás.",
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _useMyLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("El GPS está desactivado")));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition();
      LatLng myLocation = LatLng(position.latitude, position.longitude);
      _mapController.move(myLocation, 18.0);
      _setStartPoint(myLocation);
    } catch (ex) {
      print("Error obteniendo GPS: $ex");
    }
  }
}
