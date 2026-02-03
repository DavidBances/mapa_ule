import 'package:collection/collection.dart';
import 'package:dart_jts/dart_jts.dart' as jts;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:mapa_ule/logic/location_service.dart';
import 'package:mapa_ule/models/destination.dart';
import 'package:mapa_ule/utils/constants.dart';
import 'package:mapa_ule/utils/map_utils.dart';
import 'package:mapa_ule/logic/nav_mesh_system.dart';
import 'package:mapa_ule/utils/marker_factory.dart';
import 'package:mapa_ule/widgets/animators/bottom_card_animator.dart';
import 'package:mapa_ule/widgets/dialogs/arrival_dialog.dart';
import 'package:mapa_ule/widgets/dialogs/cancel_trip_dialog.dart';
import 'package:mapa_ule/widgets/floor_selector.dart';
import 'package:mapa_ule/widgets/location_info_card.dart';
import 'package:mapa_ule/widgets/map_layers.dart';
import 'package:mapa_ule/widgets/map_search_bar.dart';
import 'package:mapa_ule/widgets/navigation_card.dart';
import 'package:mapa_ule/widgets/route_planner_inputs.dart';
import 'package:mapa_ule/widgets/route_preview_card.dart';
import 'package:confetti/confetti.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final _navMeshSystem = NavMeshSystem();
  bool _isLoading = true;
  Destination? _start;
  Destination? _destination;
  Destination? _plannerStart;
  Destination? _selectedDestination;
  List<jts.Coordinate> _route = [];
  List<Marker> _markers = [];
  List<Marker> _poiMarkers = [];
  List<Marker> _labelMarkers = [];
  List<Destination> _destinations = [];
  List<Destination> _connectors = [];
  List<int> _floors = [];
  int _distance = 0;
  int _time = 0;
  int _currentFloor = 0;
  bool _onRoute = false;
  bool _isPlanningMode = false;
  bool _useElevator = false;

  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  ConfettiController _confettiControler = ConfettiController();

  @override
  void initState() {
    super.initState();
    _chargeData();
    _confettiControler = ConfettiController(duration: Duration(seconds: 3));
  }

  @override
  void dispose() {
    super.dispose();
    _confettiControler.dispose();
  }

  Future<void> _chargeData() async {
    await _navMeshSystem.initialize();
    _destinations = _navMeshSystem.obtainDestinations();
    _connectors = _navMeshSystem.obtainConnectors();
    _poiMarkers = MarkerFactory.processPoiMarkers(
      _destinations.where((d) => d.floor == _currentFloor).toList(),
    );
    _labelMarkers = MarkerFactory.processLabelMarkers(
      _destinations.where((d) => d.floor == _currentFloor).toList(),
    );
    _floors = _navMeshSystem.obtainNumberOfFloors();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _mapView(),
    );
  }

  //======================================
  //HELPERS
  //======================================

  Stack _mapView() {
    return Stack(
      children: [
        MapLayers(
          markers: _markers,
          poiMarkers: _onRoute ? [] : _poiMarkers,
          labelMarkers: _labelMarkers,
          route: _route,
          mapController: _mapController,
          floor: _currentFloor,
          onClick: _onNormalTap,
          onLongPress: _onLongPress,
        ),
        Positioned(top: 0, left: 0, right: 0, child: _buildTopControls()),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: _buildBottomControls(),
        ),
        _buildConfettiWidget(),
      ],
    );
  }

  SafeArea _buildTopControls() {
    if (_isPlanningMode &&
        (_selectedDestination != null || _plannerStart != null)) {
      return SafeArea(
        child: RoutePlannerInputs(
          destination: _selectedDestination,
          start: _plannerStart,
          onSwapPressed: _swapPoints,
          destinations: _destinations,
          onStartChanged: (Destination? point) {
            setState(() {
              _plannerStart = point;
              _markers = MarkerFactory.updateMarkers(
                _plannerStart,
                _selectedDestination,
              );
              _previewRoute();
            });
          },
          onDestChanged: (Destination point) {
            setState(() {
              _selectedDestination = point;
              _markers = MarkerFactory.updateMarkers(
                _plannerStart,
                _selectedDestination,
              );
              _previewRoute();
            });
          },
        ),
      );
    } else {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: _onRoute
              ? SizedBox.shrink()
              : Row(
                  children: [
                    Expanded(
                      child: MapSearchBar(
                        destinations: _destinations,
                        onSearch: _selectDestinationFromSearch,
                      ),
                    ),
                    SizedBox(width: 10.0),
                    FloorSelector(
                      floors: _floors,
                      currentFloor: _currentFloor,
                      onFloorChanged: _onFloorChanged,
                    ),
                  ],
                ),
        ),
      );
    }
  }

  SizedBox _buildBottomControls() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: FloatingActionButton(
              onPressed: _useMyLocation,
              child: Icon(Icons.my_location),
            ),
          ),
          SizedBox(height: 10.0),
          if (_onRoute && _route.isNotEmpty) ...{
            BottomCardAnimator(
              child: NavigationCard(
                distance: _distance,
                time: _time,
                onFinished: _setNavigationFinished,
                onCancel: _showCancelDialog,
                onNextFloor: _onFloorChanged,
                nextFloorNumber: null,
              ),
            ),
          } else if (_isPlanningMode) ...{
            BottomCardAnimator(
              child: RoutePreviewCard(
                plannerStart: _plannerStart,
                selectedDestination: _selectedDestination,
                distance: _distance,
                time: _time,
                isSameFloor:
                    _plannerStart?.floor == _selectedDestination?.floor,
                onNavigationStart: _startNavigation,
                onWaySelected: _selectMovilityWay,
                isElevatorSelected: _useElevator,
                onClose: () {
                  _resetNavigation();
                },
              ),
            ),
          } else if (_selectedDestination != null && !_onRoute) ...{
            BottomCardAnimator(
              child: LocationInfoCard(
                title: _selectedDestination!.name,
                subtitle:
                    'Lat: ${_selectedDestination!.coordinate.y.toStringAsFixed(5)}, Lng: ${_selectedDestination!.coordinate.x.toStringAsFixed(5)}',
                onGoPressed: _activatePlanningMode,
                onClosePressed: () {
                  _resetNavigation();
                },
              ),
            ),
          } else ...{
            BottomCardAnimator(child: SizedBox.shrink()),
          },
        ],
      ),
    );
  }

  Align _buildConfettiWidget() {
    return Align(
      alignment: AlignmentGeometry.topCenter,
      child: ConfettiWidget(
        numberOfParticles: 100,
        confettiController: _confettiControler,
        blastDirectionality: BlastDirectionality.explosive,
      ),
    );
  }

  //======================================
  //MAP INTERACTIONS
  //======================================

  void _onNormalTap(LatLng point) {
    var coord = jts.Coordinate(point.longitude, point.latitude);
    var nearestDestination = _navMeshSystem.obtainNearestDestinationToClick(
      _destinations.where((d) => d.floor == _currentFloor).toList(),
      coord,
    );
    if (nearestDestination != null &&
        nearestDestination.coordinate.distance(coord) < 0.00004) {
      _selectPoint(nearestDestination);
    }
  }

  void _onLongPress(LatLng point) {
    var coord = jts.Coordinate(point.longitude, point.latitude);
    _computeClick(coord);
  }

  void _computeClick(jts.Coordinate point) {
    var snappedCoord = _navMeshSystem.getSnappedPoint(point, _currentFloor);
    var destinationHelper = Destination(
      coordinate: snappedCoord,
      floor: _currentFloor,
    );

    _selectPoint(destinationHelper);
  }

  void _selectPoint(Destination destinationHelper) {
    if (_isPlanningMode) {
      setState(() {
        _plannerStart == null
            ? _plannerStart = destinationHelper
            : _selectedDestination = destinationHelper;
        _markers = MarkerFactory.updateMarkers(
          _plannerStart,
          _selectedDestination,
        );
        _previewRoute();
      });
    } else {
      if (_destination == null) {
        setState(() {
          _selectedDestination = destinationHelper;
          _markers = MarkerFactory.updateMarkers(null, _selectedDestination);
        });
      }
    }
  }

  //======================================
  //ROUTE LOGIC AND NAVIGATION
  //======================================

  void _startNavigation() {
    if (_plannerStart == null || _selectedDestination == null) return;
    setState(() {
      _onRoute = true;
      _isPlanningMode = false;
      _route = [];
    });
    _setStartPoint(
      LatLng(_plannerStart!.coordinate.y, _plannerStart!.coordinate.x),
    );
    _setDestinationPoint(
      LatLng(
        _selectedDestination!.coordinate.y,
        _selectedDestination!.coordinate.x,
      ),
    );
    _setRoute(_start!, _destination!);
    setState(() {
      _isPlanningMode = false;
    });
  }

  Future<void> _setRoute(Destination start, Destination destination) async {
    var calculatedRoute = await _navMeshSystem.obtainRoute(
      start,
      destination,
      null,
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
      _route = calculatedRoute;
      _distance = MapUtils.calculateDistance(_route);
      _time = MapUtils.calculateTime(_distance);
      _centerCameraOnRoute();
      _onRoute = true;
    });
  }

  void _resetNavigation() {
    setState(() {
      _start = null;
      _plannerStart = null;
      _destination = null;
      _selectedDestination = null;
      _route = [];
      _markers = MarkerFactory.updateMarkers(null, null);
      _onRoute = false;
      _isPlanningMode = false;
      _distance = 0;
      _time = 0;
      _useElevator = false;
    });
  }

  Future<void> _previewRoute() async {
    if (_plannerStart == null || _selectedDestination == null) {
      setState(() {
        _route = [];
        _distance = 0;
        _time = 0;
      });
      return;
    }
    var calculatedRoute = await _navMeshSystem.obtainRoute(
      _plannerStart!,
      _selectedDestination!,
      _useElevator,
    );
    setState(() {
      _route = calculatedRoute;
      _distance = MapUtils.calculateDistance(_route);
      _time = MapUtils.calculateTime(_distance);
      _markers = MarkerFactory.updateMarkers(
        _plannerStart,
        _selectedDestination,
      );
    });
  }

  void _centerCameraOnRoute() {
    if (_route.isNotEmpty) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: MapUtils.getRouteBounds(_route),
          padding: EdgeInsets.only(
            top: 200.0,
            bottom: 200.0,
            left: 50,
            right: 50,
          ),
        ),
      );
    }
  }

  void _setStartPoint(LatLng point) {
    setState(() {
      _start = Destination(
        coordinate: jts.Coordinate(point.longitude, point.latitude),
        zone:
            _destinations
                .where((d) => d.floor == _currentFloor)
                .toList()
                .isEmpty
            ? AppConstants.typeGeneral
            : MapUtils.nearestDestinationToClick(
                _destinations.where((d) => d.floor == _currentFloor).toList(),
                point,
              ).zone,
        floor: _currentFloor,
      );
      _markers = MarkerFactory.updateMarkers(_start, _destination);
    });
  }

  void _setDestinationPoint(LatLng point) {
    setState(() {
      _destination = Destination(
        coordinate: jts.Coordinate(point.longitude, point.latitude),
        floor: _currentFloor,
        zone:
            _destinations
                .where((d) => d.floor == _currentFloor)
                .toList()
                .isEmpty
            ? AppConstants.typeGeneral
            : MapUtils.nearestDestinationToClick(
                _destinations.where((d) => d.floor == _currentFloor).toList(),
                point,
              ).zone,
        connectedFloors: [],
      );
      _markers = MarkerFactory.updateMarkers(_start, _destination);
    });
  }

  //======================================
  //CALLBACKS
  //======================================

  void _onFloorChanged(int floor) {
    setState(() {
      _currentFloor = floor;
    });
    if (_onRoute) {
      Destination? startRouteConnector = _connectors.firstWhereOrNull(
        (c) => c.coordinate.distance(_route.last) < 0.0000001,
      );
      if (startRouteConnector == null) return;
      Destination? destinationRouteConnector = _connectors.firstWhereOrNull(
        (c) => c.floor == floor && c.name == startRouteConnector.name,
      );
      if (destinationRouteConnector == null) return;
      setState(() {
        _route = [];
        _start = destinationRouteConnector;
        _markers = MarkerFactory.updateMarkers(_start, _destination!);
      });
      _setRoute(destinationRouteConnector, _destination!);
    }
  }

  void _selectDestinationFromSearch(Destination point) {
    setState(() {
      _selectedDestination = point;
      _markers = MarkerFactory.updateMarkers(
        _plannerStart,
        _selectedDestination,
      );
    });
    if (_start != null) {
      setState(() {
        _destination = _selectedDestination;
      });
      _setRoute(_start!, _destination!);
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

  void _swapPoints() {
    setState(() {
      var temp = _plannerStart;
      _plannerStart = _selectedDestination;
      _selectedDestination = temp;
      _markers = MarkerFactory.updateMarkers(
        _plannerStart,
        _selectedDestination,
      );
      _previewRoute();
    });
  }

  void _activatePlanningMode() {
    setState(() {
      _isPlanningMode = true;
      _plannerStart = null;
      _previewRoute();
    });
  }

  void _selectMovilityWay() {
    setState(() {
      _useElevator = !_useElevator;
      _previewRoute();
    });
  }

  Future<void> _setNavigationFinished() async {
    await showDialog(
      context: context,
      builder: (context) => ArrivalDialog(
        onConfirm: () {
          _confettiControler.play();
          _resetNavigation();
        },
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (_) => CancelTripDialog(onConfirm: _resetNavigation),
    );
  }

  //======================================
  //EXTERNAL SERVICES
  //======================================

  void _useMyLocation() async {
    try {
      LatLng myLocation = await _locationService.getCurrentLocation();
      _mapController.move(myLocation, 18.0);
      setState(() {
        _start = Destination(
          name: AppConstants.myLocationName,
          coordinate: jts.Coordinate(myLocation.longitude, myLocation.latitude),
          floor: 0,
          type: AppConstants.typeGPS,
          zone: AppConstants.typeGeneral,
          connectedFloors: [],
        );
        _markers = MarkerFactory.updateMarkers(_start, _destination);
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
