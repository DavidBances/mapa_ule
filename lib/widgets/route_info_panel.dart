import 'package:flutter/material.dart';

class RouteInfoPanel extends StatelessWidget {
  final bool isLoading;
  final bool routeIsEmpty;
  final int distance;
  final String time;
  final VoidCallback onReset;

  const RouteInfoPanel({
    super.key,
    required this.isLoading,
    required this.routeIsEmpty,
    required this.distance,
    required this.time,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return drawRouteInfoPanel();
  }

  Column drawRouteInfoPanel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (isLoading) ...{
          CircularProgressIndicator(),
        } else ...{
          if (routeIsEmpty) ...{
            Center(child: Text("Toca el mapa o busca un destino")),
          } else ...{
            Text(
              "Navegando hacia el destino...",
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            Text(
              "Distancia: $distance m",
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10.0),
            Text(
              "Tiempo aproximado: $time",
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
            ),
            ElevatedButton(
              onPressed: onReset,
              child: Icon(Icons.delete_forever_outlined),
            ),
          },
        },
      ],
    );
  }
}
