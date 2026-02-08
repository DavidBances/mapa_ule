import 'package:dart_jts/dart_jts.dart' as jts;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapa_ule/logic/location_service.dart';
import 'package:mapa_ule/logic/nav_mesh_system.dart';
import 'package:mapa_ule/models/destination.dart';
import 'package:mapa_ule/providers/map_state.dart';
import 'package:mapa_ule/utils/constants.dart';
import 'package:mapa_ule/utils/map_utils.dart';
import 'package:mapa_ule/utils/marker_factory.dart';
import 'package:riverpod/legacy.dart';

class MapNotifier extends StateNotifier<MapState> {
  MapNotifier(super.state);

  final _navMeshSystem = NavMeshSystem();
  final LocationService _locationService = LocationService();

  Future<void> chargeData() async {
    await _navMeshSystem.initialize();
    var destinations = _navMeshSystem.obtainDestinations();
    var connectors = _navMeshSystem.obtainConnectors();
    state = state.copyWith(
      destinations: destinations,
      connectors: connectors,
      poiMarkers: MarkerFactory.processPoiMarkers(
        destinations.where((d) => d.floor == state.currentFloor).toList(),
      ),
      labelMarkers: MarkerFactory.processLabelMarkers(
        destinations.where((d) => d.floor == state.currentFloor).toList(),
      ),

      floors: _navMeshSystem.obtainNumberOfFloors(),

      isLoading: false,
    );
  }

  void _selectPoint(Destination destinationHelper) {
    if (state.isPlanningMode) {
      state.plannerStart == null
          ? state = state.copyWith(plannerStart: destinationHelper)
          : state = state.copyWith(selectedDestination: destinationHelper);
      state = state.copyWith(
        markers: MarkerFactory.updateMarkers(
          state.plannerStart,
          state.selectedDestination,
          state.currentFloor,
        ),
      );
      onFloorChanged(state.currentFloor);
    } else {
      if (state.destination == null) {
        state = state.copyWith(
          selectedDestination: destinationHelper,
          markers: MarkerFactory.updateMarkers(
            state.plannerStart,
            destinationHelper,
            state.currentFloor,
          ),
        );
      }
    }
  }

  //======================================
  //ROUTE LOGIC AND NAVIGATION
  //======================================

  void startNavigation() {
    if (state.plannerStart == null || state.selectedDestination == null) return;
    state = state.copyWith(
      start: state.plannerStart,
      destination: state.selectedDestination,
      onRoute: true,
      isPlanningMode: false,
      poiMarkers: [],
      route: [],
      markers: [],
    );
    onFloorChanged(state.plannerStart!.floor);
  }

  void resetNavigation() {
    state = MapState(
      start: null,
      plannerStart: null,
      destination: null,
      selectedDestination: null,
      route: [],
      markers: MarkerFactory.updateMarkers(null, null, state.currentFloor),
      poiMarkers: MarkerFactory.processPoiMarkers(
        state.destinations.where((d) => d.floor == state.currentFloor).toList(),
      ),
      labelMarkers: MarkerFactory.processLabelMarkers(
        state.destinations.where((d) => d.floor == state.currentFloor).toList(),
      ),
      destinations: state.destinations,
      connectors: state.connectors,
      floors: state.floors,
      isLoading: false,
      onRoute: false,
      isPlanningMode: false,
      distance: 0,
      time: 0,
      currentFloor: state.currentFloor,
      useElevator: false,
    );
  }

  Future<List<jts.Coordinate>> _calculateRouteData(
    Destination? start,
    Destination? destination,
  ) async {
    if (start == null || destination == null) return [];
    var calculatedRoute = await _navMeshSystem.obtainRoute(
      start,
      destination,
      state.useElevator,
    );

    if (calculatedRoute.isEmpty) {
      if (mounted) {
        state = state.copyWith(
          errorMessage:
              "No se pudo encontrar una ruta válida desde este punto.",
        );
      }
      return [];
    } else {
      return calculatedRoute;
    }
  }

  void setPlannerStart(Destination? point) {
    state = state.copyWith(
      plannerStart: point,
      markers: MarkerFactory.updateMarkers(
        point,
        state.selectedDestination,
        state.currentFloor,
      ),
    );
    onFloorChanged(point != null ? point.floor : state.currentFloor);
  }

  void setSelectedDestination(Destination point) {
    state = state.copyWith(
      selectedDestination: point,
      markers: MarkerFactory.updateMarkers(
        state.plannerStart,
        point,
        state.currentFloor,
      ),
    );
    onFloorChanged(point.floor);
  }

  void onFloorChanged(int floor) {
    Destination? tempStart;
    Destination? tempDestination;
    state = state.copyWith(currentFloor: floor);

    var endpoints = MapUtils.getEffectiveEndpoints(
      state.onRoute,
      state.isPlanningMode,
      state.start,
      state.destination,
      state.plannerStart,
      state.selectedDestination,
    );
    if (endpoints != null &&
        endpoints.length == 2 &&
        endpoints[0] != null &&
        endpoints[1] != null) {
      tempStart = endpoints[0];
      tempDestination = endpoints[1];
    }

    if (tempStart == null || tempDestination == null) {
      var pois = MarkerFactory.processPoiMarkers(
        state.destinations.where((d) => d.floor == floor).toList(),
      );
      var labels = MarkerFactory.processLabelMarkers(
        state.destinations.where((d) => d.floor == floor).toList(),
      );

      List<Marker> selectionMarkers = [];

      selectionMarkers.addAll(
        MarkerFactory.updateMarkers(
          state.plannerStart,
          state.selectedDestination,
          floor,
        ),
      );

      state = state.copyWith(
        poiMarkers: pois,
        labelMarkers: labels,
        route: [],
        markers: selectionMarkers,
      );
      return;
    }

    if (tempStart.floor == tempDestination.floor && floor != tempStart.floor) {
      state = state.copyWith(
        poiMarkers: MarkerFactory.processPoiMarkers(
          state.destinations.where((d) => d.floor == floor).toList(),
        ),
        labelMarkers: MarkerFactory.processLabelMarkers(
          state.destinations.where((d) => d.floor == floor).toList(),
        ),
        route: [],
        markers: [],
      );
      return;
    }

    state = state.copyWith(
      poiMarkers: [],
      labelMarkers: MarkerFactory.processLabelMarkers(
        state.destinations.where((d) => d.floor == floor).toList(),
      ),
      route: [],
      markers: [],
    );

    state = state.copyWith(route: []);
    _drawSegment(tempStart, tempDestination, floor);
  }

  Future<void> _drawSegment(
    Destination tempStart,
    Destination tempDestination,
    int floor,
  ) async {
    List<jts.Coordinate> calculatedRoute = [];
    List<Destination> tempMarkers = [];

    if (tempStart.floor == tempDestination.floor &&
        tempStart.floor == floor &&
        tempStart.zone == tempDestination.zone) {
      calculatedRoute = await _calculateRouteData(tempStart, tempDestination);
      tempMarkers = [tempStart, tempDestination];
    } else if (tempStart.floor == tempDestination.floor &&
        tempStart.floor != floor) {
    } else {
      var referenceConnector = _navMeshSystem.obtainConvinientConnector(
        tempStart.floor,
        tempStart,
        tempDestination.floor,
        state.useElevator,
      );

      var twinConnector = MapUtils.findTwinConnector(
        tempStart,
        tempDestination,
        state.connectors,
        state.currentFloor,
        referenceConnector,
      );

      if (twinConnector == null) return;
      var exitConnector = _navMeshSystem.obtainConvinientConnector(
        twinConnector.floor,
        twinConnector,
        tempDestination.floor,
        state.useElevator,
      );
      var pointsForRoute = MapUtils.calculateSegmentEndpoints(
        tempStart,
        tempDestination,
        twinConnector,
        exitConnector,
        state.currentFloor,
      );

      if (pointsForRoute == null) return;

      calculatedRoute = await _calculateRouteData(
        pointsForRoute[0],
        pointsForRoute[1],
      );
      tempMarkers = [pointsForRoute[0], pointsForRoute[1]];
    }

    var distance = MapUtils.calculateDistance(calculatedRoute);
    var time = MapUtils.calculateTime(distance);

    state = state.copyWith(
      route: calculatedRoute,
      distance: distance,
      time: time,
      markers: MarkerFactory.updateMarkers(
        tempMarkers[0],
        tempMarkers[1],
        state.currentFloor,
      ),
    );
  }

  void onNormalTap(LatLng point) {
    var coord = jts.Coordinate(point.longitude, point.latitude);
    var nearestDestination = _navMeshSystem.obtainNearestDestinationToClick(
      state.destinations.where((d) => d.floor == state.currentFloor).toList(),
      coord,
    );
    if (nearestDestination != null &&
        nearestDestination.coordinate.distance(coord) < 0.00004) {
      _selectPoint(nearestDestination);
    }
  }

  void onLongPress(LatLng point) {
    var coord = jts.Coordinate(point.longitude, point.latitude);
    _computeClick(coord);
  }

  void _computeClick(jts.Coordinate point) {
    var snappedCoord = _navMeshSystem.getSnappedPoint(
      point,
      state.currentFloor,
    );
    var destinationHelper = Destination(
      coordinate: snappedCoord,
      floor: state.currentFloor,
    );

    _selectPoint(destinationHelper);
  }

  void selectDestinationFromSearch(Destination point) {
    state = state.copyWith(
      selectedDestination: point,
      markers: MarkerFactory.updateMarkers(
        state.plannerStart,
        point,
        state.currentFloor,
      ),
    );
    if (state.start != null) {
      state = state.copyWith(destination: state.selectedDestination);
      onFloorChanged(state.start!.floor);
    }
  }

  void swapPoints() {
    var tempSelectedDestination = state.plannerStart;
    var tempPlannerStart = state.selectedDestination;

    state = state.copyWith(
      plannerStart: tempPlannerStart,
      selectedDestination: tempSelectedDestination,
      markers: MarkerFactory.updateMarkers(
        tempPlannerStart,
        tempSelectedDestination,
        state.currentFloor,
      ),
    );
    onFloorChanged(state.plannerStart!.floor);
  }

  void activatePlanningMode() {
    state = state.copyWith(isPlanningMode: true, plannerStart: null);
    _calculateRouteData(null, null);
  }

  void selectMovilityWay() {
    state = state.copyWith(useElevator: !state.useElevator);
    onFloorChanged(state.plannerStart!.floor);
  }

  void useMyLocation() async {
    LatLng myLocation = await _locationService.getCurrentLocation();
    try {
      var myLocationDestination = Destination(
        name: AppConstants.myLocationName,
        coordinate: jts.Coordinate(myLocation.longitude, myLocation.latitude),
        floor: 0,
        type: AppConstants.typeGPS,
        zone: AppConstants.typeGeneral,
        connectedFloors: [],
      );
      state = state.copyWith(
        start: myLocationDestination,
        markers: MarkerFactory.updateMarkers(
          myLocationDestination,
          state.destination,
          state.currentFloor,
        ),
      );
    } catch (ex) {
      if (mounted) {
        String msg = ex.toString().replaceAll("Exception: ", "");
        state = state.copyWith(errorMessage: msg);
      }
    }
  }
}

final StateNotifierProvider<MapNotifier, MapState> mapProvider =
    StateNotifierProvider<MapNotifier, MapState>(
      (ref) => MapNotifier(MapState()),
    );
