import 'package:dart_jts/dart_jts.dart' as jts;
import 'package:mapa_ule/utils/constants.dart';

class Destination {
  final String name;
  final jts.Coordinate coordinate;
  final int floor;
  final String type;
  final String zone;
  final List<int> connectedFloors;

  Destination({
    this.name = AppConstants.defaultName,
    required this.coordinate,
    this.floor = 0,
    this.type = AppConstants.typeGeneral,
    this.zone = AppConstants.typeGeneral,
    this.connectedFloors = const [],
  });

  bool get isConnector =>
      type == AppConstants.typeElevator || type == AppConstants.typeStairs;

  @override
  String toString() => "$name: [${coordinate.x}, ${coordinate.y}]: $floor";
}
