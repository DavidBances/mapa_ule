import 'package:dart_jts/dart_jts.dart' as jts;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapa_ule/models/destination.dart';

class MapUtils {
  static List<Marker> updateMarkers(
    Destination? start,
    Destination? destination,
  ) {
    return [
      if (start != null)
        Marker(
          key: const ValueKey('start'),
          point: LatLng(start.coordinate.y, start.coordinate.x),
          child: const Icon(Icons.circle, color: Colors.black, size: 15),
          width: 40,
          height: 40,
          rotate: true,
        ),
      if (destination != null)
        Marker(
          key: const ValueKey('dest'),
          point: LatLng(destination.coordinate.y, destination.coordinate.x),
          child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
          alignment: Alignment.topCenter,
          width: 40,
          height: 40,
          rotate: true,
        ),
    ];
  }

  static int calculateDistance(List<jts.Coordinate> route) {
    final Distance distanceCalculator = const Distance();
    double total = 0.0;
    if (route.isEmpty) return 0;

    for (int i = 0; i < route.length - 1; i++) {
      total += distanceCalculator.as(
        LengthUnit.Meter,
        LatLng(route[i].y, route[i].x),
        LatLng(route[i + 1].y, route[i + 1].x),
      );
    }
    return total.round();
  }

  static String calculateTime(int doubleDistance) {
    const double speedMetersperMinute = 70.0;
    double time = doubleDistance / speedMetersperMinute;
    int minutes = time.ceil();
    if (minutes < 1) return "< 1 min";
    return "$minutes min";
  }

  static List<Polyline> getRoutePolylines(List<jts.Coordinate> coordinates) {
    List<LatLng> points = [];
    for (var coord in coordinates) {
      points.add(LatLng(coord.y, coord.x));
    }
    return [
      Polyline(points: points, color: Colors.blueAccent, strokeWidth: 5.0),
    ];
  }

  static LatLngBounds getRouteBounds(List<jts.Coordinate> route) {
    if (route.isEmpty) return LatLngBounds(LatLng(0, 0), LatLng(0, 0));

    List<LatLng> routePoints = [];
    for (var coord in route) {
      routePoints.add(LatLng(coord.y, coord.x));
    }
    return LatLngBounds.fromPoints(routePoints);
  }

  static Destination nearestDestinationToClick(
    List<Destination> destinations,
    LatLng destinationPoint,
  ) {
    Destination nearestDestination = destinations[0];
    double minDistance = double.infinity;
    for (Destination destination in destinations) {
      if (destination.coordinate.distance(
            jts.Coordinate(
              destinationPoint.longitude,
              destinationPoint.latitude,
            ),
          ) <
          minDistance) {
        nearestDestination = destination;
        minDistance = destination.coordinate.distance(
          jts.Coordinate(destinationPoint.longitude, destinationPoint.latitude),
        );
      }
    }
    return nearestDestination;
  }
}
