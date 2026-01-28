import 'package:dart_jts/dart_jts.dart' as jts;
import 'package:collection/collection.dart';

class AStarAlgorithm {
  List<jts.Coordinate> computeRoute(
    jts.Coordinate start,
    jts.Coordinate destination,
    Map<jts.Coordinate, List<jts.Coordinate>> graph,
  ) {
    Set<jts.Coordinate> visitedNodes = {};
    Map<jts.Coordinate, jts.Coordinate> fathers = {};

    Map<jts.Coordinate, double> gScore = {};
    Map<jts.Coordinate, double> fScore = {};
    gScore[start] = 0;
    fScore[start] = calcularDistancia(start, destination);

    PriorityQueue<jts.Coordinate> unvisitedNodes = PriorityQueue((a, b) {
      double scoreA = fScore[a] ?? double.infinity;
      double scoreB = fScore[b] ?? double.infinity;
      return scoreA.compareTo(scoreB);
    });

    unvisitedNodes.add(start);

    while (unvisitedNodes.isNotEmpty) {
      jts.Coordinate actualNode = unvisitedNodes.removeFirst();
      if (actualNode == destination) {
        List<jts.Coordinate> route = [];
        while (fathers.containsKey(actualNode)) {
          route.insert(0, actualNode);
          actualNode = fathers[actualNode]!;
        }
        route.insert(0, start);
        return route;
      }
      visitedNodes.add(actualNode);
      for (jts.Coordinate neighbour in graph[actualNode] ?? []) {
        if (visitedNodes.contains(neighbour)) continue;
        double newGScore =
            gScore[actualNode]! + calcularDistancia(actualNode, neighbour);
        if (!unvisitedNodes.contains(neighbour) ||
            newGScore < gScore[neighbour]!) {
          fathers[neighbour] = actualNode;
          gScore[neighbour] = newGScore;
          fScore[neighbour] =
              newGScore + calcularDistancia(neighbour, destination);
          if (!unvisitedNodes.contains(neighbour)) {
            unvisitedNodes.add(neighbour);
          }
        }
      }
    }

    return [];
  }

  double calcularDistancia(jts.Coordinate start, jts.Coordinate destination) {
    return start.distance(destination);
  }
}
