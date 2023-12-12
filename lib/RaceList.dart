import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'RaceDetails.dart';
import 'RaceParticipation.dart';
import 'functions.dart';

class RaceList extends StatefulWidget {
  const RaceList({Key? key}) : super(key: key);

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
    final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/rider/race/?rider_id=1'));

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
      appBar: AppBar(
        title: Text('Dostępne wyścigi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Scrollbar(
          child: ListView.builder(
            itemCount: itemList.length,
            itemBuilder: (context, index) {
              return Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RaceDetails(itemList[index].id),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.all(5.0),
                      child: Column(
                        children: [
                          Container(
                            height: 160.0, // Fixed height
                            width: double.infinity, // Fill the available width
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16.0),
                                topRight: Radius.circular(16.0),
                              ),
                              child: Image.asset(
                                'lib/sample_image.png',
                                fit: BoxFit.fitWidth, // Ensure the image fills the container
                              ),
                            ),
                          ),
                          ListTile(
                            contentPadding: const EdgeInsets.all(10.0),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  itemList[index].name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                SizedBox(height: 5.0),
                                Text(
                                  formatDateString(itemList[index].time),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8.0), // Add space between list elements
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RaceParticipation(),
            ),
          );
        },
        label: Text('Rozpocznij wyścig'),
        icon: Icon(Icons.pedal_bike),
      ),
    );
  }
}

class Race {
  final int id;
  final String name;
  final String time;

  Race({required this.id, required this.name, required this.time});

  factory Race.fromJson(Map<String, dynamic> json) {
    return Race(
      id: json['id'],
      name: json['name'],
      time: json['meetup_timestamp'],
    );
  }
}
