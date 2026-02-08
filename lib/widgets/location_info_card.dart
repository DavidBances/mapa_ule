import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapa_ule/providers/map_notifier.dart';

class LocationInfoCard extends ConsumerWidget {
  const LocationInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return drawLocationInfoCard(ref);
  }

  Widget drawLocationInfoCard(WidgetRef ref) {
    if (ref.watch(mapProvider).selectedDestination == null) {
      return SizedBox.shrink();
    }
    return Card(
      color: Colors.white,
      shadowColor: Colors.black,
      margin: EdgeInsets.symmetric(horizontal: 20.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ref.watch(mapProvider).selectedDestination!.name,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: Colors.redAccent[700]),
                  onPressed: ref.read(mapProvider.notifier).resetNavigation,
                ),
              ],
            ),
            SizedBox(height: 10.0),
            Text(
              'Lat: ${ref.watch(mapProvider).selectedDestination!.coordinate.y.toStringAsFixed(5)}, Lng: ${ref.watch(mapProvider).selectedDestination!.coordinate.x.toStringAsFixed(5)}',
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10.0),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigoAccent[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onPressed: ref.read(mapProvider.notifier).activatePlanningMode,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_run_rounded),
                  Text(" IR AQUÍ"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
