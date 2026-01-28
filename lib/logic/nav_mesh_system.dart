import 'package:dart_jts/dart_jts.dart' as jts;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mapa_ule/logic/a_star_algorithm.dart';
import 'package:mapa_ule/models/destination.dart';
import 'package:mapa_ule/logic/read_geojson.dart';

class NavMeshSystem {
  final ReadGeojson _lector = ReadGeojson();

  Map<jts.Coordinate, List<jts.Coordinate>> _staticGraph = {};
  List<Destination> _destinations = [];
  jts.Polygon? _floorPolygon;
  jts.GeometryFactory? _geomFactory;

  Future<void> initialize() async {
    String jsonNav = await rootBundle.loadString('assets/navmesh.geojson');
    String jsonDest = await rootBundle.loadString('assets/destinos.geojson');

    final navData = await _lector.processNavMesh(jsonNav);
    _staticGraph = navData['graph'];
    _floorPolygon = navData['polygon'];
    _geomFactory = navData['factory'];

    // Pasamos el polígono para que el filtrado se haga en el otro hilo
    _destinations = await _lector.processDestination(
      jsonDest,
      polygon: _floorPolygon,
      geomFactory: _geomFactory,
    );
  }

  Future<List<jts.Coordinate>> obtainRoute(
    jts.Coordinate start,
    jts.Coordinate destination,
  ) async {
    final params = {
      'start': start,
      'destination': destination,
      'graph': _staticGraph,
      'polygon': _floorPolygon,
      'factory': _geomFactory,
    };
    return compute(_solveRoute, params);
  }

  List<Destination> obtainDestinations() {
    return _destinations;
  }

  List<List<jts.Coordinate>> getGraphEdges() {
    List<List<jts.Coordinate>> edges = [];
    for (var entry in _staticGraph.entries) {
      var start = entry.key;
      for (var end in entry.value) {
        edges.add([start, end]);
      }
    }
    return edges;
  }

  // Función pública para ajustar una coordenada al polígono válido más cercano
  jts.Coordinate getSnappedPoint(jts.Coordinate coord) {
    if (_floorPolygon == null || _geomFactory == null) return coord;

    var pointGeom = _geomFactory!.createPoint(coord);
    if (!_floorPolygon!.covers(pointGeom)) {
      var op = jts.DistanceOp(pointGeom, _floorPolygon!);
      var nearest = op.nearestPoints();
      if (nearest.length > 1) {
        return nearest[1]; // Devuelve el punto corregido sobre el borde del polígono
      }
    }
    return coord;
  }
}

// Función suelta (top-level) o estática para calcular la ruta
List<jts.Coordinate> _solveRoute(Map<String, dynamic> params) {
  var start = params['start'] as jts.Coordinate;
  var destination = params['destination'] as jts.Coordinate;
  final graph = params['graph'] as Map<jts.Coordinate, List<jts.Coordinate>>;
  final floorPolygon = params['polygon'] as jts.Polygon;
  final geomFactory = params['factory'] as jts.GeometryFactory;

  final pathFinder = AStarAlgorithm();

  jts.Coordinate snapToPolygon(jts.Coordinate coord) {
    var pointGeom = geomFactory.createPoint(coord);
    if (!floorPolygon.covers(pointGeom)) {
      var op = jts.DistanceOp(pointGeom, floorPolygon);
      var nearest = op.nearestPoints();
      if (nearest.length > 1) {
        return nearest[1];
      }
    }
    return coord;
  }

  start = snapToPolygon(start);
  destination = snapToPolygon(destination);

  bool isVisible(jts.Coordinate p1, jts.Coordinate p2) {
    if (p1.equals2D(p2) || p1.distance(p2) < 0.0000001) {
      return true;
    }
    try {
      var line = geomFactory.createLineString([p1, p2]);

      if (!line.isValid()) return false;

      return floorPolygon.covers(line);
    } catch (e) {
      print("Error JTS en isVisible: $e");
      return false;
    }
  }

  if (isVisible(start, destination)) {
    return [start, destination];
  }

  var tempGraph = Map.of(graph);

  void connectPoint(jts.Coordinate point) {
    bool connected = false;
    for (var coord in graph.keys) {
      if (isVisible(point, coord)) {
        tempGraph.putIfAbsent(point, () => []).add(coord);
        var neighbors = List<jts.Coordinate>.from(tempGraph[coord] ?? []);
        neighbors.add(point);
        tempGraph[coord] = neighbors;
        connected = true;
      }
    }
    if (!connected) {
      jts.Coordinate? nearest;
      double minDist = double.infinity;

      for (var coord in graph.keys) {
        double d = point.distance(coord);
        if (d < minDist) {
          minDist = d;
          nearest = coord;
        }
      }

      if (nearest != null) {
        tempGraph.putIfAbsent(point, () => []).add(nearest);
        var neighbors = List<jts.Coordinate>.from(tempGraph[nearest] ?? []);
        neighbors.add(point);
        tempGraph[nearest] = neighbors;
      }
    }
  }

  connectPoint(start);
  connectPoint(destination);

  return pathFinder.computeRoute(start, destination, tempGraph);
}
