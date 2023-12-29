import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'RaceDetails.dart';
import 'functions.dart';
import 'BottomNavigationBar.dart';

class RaceList extends StatefulWidget {
  final String accessToken;

  const RaceList({Key? key, required this.accessToken}) : super(key: key);

  @override
  _RaceListState createState() => _RaceListState();
}

class _RaceListState extends State<RaceList> {
  List<Race> itemList = [];
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchRaceList();
  }

  Future<void> fetchRaceList() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/rider/race/'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> races = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        itemList = races.map((race) => Race.fromJson(race)).toList();
      });
    } else {
      throw Exception('Failed to load races');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dostępne wyścigi'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: RefreshIndicator(
          onRefresh: fetchRaceList,
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
                            builder: (context) => RaceDetails(itemList[index].id, accessToken: widget.accessToken,),
                          ),
                        );
                      },
                      child: ColorFiltered(colorFilter: ColorFilter.mode(
                        itemList[index].status == 'ended' ? Theme.of(context).colorScheme.surface.withOpacity(0.62) : Colors.transparent,
                        BlendMode.srcOver,
                      ),
                        child: Card(
                          margin: const EdgeInsets.all(5.0),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 160.0,
                                width: double.infinity,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16.0),
                                    topRight: Radius.circular(16.0),
                                  ),
                                  child: itemList[index].eventGraphic.contains("/")
                                      ? Image.network(
                                    'http://10.0.2.2${itemList[index].eventGraphic}',
                                    fit: BoxFit.fitWidth,
                                  )
                                      : Image.asset(
                                    'lib/sample_image.png',
                                    fit: BoxFit.fitWidth,
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
                                    const SizedBox(height: 5.0),
                                    Text(
                                      '${formatDateString(itemList[index].timeStart)}-${formatDateStringToHours(itemList[index].timeEnd)}',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
          switch (currentIndex) {
            case 0:
              // RaceList
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/ranking', arguments: widget.accessToken);
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

class Race {
  final int id;
  final String name;
  final String status;
  final String eventGraphic;
  final String timeStart;
  final String timeEnd;

  Race({required this.id, required this.name, required this.status, required this.eventGraphic, required this.timeStart, required this.timeEnd});

  factory Race.fromJson(Map<String, dynamic> json) {
    return Race(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      eventGraphic: json['event_graphic_file'],
      timeStart: json['start_timestamp'],
      timeEnd: json['end_timestamp'],
    );
  }
}
