import 'dart:convert';
import 'package:dart_jts/dart_jts.dart' as jts;
import 'package:flutter/foundation.dart';
import 'package:mapa_ule/models/destination.dart';
import 'package:turf/turf.dart';

class ReadGeojson {
  // Devuelve un Mapa genérico con todo lo necesario
  Future<Map<String, dynamic>> processNavMesh(String jsonData) {
    return compute(_processNavMeshInternal, jsonData);
  }

  Future<List<Destination>> processDestination(
    String jsonData, {
    jts.Polygon? polygon,
    jts.GeometryFactory? geomFactory,
  }) {
    return compute(_processDestinationsInternal, {
      'json': jsonData,
      'polygon': polygon,
      'factory': geomFactory,
    });
  }

  // Función estática privada que hace el trabajo sucio
  static Map<String, dynamic> _processNavMeshInternal(String jsonData) {
    final geomFactory = jts.GeometryFactory.defaultPrecision();
    jts.Polygon polygonJts = geomFactory.createPolygonEmpty();

    var geojson = GeoJSONObject.fromJson(jsonDecode(jsonData));

    if (geojson is FeatureCollection) {
      var polygonTurf = geojson.features[0].geometry as Polygon;
      var outerBorder = polygonTurf.coordinates[0];

      jts.LinearRing shell = geomFactory.createLinearRing(
        _createShell(outerBorder),
      );

      List<jts.LinearRing> holes = [];

      for (int i = 1; i < polygonTurf.coordinates.length; i++) {
        var innerBorder = polygonTurf.coordinates[i];
        jts.LinearRing hole = geomFactory.createLinearRing(
          _createShell(innerBorder),
        );
        holes.add(hole);
      }

      polygonJts = geomFactory.createPolygon(shell, holes);
    }

    final graph = _buildVisibilityGraph(polygonJts, geomFactory);

    // Devolvemos un mapa simple en lugar de una clase NavMeshData
    return {'graph': graph, 'polygon': polygonJts, 'factory': geomFactory};
  }

  static List<Destination> _processDestinationsInternal(
    Map<String, dynamic> params,
  ) {
    final jsonData = params['json'] as String;
    final polygon = params['polygon'] as jts.Polygon?;
    final geomFactory =
        params['factory'] as jts.GeometryFactory? ??
        jts.GeometryFactory.defaultPrecision();

    List<Destination> destinations = [];
    var geojson = GeoJSONObject.fromJson(jsonDecode(jsonData));
    if (geojson is FeatureCollection) {
      for (var feature in geojson.features) {
        var geometry = feature.geometry as Point;
        var properties = feature.properties;
        var coord = jts.Coordinate(
          geometry.coordinates.lng.toDouble(),
          geometry.coordinates.lat.toDouble(),
        );

        if (polygon != null) {
          var point = geomFactory.createPoint(coord);
          if (!polygon.covers(point)) {
            continue;
          }
        }

        String name = properties?['nombre'] ?? 'Sin nombre';
        int floor = properties?['planta'] ?? 0;
        String type = properties?['tipo'] ?? 'general';
        String zone = properties?['zona'] ?? 'general';
        var rawFloors = properties?['plantas_conectadas'];
        List<int> connectedFloors = [];
        if (rawFloors != null &&
            rawFloors.toString() != 'null' &&
            rawFloors.toString().trim().isNotEmpty) {
          connectedFloors = rawFloors
              .toString()
              .split(',')
              .map((e) => int.tryParse(e.trim()))
              .where((e) => e != null)
              .cast<int>()
              .toList();
        }
        destinations.add(
          Destination(
            name: name,
            coordinate: coord,
            floor: floor,
            type: type,
            zone: zone,
            connectedFloors: connectedFloors,
          ),
        );
      }
    }
    return destinations;
  }

  static List<jts.Coordinate> _createShell(List<Position> border) {
    List<jts.Coordinate> jtsCoordinates = [];

    for (int i = 0; i < border.length; i++) {
      var coord = jts.Coordinate(
        border[i].lng.toDouble(),
        border[i].lat.toDouble(),
      );

      jtsCoordinates.add(coord);
    }

    if (jtsCoordinates.isEmpty || jtsCoordinates.first != jtsCoordinates.last) {
      jtsCoordinates.add(jtsCoordinates.first);
    }
    return jtsCoordinates;
  }

  static Map<jts.Coordinate, List<jts.Coordinate>> _buildVisibilityGraph(
    jts.Polygon jtsPolygon,
    jts.GeometryFactory geomFactory,
  ) {
    Map<jts.Coordinate, List<jts.Coordinate>> graph = {};

    List<jts.Coordinate> allCords = jtsPolygon
        .getCoordinates()
        .toSet()
        .toList();

    const double maxConnectionDistance = 0.0005;

    for (var i = 0; i < allCords.length; i++) {
      for (var j = i + 1; j < allCords.length; j++) {
        var a = allCords[i];
        var b = allCords[j];

        if (a.distance(b) > maxConnectionDistance) {
          continue;
        }

        var segment = geomFactory.createLineString([a, b]);
        if (jtsPolygon.covers(segment)) {
          graph.putIfAbsent(a, () => []).add(b);
          graph.putIfAbsent(b, () => []).add(a);
        }
      }
    }
    return graph;
  }
}
