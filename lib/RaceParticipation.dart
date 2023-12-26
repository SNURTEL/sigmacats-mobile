import 'dart:convert';
import 'package:flutter/material.dart';
import 'BottomNavigationBar.dart';
import 'RaceDetails.dart';
import 'package:http/http.dart' as http;
import 'functions.dart';

class RaceParticipation extends StatefulWidget {
  final String accessToken;
  const RaceParticipation({Key? key, required this.accessToken}) : super(key: key);

  @override
  _RaceParticipationState createState() => _RaceParticipationState();
}

class _RaceParticipationState extends State<RaceParticipation> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();
  int currentIndex = 2;
  bool raceStarted = false;
  List<Race> itemList = [];

  @override
  void initState() {
    super.initState();
    // Fetch the list of races when the widget is created
    fetchRaceList();
  }

  Future<void> fetchRaceList() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/rider/race/'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

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
    // Check if there is a race today in which the user is participating
    Race? todayRace;
    for (Race race in itemList) {
      if (race.userParticipating && isToday(race.timeStart)) {
        todayRace = race;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Panel wyścigu'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              child: Center(
                child: todayRace != null
                    ? buildTodayRaceWidget(todayRace)
                    : buildDefaultWidget(),
              ),
              //color: Colors.green,
              constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 3*AppBar().preferredSize.height),
              //height: MediaQuery.of(context).size.height - 3*AppBar().preferredSize.height,
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
          // Handle navigation based on index
          switch (currentIndex) {
            case 0:
            // Wyścigi
              Navigator.pushReplacementNamed(context, '/race_list', arguments: widget.accessToken);
              break;
            case 1:
            // Ranking
              Navigator.pushReplacementNamed(context, '/ranking', arguments: widget.accessToken);
              break;
            case 2:
            // Aktualny wyścig
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

  Future<void> _handleRefresh() async {
    // Reload the data here
    await fetchRaceList();
    // Trigger a rebuild of the current page
    setState(() {});
  }

  Widget buildDefaultWidget() {
    int nextRaceIndex = findNextRaceIndex();

    // Display message if no race is found
    return Container(
      alignment: Alignment.bottomCenter, // Align the widget to the bottom center
      height: MediaQuery.of(context).size.height - 3*AppBar().preferredSize.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: double.infinity,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Na dzisiaj nie masz zaplanowanych żadnych wyścigów',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (nextRaceIndex != -1)
          // Display race details
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height/8),
                Container(
                  width: double.infinity,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Twój najbliższy wyścig:',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.0),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RaceDetails(itemList[nextRaceIndex].id, accessToken: widget.accessToken,),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.all(5.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 90.0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16.0),
                              bottomLeft: Radius.circular(16.0),
                            ),
                            child: Image.asset(
                              'lib/sample_image.png',
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.0),
                        Expanded(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10.0),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  itemList[nextRaceIndex].name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                SizedBox(height: 5.0),
                                Text(
                                  '${formatDateString(itemList[nextRaceIndex].timeStart)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height/5),
                Container(
                  width: double.infinity,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Możesz zapisać się na wyścig\nw zakładce "Wyścigi"',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }


  int findNextRaceIndex() {
    DateTime today = DateTime.now();
    int closestIndex = -1;
    DateTime closestDate = today;

    for (int i = 0; i < itemList.length; i++) {
      DateTime startDate = DateTime.parse(itemList[i].timeStart);
      if (itemList[i].userParticipating &&
          startDate.isAfter(today) &&
          (closestDate == today || startDate.isBefore(closestDate))) {
        closestIndex = i;
        closestDate = startDate;
      }
    }

    return closestIndex;
  }


  Widget buildTodayRaceWidget(Race race) {
    if (race.status == 'pending') {
      DateTime startTime = DateTime.parse(race.timeStart);

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
                children: [
                  Container(
                    width: double.infinity,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              race.name,
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.0),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.surface.withOpacity(0.62),
                        BlendMode.srcOver,
                      ),
                      child: Image.asset(
                        'lib/sample_image.png',
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Container(
                    width: double.infinity,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Wyścig rozpocznie się za:',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.0),
                  CountdownTimer(startTime: startTime),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to RaceDetails page with the race ID
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RaceDetails(race.id, accessToken: widget.accessToken,),
                        ),
                      );
                    },
                    child: Text('Szczegóły wyścigu'),
                  ),
                ],
            ),
          // Additional widgets for pending status if needed
        ],
      );
    } else if (race.status == 'in_progress') {
      // Display the existing column for in-progress status
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          race.name,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Image.asset(
                  'lib/sample_image.png',
                  fit: BoxFit.fitWidth,
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  // Toggle the raceStarted variable
                  setState(() {
                    raceStarted = !raceStarted;
                  });
                },
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(double.infinity, 50.0), // Set the height to 50.0
                ),
                child: Text(
                    raceStarted ? 'Zakończ wyścig' : 'Rozpocznij wyścig!',
                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
          // Additional widgets for pending status if needed
        ],
      );
    } else if (race.status == 'ended') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'tutaj powinien być ranking wyścigu',
            style: TextStyle(fontSize: 20.0),
          ),
          // Additional widgets for ended status if needed
        ],
      );
    } else {
      // Handle other status scenarios if needed
      return buildDefaultWidget();
    }
  }
}

class CountdownTimer extends StatelessWidget {
  final DateTime startTime;

  CountdownTimer({required this.startTime});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: countdownStream(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          int seconds = snapshot.data!;
          Duration duration = Duration(seconds: seconds);

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CountdownCard(
                label: 'godz.',
                value: duration.inHours.toString().padLeft(2, '0'),
                left: 0.0,
                right: 8.0,
              ),
              Text(
                ':',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              CountdownCard(
                label: 'min',
                value: (duration.inMinutes.remainder(60)).toString().padLeft(2, '0'),
                left: 8.0,
                right: 8.0,
              ),
              Text(
                ':',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              CountdownCard(
                label: 's',
                value: (duration.inSeconds.remainder(60)).toString().padLeft(2, '0'),
                left: 8.0,
                right: 0.0,
              ),
            ],
          );
        } else {
          return Container();
        }
      },
    );
  }

  Stream<int> countdownStream() async* {
    while (true) {
      DateTime currentTime = DateTime.now();
      int remainingSeconds = startTime.difference(currentTime).inSeconds;

      yield remainingSeconds;

      // Update every second
      await Future.delayed(Duration(seconds: 1));
    }
  }
}

class CountdownCard extends StatelessWidget {
  final String label;
  final String value;
  final double left;
  final double right;

  CountdownCard({required this.label, required this.value, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Card(
            margin: EdgeInsets.fromLTRB(left, 0.0, right, 0.0),
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                value,
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
          ),
          // SizedBox(height: 4.0), // Adjust the spacing between the value and label
          // Text(
          //   label,
          //   style: Theme.of(context).textTheme.headlineMedium,
          // ),
        ],
      ),
    );
  }
}

class Race {
  final int id;
  final String name;
  final String status;
  final String timeStart;
  final String timeMeetUp;
  final bool userParticipating;

  Race({required this.id, required this.name, required this.status, required this.timeStart, required this.timeMeetUp, required this.userParticipating});

  factory Race.fromJson(Map<String, dynamic> json) {
    bool participating = false;
    String meetupTimestamp = 'null';
    final String? participationStatus = json['participation_status'];
    if (participationStatus != null){
      participating = true;
    }
    if (json['meetup_timestamp'] != null){
      meetupTimestamp = json['meetup_timestamp'];
    }
    return Race(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      timeStart: json['start_timestamp'],
      timeMeetUp: meetupTimestamp,
      userParticipating: participating,
    );
  }
}