import 'package:flutter/material.dart';
import 'RaceDetails.dart';

class RaceList extends StatelessWidget {
  final List<String> itemList = List.generate(15, (index) => 'Wyścig #$index');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scrollbar(
        child: ListView.builder(
          itemCount: itemList.length,
          itemBuilder: (context, index) {
            return ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              leading: Container(
                width: 60.0, // Set the width as needed
                height: 60.0, // Set the height as needed
                child: Image.asset(
                  'lib/sample_image.png', // Replace with your image path
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(itemList[index]),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RaceDetails(itemList[index]),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}