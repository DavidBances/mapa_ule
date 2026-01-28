import 'package:dart_jts/dart_jts.dart' as jts;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
}
