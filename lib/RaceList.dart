// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'RaceDetails.dart';
//
// class RaceList extends StatefulWidget {
//   @override
//   _RaceListState createState() => _RaceListState();
// }
//
// class _RaceListState extends State<RaceList> {
//   List<String> itemList = [];
//
//   @override
//   void initState() {
//     super.initState();
//     // Fetch the list of races when the widget is created
//     fetchRaceList();
//   }
//
//   Future<void> fetchRaceList() async {
//     final response = await http.get(Uri.parse('http://10.0.2.2:8000/api/rider/race/'));
//
//     if (response.statusCode == 200) {
//       // If the server returns a 200 OK response, parse the races from the response
//       final List<dynamic> races = json.decode(utf8.decode(response.bodyBytes));
//       setState(() {
//         itemList = races.map((race) => race['name'].toString()).toList();
//       });
//     } else {
//       // If the server did not return a 200 OK response, throw an exception.
//       throw Exception('Failed to load races');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Scrollbar(
//         child: ListView.builder(
//           itemCount: itemList.length,
//           itemBuilder: (context, index) {
//             return ListTile(
//               contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
//               leading: Container(
//                 width: 60.0,
//                 height: 60.0,
//                 child: Image.asset(
//                   'lib/sample_image.png',
//                   fit: BoxFit.cover,
//                 ),
//               ),
//               title: Text(itemList[index]),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => RaceDetails(itemList[index]),
//                   ),
//                 );
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'RaceDetails.dart';

class RaceList extends StatefulWidget {
  @override
  _RaceListState createState() => _RaceListState();
}

class _RaceListState extends State<RaceList> {
  List<Race> itemList = [];

  @override
  void initState() {
    super.initState();
    // Fetch the list of races when the widget is created
    fetchRaceList();
  }

  Future<void> fetchRaceList() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/api/rider/race'));

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the races from the response
      final List<dynamic> races = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        itemList = races.map((race) => Race.fromJson(race)).toList();
      });
    } else {
      // If the server did not return a 200 OK response, throw an exception.
      throw Exception('Failed to load races');
    }
  }

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
                width: 60.0,
                height: 60.0,
                child: Image.asset(
                  'lib/sample_image.png',
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(itemList[index].name),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RaceDetails(itemList[index].id),
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

class Race {
  final int id;
  final String name;

  Race({required this.id, required this.name});

  factory Race.fromJson(Map<String, dynamic> json) {
    return Race(
      id: json['id'],
      name: json['name'],
    );
  }
}
