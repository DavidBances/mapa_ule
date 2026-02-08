import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapa_ule/screens/map_view.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MaterialApp(
        home: MapView(),
        title: "Prueba APP ULE",
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}
