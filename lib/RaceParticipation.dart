import 'package:flutter/material.dart';

class RaceParticipation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Race Participation'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'You are participating in the race!',
              style: TextStyle(fontSize: 20.0),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                // Navigate back to the RaceList page
                Navigator.pop(context);
              },
              child: Text('Stop'),
            ),
          ],
        ),
      ),
    );
  }
}
