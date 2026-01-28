import 'package:dart_jts/dart_jts.dart' as jts;

class Destination {
  final String name;
  final jts.Coordinate coordinate;

  Destination({required this.name, required this.coordinate});

  @override
  String toString() => "$name [${coordinate.x}, ${coordinate.y}]";
}
