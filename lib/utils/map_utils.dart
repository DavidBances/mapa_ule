import 'package:dart_jts/dart_jts.dart' as jts;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapa_ule/models/destination.dart';

class MapUtils {
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

  static int calculateTime(int doubleDistance) {
    const double speedMetersperMinute = 70.0;
    double time = doubleDistance / speedMetersperMinute;
    int minutes = time.ceil();
    if (minutes < 1) return minutes;
    return minutes;
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
