import 'package:dart_jts/dart_jts.dart' as jts;

class Destination {
  final String name;
  final jts.Coordinate coordinate;
  final int floor;
  final String type;
  final String zone;
  final List<int> connectedFloors;

  Destination({
    this.name = 'Sin nombre',
    required this.coordinate,
    this.floor = 0,
    this.type = 'general',
    this.zone = 'general',
    this.connectedFloors = const [],
  });

  bool get isConnector => type == "ascensor" || type == "escalera";

  @override
  String toString() => "$name: [${coordinate.x}, ${coordinate.y}]: $floor";
}
