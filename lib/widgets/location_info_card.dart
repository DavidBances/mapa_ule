import 'package:flutter/material.dart';

class LocationInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onGoPressed;
  final VoidCallback onClosePressed;

  const LocationInfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onGoPressed,
    required this.onClosePressed,
  });

  @override
  Widget build(BuildContext context) {
    return drawLocationInfoCard();
  }

  Card drawLocationInfoCard() {
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
                    title,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: Colors.redAccent[700]),
                  onPressed: onClosePressed,
                ),
              ],
            ),
            SizedBox(height: 10.0),
            Text(
              subtitle,
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
              onPressed: onGoPressed,
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
