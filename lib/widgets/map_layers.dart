import 'package:dart_jts/dart_jts.dart' as jts;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapa_ule/utils/map_utils.dart';

class MapLayers extends StatefulWidget {
  final List<Marker> markers;
  final List<Marker> poiMarkers;
  final List<Marker> labelMarkers;
  final List<jts.Coordinate> route;
  final MapController mapController;
  final int floor;
  final Function(LatLng) onClick;
  final Function(LatLng) onLongPress;

  static final LatLngBounds bounds = LatLngBounds(
    LatLng(42.613882, -5.561787),
    LatLng(42.614592, -5.560516),
  );

  const MapLayers({
    super.key,
    required this.markers,
    required this.poiMarkers,
    required this.labelMarkers,
    required this.route,
    required this.mapController,
    required this.floor,
    required this.onClick,
    required this.onLongPress,
  });

  @override
  State<MapLayers> createState() => _MapLayersState();
}

class _MapLayersState extends State<MapLayers> {
  List<Marker> labelMarkersList = [];
  @override
  Widget build(BuildContext context) {
    return drawMap();
  }

  FlutterMap drawMap() {
    var cameraBounds = LatLngBounds(
      LatLng(
        MapLayers.bounds.southWest.latitude - 0.002,
        MapLayers.bounds.southWest.longitude - 0.002,
      ),
      LatLng(
        MapLayers.bounds.northEast.latitude + 0.002,
        MapLayers.bounds.northEast.longitude + 0.002,
      ),
    );
    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: MapLayers.bounds.center,
        cameraConstraint: CameraConstraint.contain(bounds: cameraBounds),
        minZoom: 17.5,
        maxZoom: 21.0,
        initialZoom: 18.5,
        onTap: (tapPosition, point) {
          widget.onClick(point);
        },
        onLongPress: (tapPosition, point) {
          widget.onLongPress(point);
        },
        onPositionChanged: (position, hasGesture) {
          setState(() {
            position.zoom! > 19.0
                ? labelMarkersList = widget.labelMarkers
                : labelMarkersList = [];
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          //urlTemplate: 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
          userAgentPackageName: 'com.david.mapaUle',
        ),
        OverlayImageLayer(
          overlayImages: [
            OverlayImage(
              imageProvider: AssetImage(
                'assets/images/Planta_${widget.floor}_final.png',
              ),
              bounds: MapLayers.bounds,
            ),
          ],
        ),
        PolylineLayer(polylines: MapUtils.getRoutePolylines(widget.route)),
        MarkerLayer(
          markers: widget.route.isEmpty
              ? [...widget.poiMarkers, ...widget.markers, ...labelMarkersList]
              : [...widget.markers, ...labelMarkersList],
        ),
      ],
    );
  }
}
