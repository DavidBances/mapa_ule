import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapa_ule/providers/map_notifier.dart';

class CancelTripDialog extends ConsumerWidget {
  const CancelTripDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return drawCancelRouteDialog(context, ref);
  }

  Dialog drawCancelRouteDialog(BuildContext context, WidgetRef ref) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded),
                SizedBox(width: 10.0),
                Text('¿Cancelar?'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    ref.read(mapProvider.notifier).resetNavigation();
                    Navigator.pop(context);
                  },
                  child: Text("SI"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("NO"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
