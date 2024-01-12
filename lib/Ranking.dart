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
  List<ScoreRow> scoreRows = [];
  String dropdownValue = 'Wybierz klasyfikację';

  Future<void> fetchClassifications() async {
    await fetchCurrentSeason();
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/rider/season/$seasonID/classification'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the classifications from the response
      final List<dynamic> classifications = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        classificationsParsed = classifications.map((classification) => Classification.fromJson(classification)).toList();
        classificationsParsed.insert(0, Classification(id: 0, name: 'Wybierz klasyfikację', description: 'brak'));
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

  Future<void> fetchScores(int classificationId) async {
    if (classificationId != 0) {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:8000/api/rider/rider_classification_link/$classificationId/classification'),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the scores from the response
        final List<dynamic> scores = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          scoreRows = scores.map((score) => ScoreRow.fromJson(score)).toList();
        });
      } else {
        // If the server did not return a 200 OK response, throw an exception
        throw Exception('Failed to load scores');
      }
    }
    else {
      setState(() {
        scoreRows = [];
      });
    }
  }

  Color getColor(int index) {
    if (index == 0) {
      return Colors.amber;
    }
    else if (index == 1) {
      return Colors.blueGrey.shade300;
    }
    else if (index == 2) {
      return Colors.deepOrange.shade800;
    }
    else {
      return Colors.white;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchClassifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Ranking'),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        body: Column(
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
                  int classificationId = 0;
                  for (final classification in classificationsParsed) {
                    if (classification.name == value) {
                      classificationId = classification.id;
                    }
                  }
                  fetchScores(classificationId);
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
              Expanded(
                child: ListView.builder(
                  itemCount: scoreRows.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Card(
                            color: getColor(index),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "${scoreRows[index].name} ${scoreRows[index].surname}",
                                      style: Theme.of(context).textTheme.titleMedium,
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                  Text(
                                    "${scoreRows[index].score}",
                                    style: Theme.of(context).textTheme.titleMedium,
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              )
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
  final String startTimestamp;
  final String endTimestamp;

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

class ScoreRow {
  final int score;
  final String name;
  final String surname;

  ScoreRow({required this.score, required this.name, required this.surname});

  factory ScoreRow.fromJson(Map<String, dynamic> json) {
    return ScoreRow(
        score: json['score'],
        name: json['name'],
        surname: json['surname']
    );
  }
}