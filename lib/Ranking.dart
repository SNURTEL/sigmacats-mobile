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
    List<RiderClassificationLink> scoresLocal = [];
    List<Rider> ridersParsed = [];
    List<ScoreRow> scoreRows = [];

    if (classificationId != 0) {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/rider/rider_classification_link/$classificationId/classification'),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the scores from the response
        final List<dynamic> scores = json.decode(utf8.decode(response.bodyBytes));
        scoresLocal = scores.map((score) => RiderClassificationLink.fromJson(score)).toList();
      } else {
        // If the server did not return a 200 OK response, throw an exception
        throw Exception('Failed to load scores');
      }

      final responseRiders = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/rider/classification/$classificationId/rider'),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );

      if (responseRiders.statusCode == 200) {
        final List<dynamic> riders = json.decode(utf8.decode(responseRiders.bodyBytes));
        ridersParsed = riders.map((rider) => Rider.fromJson(rider)).toList();
      } else {
        throw Exception('Failed to load riders');
      }

      for (RiderClassificationLink score in scoresLocal) {
        for (Rider rider in ridersParsed) {
          if (score.rider_id == rider.id) {
            scoreRows.add(ScoreRow(score: score.score, name: rider.name, surname: rider.surname));
          }
        }
      }
    }
    setState(() {
      this.scoreRows = scoreRows;
    });
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
              ListView.builder(
                itemCount: scoreRows.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(10.0),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${scoreRows[index].name} ${scoreRows[index].surname}",
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 5.0),
                          ],
                        ),
                      )
                    ],
                  );
                },
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

class RiderClassificationLink {
  final int score;
  final int rider_id;
  final int classification_id;

  RiderClassificationLink({required this.score, required this.rider_id, required this.classification_id});

  factory RiderClassificationLink.fromJson(Map<String, dynamic> json) {
    return RiderClassificationLink(
      score: json['score'],
      rider_id: json['rider_id'],
      classification_id: json['classification_id']
    );
  }
}

class Rider {
  final int id;
  final String name;
  final String surname;

  Rider({required this.id, required this.name, required this.surname});

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
        id: json['id'],
        name: json['account']['name'],
        surname: json['account']['surname']
    );
  }
}

class ScoreRow {
  final int score;
  final String name;
  final String surname;

  ScoreRow({required this.score, required this.name, required this.surname});
}