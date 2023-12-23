import 'package:flutter/material.dart';
import 'BottomNavigationBar.dart';

class RaceParticipation extends StatefulWidget {
  const RaceParticipation({Key? key}) : super(key: key);

  @override
  _RaceParticipationState createState() => _RaceParticipationState();
}

class _RaceParticipationState extends State<RaceParticipation> {
  int currentIndex = 2;
  bool raceStarted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Race Participation'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              raceStarted
                  ? 'You have started the race!'
                  : 'You are not participating in the race.',
              style: TextStyle(fontSize: 20.0),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                // Toggle the raceStarted variable
                setState(() {
                  raceStarted = !raceStarted;
                });
              },
              child: Text(raceStarted ? 'Stop' : 'Start'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
          // Handle navigation based on index
          switch (currentIndex) {
            case 0:
            // Wyścigi
              Navigator.pushReplacementNamed(context, '/race_list');
              break;
            case 1:
            // Ranking
              Navigator.pushReplacementNamed(context, '/ranking');
              break;
            case 2:
            // Aktualny wyścig
              break;
            case 3:
            // Mój profil
              Navigator.pushReplacementNamed(context, '/user_profile');
              break;
          }
        },
      ),
    );
  }
}
