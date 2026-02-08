import 'package:collection/collection.dart';
import 'package:dart_jts/dart_jts.dart' as jts;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mapa_ule/logic/a_star_algorithm.dart';
import 'package:mapa_ule/models/destination.dart';
import 'package:mapa_ule/logic/read_geojson.dart';
import 'package:mapa_ule/utils/constants.dart';

class NavMeshSystem {
  final ReadGeojson _lector = ReadGeojson();

  final Map<int, Map<jts.Coordinate, List<jts.Coordinate>>> _graphs = {};
  final List<Destination> _allDestinations = [];
  final Map<int, jts.Polygon?> _polygons = {};
  final Map<int, jts.GeometryFactory?> _factories = {};
  final List<int> floors = [];

  Future<void> initialize() async {
    var assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    int floorNumbers = assetManifest
        .listAssets()
        .where((element) => element.startsWith('assets/navmesh/navmesh_'))
        .length;

    floors.addAll(List.generate(floorNumbers, (index) => index));

    for (int i = 0; i < floorNumbers; i++) {
      String jsonNav = await rootBundle.loadString(
        'assets/navmesh/navmesh_$i.geojson',
      );
      String jsonDest = await rootBundle.loadString(
        'assets/destinations/destinos_$i.geojson',
      );

      final navData = await _lector.processNavMesh(jsonNav);
      _graphs[i] = navData['graph'];
      _polygons[i] = navData['polygon'];
      _factories[i] = navData['factory'];

      _allDestinations.addAll(
        await _lector.processDestination(
          jsonDest,
          polygon: _polygons[i],
          geomFactory: _factories[i],
        ),
      );
    }
  }

  Future<List<jts.Coordinate>> obtainRoute(
    Destination start,
    Destination destination,
    bool? useElevator,
  ) async {
    int startFloor = start.floor;
    int destinationFloor = destination.floor;
    Map<String, dynamic> params = {};
    if (startFloor == destinationFloor) {
      if (start.zone == destination.zone ||
          start.zone == AppConstants.typeGeneral ||
          destination.zone == AppConstants.typeGeneral) {
        params = {
          'start': start,
          'destination': destination,
          'graph': _graphs[startFloor],
          'polygon': _polygons[startFloor],
          'factory': _factories[startFloor],
        };
      } else {
        Destination? connector = obtainConvinientConnector(
          startFloor,
          start,
          destinationFloor,
          useElevator,
        );
        if (connector == null) {
          return [];
        }
        params = {
          'start': start,
          'destination': connector,
          'graph': _graphs[startFloor],
          'polygon': _polygons[startFloor],
          'factory': _factories[startFloor],
        };
      }
    } else {
      Destination? connector = obtainConvinientConnector(
        startFloor,
        start,
        destinationFloor,
        useElevator,
      );
      if (connector == null) {
        return [];
      }
      params = {
        'start': start,
        'destination': connector,
        'graph': _graphs[startFloor],
        'polygon': _polygons[startFloor],
        'factory': _factories[startFloor],
      };
    }
    return compute(_solveRoute, params);
  }

  List<Destination> obtainDestinations() {
    return _allDestinations.where((d) => !d.isConnector).toList();
  }

  List<Destination> obtainConnectors() {
    return _allDestinations.where((d) => d.isConnector).toList();
  }

  List<int> obtainNumberOfFloors() {
    return floors;
  }

  List<Destination> _obtainConnectorsInSameFloor(
    int floor,
    String zone,
    int destinationFloor,
    bool? useElevator,
  ) {
    return _allDestinations
        .where(
          (d) =>
              d.isConnector &&
              d.floor == floor &&
              d.zone == zone &&
              d.connectedFloors.contains(destinationFloor) &&
              ((useElevator == null ||
                      (d.type == AppConstants.typeElevator && useElevator)) ||
                  (d.type == AppConstants.typeStairs && !useElevator)),
        )
        .toList();
  }

  Destination _obtainNearestConnector(
    Destination point,
    List<Destination> connectors,
  ) {
    Destination nearestConnector = connectors[0];
    double minDistance = double.infinity;
    for (Destination connector in connectors) {
      double distance = point.coordinate.distance(connector.coordinate);
      if (distance < minDistance) {
        nearestConnector = connector;
        minDistance = distance;
      }
    }
    return nearestConnector;
  }

  Destination? obtainConvinientConnector(
    int startFloor,
    Destination start,
    int destinationFloor,
    bool? useElevator,
  ) {
    List<Destination> connectors = _obtainConnectorsInSameFloor(
      startFloor,
      start.zone,
      destinationFloor,
      useElevator,
    );
    if (connectors.isEmpty) {
      return _findHubConnector(startFloor, destinationFloor, start);
    } else {
      return _obtainNearestConnector(start, connectors);
    }
  }

  Destination? _findHubConnector(
    int startFloor,
    int destinationFloor,
    Destination startPoint,
  ) {
    Set<int> possibleStartFloors = {};
    Set<int> possibleDestinationFloors = {};

    var possibleStartConnectors = obtainConnectors().where(
      (d) => d.floor == startFloor,
    );
    var possibleDestinationConnectors = obtainConnectors().where(
      (d) => d.floor == destinationFloor,
    );

    for (Destination connector in possibleStartConnectors) {
      for (var d in connector.connectedFloors) {
        possibleStartFloors.add(d);
      }
    }
    for (Destination connector in possibleDestinationConnectors) {
      for (var d in connector.connectedFloors) {
        possibleDestinationFloors.add(d);
      }
    }
    var hubFloor = possibleStartFloors.firstWhereOrNull(
      (d) => possibleDestinationFloors.contains(d),
    );
    if (hubFloor == null) return null;
    List<Destination> hubConnectors = possibleStartConnectors
        .where((c) => c.connectedFloors.contains(hubFloor))
        .toList();
    return _obtainNearestConnector(startPoint, hubConnectors);
  }

  Destination? obtainNearestDestinationToClick(
    List<Destination> destinations,
    jts.Coordinate point,
  ) {
    Destination nearestDestination = destinations[0];
    double minDistance = double.infinity;
    for (Destination destination in destinations) {
      double distance = point.distance(destination.coordinate);
      if (distance < minDistance) {
        nearestDestination = destination;
        minDistance = distance;
      }
    }
    return nearestDestination;
  }

  // Función pública para ajustar una coordenada al polígono válido más cercano
  jts.Coordinate getSnappedPoint(jts.Coordinate coord, int floor) {
    jts.Polygon? floorPolygon = _polygons[floor];
    jts.GeometryFactory? geomFactory = _factories[floor];
    if (floorPolygon == null || geomFactory == null) return coord;

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
}

List<jts.Coordinate> _solveRoute(Map<String, dynamic> params) {
  var startDest = params['start'] as Destination;
  var destinationDest = params['destination'] as Destination;
  var startCoord = startDest.coordinate;
  var destinationCoord = destinationDest.coordinate;
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

  startCoord = snapToPolygon(startCoord);
  destinationCoord = snapToPolygon(destinationCoord);

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

  if (isVisible(startCoord, destinationCoord)) {
    return [startCoord, destinationCoord];
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

  connectPoint(startCoord);
  connectPoint(destinationCoord);

  List<jts.Coordinate> route = pathFinder.computeRoute(
    startCoord,
    destinationCoord,
    tempGraph,
  );

  List<jts.Coordinate> optimizeRoute(List<jts.Coordinate> route) {
    List<jts.Coordinate> optimizedRoute = [];
    optimizedRoute.add(route[0]);
    int pivot = 0;
    for (int i = pivot + 2; i < route.length; i++) {
      if (!isVisible(route[pivot], route[i])) {
        optimizedRoute.add(route[i - 1]);
        pivot = i - 1;
      }
    }
    optimizedRoute.add(route[route.length - 1]);
    return optimizedRoute;
  }

  return optimizeRoute(route);
}
