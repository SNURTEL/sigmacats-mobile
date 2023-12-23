import 'package:flutter/material.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigationBarWidget({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt, color: currentIndex == 0 ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.primaryContainer),
          label: 'Wyścigi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.emoji_events, color: currentIndex == 1 ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.primaryContainer),
          label: 'Ranking',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pedal_bike, color: currentIndex == 2 ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.primaryContainer),
          label: 'Aktualny wyścig',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person, color: currentIndex == 3 ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.primaryContainer),
          label: 'Mój profil',
        ),
      ],
      currentIndex: currentIndex,
      selectedItemColor: Theme.of(context).primaryColor,
      onTap: onTap,
    );
  }
}
