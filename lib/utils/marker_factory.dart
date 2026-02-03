import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapa_ule/models/destination.dart';
import 'package:mapa_ule/utils/constants.dart';

class MarkerFactory {
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

  static List<Marker> processPoiMarkers(List<Destination> destinations) {
    List<Marker> markers = [];
    for (Destination destination in destinations) {
      var point = LatLng(destination.coordinate.y, destination.coordinate.x);
      switch (destination.type) {
        case AppConstants.typeEntry:
          markers.add(
            Marker(
              point: point,
              child: Icon(Icons.login_rounded),
              rotate: true,
            ),
          );
          break;
        case AppConstants.typeWC:
          markers.add(
            Marker(point: point, child: Icon(Icons.wc_rounded), rotate: true),
          );
          break;
        case AppConstants.typeInfo:
          markers.add(
            Marker(point: point, child: Icon(Icons.info_rounded), rotate: true),
          );
          break;
        case AppConstants.typeRestauration:
          markers.add(
            Marker(
              point: point,
              child: Icon(Icons.coffee_maker_rounded),
              rotate: true,
            ),
          );
          break;
        default:
          break;
      }
    }
    return markers;
  }

  static List<Marker> processLabelMarkers(List<Destination> destinations) {
    List<Marker> markers = [];
    for (Destination destination in destinations) {
      var coord = LatLng(destination.coordinate.y, destination.coordinate.x);
      markers.add(
        Marker(
          point: coord,
          child: Container(
            alignment: Alignment.center,
            child: Text(
              destination.name,
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
          width: 150.0,
          alignment: Alignment.bottomCenter,
          rotate: true,
        ),
      );
    }
    return markers;
  }
}
