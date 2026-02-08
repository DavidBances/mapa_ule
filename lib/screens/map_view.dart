import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:mapa_ule/providers/map_notifier.dart';
import 'package:mapa_ule/utils/constants.dart';
import 'package:mapa_ule/utils/map_utils.dart';
import 'package:mapa_ule/widgets/animators/bottom_card_animator.dart';
import 'package:mapa_ule/widgets/dialogs/arrival_dialog.dart';
import 'package:mapa_ule/widgets/dialogs/cancel_trip_dialog.dart';
import 'package:mapa_ule/widgets/map_controls/floor_selector.dart';
import 'package:mapa_ule/widgets/location_info_card.dart';
import 'package:mapa_ule/widgets/map_layers.dart';
import 'package:mapa_ule/widgets/map_search_bar.dart';
import 'package:mapa_ule/widgets/navigation_card.dart';
import 'package:mapa_ule/widgets/route_planner_inputs.dart';
import 'package:mapa_ule/widgets/route_preview_card.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  final MapController _mapController = MapController();
  ConfettiController _confettiControler = ConfettiController();

  @override
  void initState() {
    super.initState();
    ref.read(mapProvider.notifier).chargeData();
    _confettiControler = ConfettiController(duration: Duration(seconds: 3));
  }

  @override
  void dispose() {
    super.dispose();
    _confettiControler.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);

    ref.listen(mapProvider, (previous, next) {
      if (next.errorMessage.isNotEmpty &&
          next.errorMessage != previous!.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage)));
        mapState.errorMessage = '';
      }

      if (next.route.isNotEmpty && next.route != previous!.route) {
        _centerCameraOnRoute();
      }

      if (next.start != previous?.start &&
          next.start?.type == AppConstants.typeGPS) {
        LatLng myLocation = LatLng(
          next.start!.coordinate.y,
          next.start!.coordinate.x,
        );
        _mapController.move(myLocation, 18.0);
      }
    });

    return Scaffold(
      body: mapState.isLoading
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
          markers: ref.watch(mapProvider).markers,
          poiMarkers: ref.watch(mapProvider).onRoute
              ? []
              : ref.watch(mapProvider).poiMarkers,
          labelMarkers: ref.watch(mapProvider).labelMarkers,
          route: ref.watch(mapProvider).route,
          mapController: _mapController,
          floor: ref.watch(mapProvider).currentFloor,
          onClick: (point) => ref.read(mapProvider.notifier).onNormalTap(point),
          onLongPress: (point) =>
              ref.read(mapProvider.notifier).onLongPress(point),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Column(
            children: [
              _buildTopControls(),
              SizedBox(height: 10),
              _buildFloorSelector(),
            ],
          ),
        ),
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

  Row _buildFloorSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: FloorSelector(
            floors: ref.watch(mapProvider).floors,
            currentFloor: ref.watch(mapProvider).currentFloor,
            onFloorChanged: (floor) =>
                ref.read(mapProvider.notifier).onFloorChanged(floor),
          ),
        ),
      ],
    );
  }

  SafeArea _buildTopControls() {
    if (ref.watch(mapProvider).isPlanningMode &&
        (ref.watch(mapProvider).selectedDestination != null ||
            ref.watch(mapProvider).plannerStart != null)) {
      return SafeArea(
        child: RoutePlannerInputs(
          destination: ref.watch(mapProvider).selectedDestination,
          start: ref.watch(mapProvider).plannerStart,
          onSwapPressed: ref.read(mapProvider.notifier).swapPoints,
          destinations: ref.watch(mapProvider).destinations,
          onStartChanged: (point) =>
              ref.read(mapProvider.notifier).setPlannerStart(point),
          onDestChanged: (point) =>
              ref.read(mapProvider.notifier).setSelectedDestination(point),
        ),
      );
    } else {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: ref.watch(mapProvider).onRoute
              ? SizedBox.shrink()
              : MapSearchBar(
                  destinations: ref.watch(mapProvider).destinations,
                  onSearch: (point) => ref
                      .read(mapProvider.notifier)
                      .selectDestinationFromSearch(point),
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
              onPressed: ref.read(mapProvider.notifier).useMyLocation,
              child: Icon(Icons.my_location),
            ),
          ),
          SizedBox(height: 10.0),
          if (ref.watch(mapProvider).onRoute &&
              ref.watch(mapProvider).route.isNotEmpty) ...{
            BottomCardAnimator(
              child: NavigationCard(
                distance: ref.watch(mapProvider).distance,
                time: ref.watch(mapProvider).time,
                onFinished: _setNavigationFinished,
                onCancel: _showCancelDialog,
                onNextFloor: (floor) =>
                    ref.read(mapProvider.notifier).onFloorChanged(floor),
                nextFloorNumber:
                    (ref.watch(mapProvider).destination != null &&
                        ref.watch(mapProvider).currentFloor !=
                            ref.watch(mapProvider).destination!.floor)
                    ? ref.watch(mapProvider).destination!.floor
                    : null,
              ),
            ),
          } else if (ref.watch(mapProvider).isPlanningMode) ...{
            BottomCardAnimator(
              child: RoutePreviewCard(
                plannerStart: ref.watch(mapProvider).plannerStart,
                selectedDestination: ref.watch(mapProvider).selectedDestination,
                distance: ref.watch(mapProvider).distance,
                time: ref.watch(mapProvider).time,
                isSameFloor:
                    ref.watch(mapProvider).plannerStart?.floor ==
                    ref.watch(mapProvider).selectedDestination?.floor,
                onNavigationStart: ref
                    .read(mapProvider.notifier)
                    .startNavigation,
                onWaySelected: ref.read(mapProvider.notifier).selectMovilityWay,
                isElevatorSelected: ref.watch(mapProvider).useElevator,
                onClose: ref.read(mapProvider.notifier).resetNavigation,
              ),
            ),
          } else if (ref.watch(mapProvider).selectedDestination != null &&
              !ref.watch(mapProvider).onRoute) ...{
            BottomCardAnimator(child: LocationInfoCard()),
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

  void _centerCameraOnRoute() {
    if (ref.watch(mapProvider).route.isNotEmpty) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: MapUtils.getRouteBounds(ref.watch(mapProvider).route),
          padding: EdgeInsets.only(
            top: 200.0,
            bottom: 200.0,
            left: 100,
            right: 100,
          ),
        ),
      );
    }
  }

  //======================================
  //CALLBACKS
  //======================================

  Future<void> _setNavigationFinished() async {
    await showDialog(
      context: context,
      builder: (context) => ArrivalDialog(
        onConfirm: () {
          _confettiControler.play();
          ref.read(mapProvider.notifier).resetNavigation();
        },
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(context: context, builder: (_) => CancelTripDialog());
  }
}
