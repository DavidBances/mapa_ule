import 'package:flutter/material.dart';

class CancelTripDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const CancelTripDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return drawCancelRouteDialog(context);
  }

  Dialog drawCancelRouteDialog(BuildContext context) {
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
                    onConfirm();
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
