import 'package:collection/collection.dart';
import 'package:dart_jts/dart_jts.dart' as jts;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:mapa_ule/logic/location_service.dart';
import 'package:mapa_ule/models/destination.dart';
import 'package:mapa_ule/utils/map_utils.dart';
import 'package:mapa_ule/logic/nav_mesh_system.dart';
import 'package:mapa_ule/widgets/map_layers.dart';
import 'package:mapa_ule/widgets/map_search_bar.dart';
import 'package:mapa_ule/widgets/route_info_panel.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final navMeshSystem = NavMeshSystem();
  bool isLoading = true;
  Destination? start;
  Destination? destination;
  List<jts.Coordinate> route = [];
  List<Marker> markers = [];
  List<Destination> destinations = [];
  List<Destination> connectors = [];
  List<int> floors = [];
  int distance = 0;
  String time = "0";
  int currentFloor = 0;
  bool onRoute = false;

  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _chargeData();
  }

  Future<void> _chargeData() async {
    await navMeshSystem.initialize();
    destinations = navMeshSystem.obtainDestinations();
    connectors = navMeshSystem.obtainConnectors();
    floors = navMeshSystem.obtainNumberOfFloors();
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
      body: slidingPanel(),
    );
  }

  SlidingUpPanel slidingPanel() {
    return SlidingUpPanel(
      minHeight: 0.0,
      maxHeight: 200.0,
      panel: RouteInfoPanel(
        isLoading: isLoading,
        routeIsEmpty: route.isEmpty,
        distance: distance,
        time: time,
        onReset: _resetNavigation,
      ),
      body: Stack(
        children: [
          MapLayers(
            markers: markers,
            route: route,
            mapController: _mapController,
            floor: currentFloor,
            onClick: _computeClick,
          ),
          MapSearchBar(
            destinations: destinations,
            onSearch: _selectDestinationFromSearch,
          ),
          Positioned(
            right: 20,
            child: DropdownButton(
              items: List<DropdownMenuItem<int>>.generate(floors.length, (
                index,
              ) {
                return DropdownMenuItem(
                  value: floors[index],
                  child: Text("Piso ${floors[index] + 1}"),
                );
              }),
              value: currentFloor,
              focusColor: Colors.blue[800],
              dropdownColor: Colors.blue[200],
              onChanged: (int? value) {
                if (value != null) {
                  onFloorChanged(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void onFloorChanged(int floor) {
    if (onRoute) {
      Destination? startRouteConnector = connectors.firstWhereOrNull(
        (c) => c.coordinate == route.last,
      );
      if (startRouteConnector == null) return;
      Destination? destinationRouteConnector = connectors.firstWhereOrNull(
        (c) => c.floor == floor && c.name == startRouteConnector.name,
      );
      if (destinationRouteConnector == null) return;
      setState(() {
        route = [];
        currentFloor = floor;
        start = destinationRouteConnector;
        markers = MapUtils.updateMarkers(start, destination!);
      });
      _setRouteOrClear(destinationRouteConnector, destination!);
    }
  }

  void _setStartPoint(LatLng point) {
    setState(() {
      start = Destination(
        coordinate: jts.Coordinate(point.longitude, point.latitude),
        zone:
            destinations.where((d) => d.floor == currentFloor).toList().isEmpty
            ? 'general'
            : MapUtils.nearestDestinationToClick(
                destinations.where((d) => d.floor == currentFloor).toList(),
                point,
              ).zone,
        floor: currentFloor,
      );
      markers = MapUtils.updateMarkers(start, destination);
    });
  }

  void _setDestinationPoint(LatLng point) {
    setState(() {
      destination = Destination(
        coordinate: jts.Coordinate(point.longitude, point.latitude),
        floor: currentFloor,
        zone:
            destinations.where((d) => d.floor == currentFloor).toList().isEmpty
            ? 'general'
            : MapUtils.nearestDestinationToClick(
                destinations.where((d) => d.floor == currentFloor).toList(),
                point,
              ).zone,
        connectedFloors: [],
      );
      markers = MapUtils.updateMarkers(start, destination);
    });
  }

  void _resetNavigation() {
    setState(() {
      start = null;
      destination = null;
      route = [];
      markers = MapUtils.updateMarkers(null, null);
      onRoute = false;
    });
  }

  Future<void> _setRouteOrClear(
    Destination start,
    Destination destination,
  ) async {
    if (route.isEmpty) {
      var calculatedRoute = await navMeshSystem.obtainRoute(start, destination);
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
        onRoute = true;
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
    var snappedCoord = navMeshSystem.getSnappedPoint(coord, currentFloor);
    LatLng finalPoint = LatLng(snappedCoord.y, snappedCoord.x);

    if (onRoute || route.isNotEmpty) {
      _resetNavigation();
      return;
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

  void _selectDestinationFromSearch(Destination point) {
    setState(() {
      destination = Destination(
        name: point.name,
        coordinate: point.coordinate,
        floor: point.floor,
        type: point.type,
        zone: point.zone,
        connectedFloors: point.connectedFloors,
      );
      markers = MapUtils.updateMarkers(start, destination);
    });
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
      LatLng myLocation = await _locationService.getCurrentLocation();
      _mapController.move(myLocation, 18.0);
      setState(() {
        start = Destination(
          name: 'Mi ubicación',
          coordinate: jts.Coordinate(myLocation.longitude, myLocation.latitude),
          floor: 0,
          type: 'gps',
          zone: 'general',
          connectedFloors: [],
        );
        markers = MapUtils.updateMarkers(start, destination);
      });
    } catch (ex) {
      if (mounted) {
        String msg = ex.toString().replaceAll("Exception: ", "");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }
}
