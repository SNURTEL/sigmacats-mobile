import 'package:flutter/material.dart';
import 'BottomNavigationBar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:move_to_background/move_to_background.dart';
import 'settings.dart' as settings;

class Ranking extends StatefulWidget {
  final String accessToken;

  const Ranking({Key? key, required this.accessToken}) : super(key: key);

  @override
  _RankingState createState() => _RankingState();
}

class _RankingState extends State<Ranking>{
  int currentIndex = 1;
  int seasonID = 0;
  List<Classification> classificationsParsed = [];
  List<ScoreRow> scoreRows = [];
  List<Season> seasonsParsed = [];
  User currentUser = User(name: 'default', surname: 'default', username: 'd');
  String classificationDropdownValue = 'Klasyfikacja generalna';
  String seasonDropdownValue = 'Wybierz sezon';

  Future<void> fetchClassifications() async {
    if (seasonID != 0) {
      final response = await http.get(
        Uri.parse('${settings.apiBaseUrl}/api/rider/season/$seasonID/classification'),
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
    else {
      setState(() {
        classificationsParsed = [Classification(id: 0, name: 'Wybierz klasyfikację', description: 'brak')];
        classificationDropdownValue = 'Wybierz klasyfikację';
      });
    }
  }

  Future<void> fetchCurrentSeason() async {
    final response = await http.get(
      Uri.parse('${settings.apiBaseUrl}/api/rider/season/current'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      final season = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        seasonID = Season.fromJson(season).id;
      });
    } else {
      throw Exception('Failed to load current season');
    }
  }

  Future<void> fetchSeasons() async {
    final response = await http.get(
      Uri.parse('${settings.apiBaseUrl}/api/rider/season/all'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> seasons = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        seasonsParsed = seasons.map((season) => Season.fromJson(season)).toList();
        seasonsParsed.insert(0, Season(id: 0, name: 'Wybierz sezon', startTimestamp: 'brak', endTimestamp: 'brak'));
      });
    } else {
      throw Exception('Failed to load seasons');
    }
  }
  
  Future<void> fetchCurrentUser() async {
    final response = await http.get(
      Uri.parse('${settings.apiBaseUrl}/api/users/me'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      final user = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        currentUser = User.fromJson(user);
      });
    } else {
      throw Exception('Failed to load current user');
    }
  }

  Future<void> fetchScores(int classificationId) async {
    if (classificationId != 0) {
      final response = await http.get(
        Uri.parse(
            '${settings.apiBaseUrl}/api/rider/rider_classification_link/$classificationId/classification'),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the scores from the response
        final List<dynamic> scores = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          scoreRows = scores.map((score) => ScoreRow.fromJson(score)).toList();
        });
      } else {
        setState(() {
          scoreRows = [];
        });
      }
    }
    else {
      setState(() {
        scoreRows = [];
      });
    }
  }

  Future<void> fetchInitialData() async {
    await fetchCurrentSeason();
    await fetchSeasons();
    setState(() {
      seasonDropdownValue = getSeasonName();
    });
    await fetchClassifications();
    await fetchCurrentUser();
    await fetchScores(getClassificationId('Klasyfikacja generalna'));
  }

  Color getColor(int index) {
    if (index == 0) {
      return Colors.amber;
    }
    else if (index == 1) {
      return Colors.blueGrey.shade300;
    }
    else if (index == 2) {
      return Colors.deepOrange;
    }
    else {
      return Colors.white;
    }
  }

  Color getCardColor(int index) {
    if (scoreRows[index].name == currentUser.name && scoreRows[index].surname == currentUser.surname) {
      return Colors.deepPurple.shade100;
    }
    else {
      return Colors.white;
    }
  }
  
  int getClassificationId(String? name) {
    for (final classification in classificationsParsed) {
      if (classification.name == name) {
        return classification.id;
      }
    }
    return 0;
  }

  String getSeasonName() {
    for (final season in seasonsParsed) {
      if (season.id == seasonID) {
        return season.name;
      }
    }
    return 'Wybierz sezon';
  }

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) {
          return;
        }
        MoveToBackground.moveTaskToBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ranking'),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        body: Column(
            children: <Widget> [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: DropdownButton<String>(
                      value: classificationDropdownValue,
                      icon: const Icon(Icons.arrow_downward),
                      elevation: 16,
                      style: const TextStyle(color: Colors.deepPurple),
                      underline: Container(
                        height: 2,
                        color: Colors.deepPurpleAccent,
                      ),
                      onChanged: (String? value) {
                        int classificationId = getClassificationId(value);
                        fetchScores(classificationId);
                        setState(() {
                          classificationDropdownValue = value!;
                        });
                      },
                      items: classificationsParsed.map((c) => c.name).map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 80),
                    child: DropdownButton<String>(
                      value: seasonDropdownValue,
                      icon: const Icon(Icons.arrow_downward),
                      elevation: 16,
                      style: const TextStyle(color: Colors.deepPurple),
                      underline: Container(
                        height: 2,
                        color: Colors.deepPurpleAccent,
                      ),
                      onChanged: (String? value) {
                        for (final season in seasonsParsed) {
                          if (season.name == value) {
                            setState(() {
                              seasonID = season.id;
                            });
                            break;
                          }
                        }
                        fetchClassifications();
                        setState(() {
                          seasonDropdownValue = value!;
                          classificationDropdownValue = 'Wybierz klasyfikację';
                          scoreRows = [];
                        });
                      },
                      items: seasonsParsed.map((s) => s.name).map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: scoreRows.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                bottom: 16.0,
                                right: 16.0
                              ),
                              child: Text(
                                "${index+1}",
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            Expanded(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Card(
                                    color: getCardColor(index),
                                    margin: const EdgeInsets.only(
                                        right: 16.0,
                                        bottom: 16.0),
                                    shape: RoundedRectangleBorder(
                                        side: BorderSide(color: getColor(index), width: 3.0),
                                        borderRadius: BorderRadius.circular(10.0)
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(0.0),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  scoreRows[index].username,
                                                  style: Theme.of(context).textTheme.titleLarge,
                                                ),
                                                Text(
                                                  "${scoreRows[index].name} ${scoreRows[index].surname}",
                                                  style: Theme.of(context).textTheme.labelMedium,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              "${scoreRows[index].score}",
                                              style: Theme.of(context).textTheme.titleMedium,
                                              textAlign: TextAlign.right,
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            )
                          ],
                        )
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
    )
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
      description: json['description']
    );
  }
}

class Season {
  final int id;
  final String name;
  final String startTimestamp;
  final String? endTimestamp;

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
  final String username;

  ScoreRow({required this.score, required this.name, required this.surname, required this.username});

  factory ScoreRow.fromJson(Map<String, dynamic> json) {
    return ScoreRow(
        score: json['score'],
        name: json['name'],
        surname: json['surname'],
        username: json['username']
    );
  }
}

class User {
  final String name;
  final String surname;
  final String username;
  
  User({required this.name, required this.surname, required this.username});
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
        name: json['name'],
        surname: json['surname'],
        username: json['username']
    );
  }
}