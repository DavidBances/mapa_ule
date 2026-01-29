import 'package:dart_jts/dart_jts.dart' as jts;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapa_ule/utils/map_utils.dart';

class MapLayers extends StatelessWidget {
  final List<Marker> markers;
  final List<jts.Coordinate> route;
  final MapController mapController;
  final int floor;
  final Function(LatLng) onClick;

  static final LatLngBounds bounds = LatLngBounds(
    LatLng(42.614764802, -5.561775800),
    LatLng(42.613773767, -5.560411363),
  );

  static final LatLngBounds limitBounds = LatLngBounds(
    LatLng(42.6150, -5.5625),
    LatLng(42.6135, -5.5595),
  );

  static final LatLng initialCenter = LatLng(42.614434, -5.561000);

  const MapLayers({
    super.key,
    required this.markers,
    required this.route,
    required this.mapController,
    required this.floor,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return drawMap();
  }

  FlutterMap drawMap() {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        //cameraConstraint: CameraConstraint.contain(bounds: limitBounds),
        minZoom: 10.0,
        maxZoom: 20.0,
        initialZoom: 19.0,
        onTap: (tapPosition, point) {
          onClick(point);
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
              imageProvider: AssetImage(
                'assets/images/Planta_${floor}_final.png',
              ),
              bounds: bounds,
            ),
          ],
        ),
        PolylineLayer(polylines: MapUtils.getRoutePolylines(route)),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
