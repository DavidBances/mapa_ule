import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapa_ule/models/destination.dart';
import 'package:mapa_ule/utils/constants.dart';

class MarkerFactory {
  static List<Marker> updateMarkers(
    Destination? start,
    Destination? destination,
    int currentFloor,
  ) {
    return [
      if (start != null && start.floor == currentFloor)
        Marker(
          key: const ValueKey('start'),
          point: LatLng(start.coordinate.y, start.coordinate.x),
          child: const Icon(Icons.circle, color: Colors.black, size: 15),
          width: 40,
          height: 40,
          rotate: true,
        ),
      if (destination != null && destination.floor == currentFloor)
        Marker(
          key: const ValueKey('dest'),
          point: LatLng(destination.coordinate.y, destination.coordinate.x),
          child: destination.isConnector
              ? const Icon(Icons.flag_rounded, color: Colors.yellow, size: 40)
              : const Icon(Icons.location_pin, color: Colors.red, size: 40),
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
        case AppConstants.typeLibrary:
          markers.add(
            Marker(
              point: point,
              child: Icon(Icons.menu_book_rounded),
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
              style: TextStyle(fontSize: 10, color: Colors.grey[900]),
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
