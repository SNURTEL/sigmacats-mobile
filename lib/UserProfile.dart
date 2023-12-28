import 'package:flutter/material.dart';
import 'BottomNavigationBar.dart';

class UserProfile extends StatefulWidget {
  final String accessToken;
  const UserProfile({Key? key, required this.accessToken}) : super(key: key);

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  int currentIndex = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mój profil'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: const Center(
        child: Text('User Profile Content'),
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
              Navigator.pushReplacementNamed(context, '/ranking', arguments: widget.accessToken);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/race_participation', arguments: widget.accessToken);
              break;
            case 3:
              // UserProfile
              break;
          }
        },
      ),
    );
  }
}
