import 'package:dart_jts/dart_jts.dart' as jts;
import 'package:flutter_map/flutter_map.dart';
import 'package:mapa_ule/models/destination.dart';

class MapState {
  bool isLoading = true;
  Destination? start;
  Destination? destination;
  Destination? plannerStart;
  Destination? selectedDestination;
  List<jts.Coordinate> route = [];
  List<Marker> markers = [];
  List<Marker> poiMarkers = [];
  List<Marker> labelMarkers = [];
  List<Destination> destinations = [];
  List<Destination> connectors = [];
  List<int> floors = [];
  int distance = 0;
  int time = 0;
  int currentFloor = 0;
  bool onRoute = false;
  bool isPlanningMode = false;
  bool useElevator = false;
  String errorMessage = '';

  MapState({
    this.isLoading = true,
    this.start,
    this.destination,
    this.plannerStart,
    this.selectedDestination,
    this.route = const [],
    this.markers = const [],
    this.poiMarkers = const [],
    this.labelMarkers = const [],
    this.destinations = const [],
    this.connectors = const [],
    this.floors = const [],
    this.distance = 0,
    this.time = 0,
    this.currentFloor = 0,
    this.onRoute = false,
    this.isPlanningMode = false,
    this.useElevator = false,
    this.errorMessage = '',
  });

  MapState copyWith({
    bool? isLoading,
    Destination? start,
    Destination? destination,
    Destination? plannerStart,
    Destination? selectedDestination,
    List<jts.Coordinate>? route,
    List<Marker>? markers,
    List<Marker>? poiMarkers,
    List<Marker>? labelMarkers,
    List<Destination>? destinations,
    List<Destination>? connectors,
    List<int>? floors,
    int? distance,
    int? time,
    int? currentFloor,
    bool? onRoute,
    bool? isPlanningMode,
    bool? useElevator,
    String? errorMessage,
  }) {
    return MapState(
      isLoading: isLoading ?? this.isLoading,
      start: start ?? this.start,
      destination: destination ?? this.destination,
      plannerStart: plannerStart ?? this.plannerStart,
      selectedDestination: selectedDestination ?? this.selectedDestination,
      route: route ?? this.route,
      markers: markers ?? this.markers,
      poiMarkers: poiMarkers ?? this.poiMarkers,
      labelMarkers: labelMarkers ?? this.labelMarkers,
      destinations: destinations ?? this.destinations,
      connectors: connectors ?? this.connectors,
      floors: floors ?? this.floors,
      distance: distance ?? this.distance,
      time: time ?? this.time,
      currentFloor: currentFloor ?? this.currentFloor,
      onRoute: onRoute ?? this.onRoute,
      isPlanningMode: isPlanningMode ?? this.isPlanningMode,
      useElevator: useElevator ?? this.useElevator,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
