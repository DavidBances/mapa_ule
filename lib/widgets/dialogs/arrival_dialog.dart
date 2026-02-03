import 'package:flutter/material.dart';

class ArrivalDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const ArrivalDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return drawArrivalRouteDialog(context);
  }

  Dialog drawArrivalRouteDialog(BuildContext context) {
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
                Icon(Icons.celebration_rounded),
                SizedBox(width: 10.0),
                Text('¿Llegaste a tu destino?'),
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
                  child: Text("DESTINO ALCANZADO"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("NO, AÚN NO"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
