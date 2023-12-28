import 'package:flutter/material.dart';
import 'BottomNavigationBar.dart';

class Ranking extends StatefulWidget {
  final String accessToken;
  const Ranking({Key? key, required this.accessToken}) : super(key: key);

@override
_RankingState createState() => _RankingState();
}

class _RankingState extends State<Ranking> {
  int currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Ranking'),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        body: const Center(
        ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
          switch (currentIndex) {
            case 0:
              Navigator.pushReplacementNamed(context, '/race_list', arguments: widget.accessToken);
              break;
            case 1:
              // Ranking
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/race_participation', arguments: widget.accessToken);
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/user_profile', arguments: widget.accessToken);
              break;
          }
        },
      ),
    );
  }
}