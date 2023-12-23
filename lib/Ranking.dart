import 'package:flutter/material.dart';
import 'BottomNavigationBar.dart';

class Ranking extends StatefulWidget {
  const Ranking({Key? key}) : super(key: key);

@override
_RankingState createState() => _RankingState();
}

class _RankingState extends State<Ranking> {
  int currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Ranking App'),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        body: Center(
          // Your widgets can go here
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
              break;
            case 2:
            // Aktualny wyścig
              Navigator.pushReplacementNamed(context, '/race_participation');
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