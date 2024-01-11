import 'package:flutter/material.dart';
import 'BottomNavigationBar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Ranking extends StatefulWidget {
  final String accessToken;
  const Ranking({Key? key, required this.accessToken}) : super(key: key);

  @override
  _RankingState createState() => _RankingState();
}

class _RankingState extends State<Ranking> {
  int currentIndex = 1;
  int seasonID = 0;
  List<Classification> classificationsParsed = [];
  String dropdownValue = 'test';

  Future<void> fetchClassifications() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/rider/season/$seasonID/classification'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the classifications from the response
      final List<dynamic> classifications = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        classificationsParsed = classifications.map((classification) => Classification.fromJson(classification)).toList();
      });
    } else {
      // If the server did not return a 200 OK response, throw an exception
      throw Exception('Failed to load classifications');
    }
  }

  Future<void> fetchCurrentSeason() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/rider/season/current'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      final season = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        seasonID = Season.fromJson(season).id;
      });
    } else {
      // If the server did not return a 200 OK response, throw an exception
      throw Exception('Failed to load current season');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCurrentSeason();
    fetchClassifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Ranking'),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        body: ListView(
            children: <Widget> [
              DropdownButton<String>(
                value: dropdownValue,
                icon: const Icon(Icons.arrow_downward),
                elevation: 16,
                style: const TextStyle(color: Colors.deepPurple),
                underline: Container(
                  height: 2,
                  color: Colors.deepPurpleAccent,
                ),
                onChanged: (String? value) {
                  // This is called when the user selects an item.
                  setState(() {
                    dropdownValue = value!;
                  });
                },
                items: classificationsParsed.map((c) => c.name).map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              ListView(
                padding: const EdgeInsets.all(8),
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                children: <Widget>[],
              ),
            ]
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
              Navigator.pushReplacementNamed(context, '/race_list', arguments: widget.accessToken);
              break;
            case 1:
            // Ranking
              break;
            case 2:
            // Aktualny wyścig
              Navigator.pushReplacementNamed(context, '/race_participation', arguments: widget.accessToken);
              break;
            case 3:
            // Mój profil
              Navigator.pushReplacementNamed(context, '/user_profile', arguments: widget.accessToken);
              break;
          }
        },
      ),
    );
  }
}

class Classification {
  final int id;
  final String name;
  final String description;

  Classification({required this.id, required this.name, required this.description});

  factory Classification.fromJson(Map<String, dynamic> json) {
    return Classification(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}

class Season {
  final int id;
  final String name;
  final DateTime startTimestamp;
  final DateTime endTimestamp;

  Season({required this.id, required this.name, required this.startTimestamp, required this.endTimestamp});

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'],
      name: json['name'],
      startTimestamp: json['start_timestamp'],
      endTimestamp: json['end_timestamp'],
    );
  }
}
