import 'dart:convert';
import 'package:flutter/material.dart';
import 'BottomNavigationBar.dart';
import 'RaceDetails.dart';
import 'package:http/http.dart' as http;
import 'functions.dart';
import 'package:gpx/gpx.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';

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
  String gpxMapLink = '';
  List<LatLng> points = [];
  late List<Wpt> pointsWpt;
  final mapController = MapController();

  TileLayer get openStreetMapTileLayer => TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
    // Use the recommended flutter_map_cancellable_tile_provider package to
    // support the cancellation of loading tiles.
    tileProvider: CancellableNetworkTileProvider(),
    tileBuilder: context.isDarkMode ? darkModeTileBuilder : null,
  );

  @override
  void initState() {
    super.initState();
    fetchRaceList();
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  void fitMap() {
    mapController.fitCamera(
      CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(pointsWpt.where((e) => e.lat != null && e.lon != null).map((e) => LatLng(e.lat!, e.lon!)).toList()),
          padding: const EdgeInsets.all(32)),
    );
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

  Future<void> fetchRaceDetails(int id) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/rider/race/$id'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> raceDetails = json.decode(utf8.decode(response.bodyBytes));
      if(raceDetails['checkpoints_gpx_file'].contains("/")) {
        gpxMapLink = raceDetails['checkpoints_gpx_file'];
        fetchGpxMap();
      }
    } else {
      throw Exception('Failed to load race details');
    }
  }

  Future<void> fetchGpxMap() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2$gpxMapLink'),
    );

    if (response.statusCode == 200) {
      setState(() {
        Gpx gpxMap = GpxReader().fromString(utf8.decode(response.bodyBytes));
        pointsWpt = gpxMap.trks.first.trksegs.first.trkpts;
        points = gpxMap.trks.first.trksegs.first.trkpts
            .where((element) =>
        element.lat != null &&
            element.lon != null &&
            element.lat!.isFinite &&
            element.lon!.isFinite)
            .map((e) => LatLng(e.lat!, e.lon!))
            .toList();
        fitMap();
      });
    } else {
      throw Exception('Failed to load GPX map');
    }
  }


  @override
  Widget build(BuildContext context) {
    Race? todayRace;
    for (Race race in itemList) {
      if (race.userParticipating && isToday(race.timeStart)) {
        todayRace = race;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel wyścigu'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 3*AppBar().preferredSize.height),
              child: Center(
                child: todayRace != null
                    ? buildTodayRaceWidget(todayRace)
                    : buildDefaultWidget(),
              ),
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
              Navigator.pushReplacementNamed(context, '/race_list', arguments: widget.accessToken);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/ranking', arguments: widget.accessToken);
              break;
            case 2:
              // RaceParticipation
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/user_profile', arguments: widget.accessToken);
              break;
          }
        },
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await fetchRaceList();
    setState(() {});
  }

  Widget buildDefaultWidget() {
    int nextRaceIndex = findNextRaceIndex();

    return Container(
      alignment: Alignment.bottomCenter,
      height: MediaQuery.of(context).size.height - 3*AppBar().preferredSize.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
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
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height/8),
                SizedBox(
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
                const SizedBox(height: 8.0),
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
                        SizedBox(
                          height: 90.0,
                          width: 100.0,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16.0),
                              bottomLeft: Radius.circular(16.0),
                            ),
                            child: itemList[nextRaceIndex].eventGraphic.contains("/")
                                ? Image.network(
                              'http://10.0.2.2${itemList[nextRaceIndex].eventGraphic}',
                              fit: BoxFit.fitHeight,
                            )
                                : Image.asset(
                              'lib/sample_image.png',
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5.0),
                        Expanded(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10.0),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  itemList[nextRaceIndex].name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5.0),
                                Text(
                                  formatDateString(itemList[nextRaceIndex].timeStart),
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
                SizedBox(
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
    fetchRaceDetails(race.id);
    if (race.status == 'pending') {
      DateTime startTime = DateTime.parse(race.timeStart);

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
                children: [
                  SizedBox(
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
                  const SizedBox(height: 8.0),
                  SizedBox(
                    height: 300.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: ColorFiltered(colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.surface.withOpacity(0.62),
                        BlendMode.srcOver,
                      ),
                        child: FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                              initialCenter: const LatLng(52.23202828872916, 21.006132649819673), //Warsaw
                              initialZoom: 13,
                              interactionOptions:
                              InteractionOptions(flags: gpxMapLink.contains("/") ? InteractiveFlag.all : InteractiveFlag.none)),
                          children: [
                            openStreetMapTileLayer,
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: points,
                                  strokeWidth: 3,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  SizedBox(
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
                  const SizedBox(height: 8.0),
                  CountdownTimer(startTime: startTime),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RaceDetails(race.id, accessToken: widget.accessToken,),
                        ),
                      );
                    },
                    child: const Text('Szczegóły wyścigu'),
                  ),
                ],
            ),
        ],
      );
    } else if (race.status == 'in_progress') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              SizedBox(
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
              const SizedBox(height: 16.0),
              SizedBox(
                height: 300.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                          initialCenter: const LatLng(52.23202828872916, 21.006132649819673), //Warsaw
                          initialZoom: 13,
                          interactionOptions:
                          InteractionOptions(flags: gpxMapLink.contains("/") ? InteractiveFlag.all : InteractiveFlag.none)),
                      children: [
                        openStreetMapTileLayer,
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: points,
                              strokeWidth: 3,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    raceStarted = !raceStarted;
                  });
                },
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(double.infinity, 50.0),
                ),
                child: Text(
                    raceStarted ? 'Zakończ wyścig' : 'Rozpocznij wyścig!',
                    style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
        ],
      );
    } else if (race.status == 'ended') {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'tutaj powinien być ranking wyścigu',
            style: TextStyle(fontSize: 20.0),
          ),
        ],
      );
    } else {
      return buildDefaultWidget();
    }
  }
}

class CountdownTimer extends StatelessWidget {
  final DateTime startTime;

  const CountdownTimer({super.key, required this.startTime});

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

      await Future.delayed(const Duration(seconds: 1));
    }
  }
}

class CountdownCard extends StatelessWidget {
  final String label;
  final String value;
  final double left;
  final double right;

  const CountdownCard({super.key, required this.label, required this.value, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Card(
            margin: EdgeInsets.fromLTRB(left, 0.0, right, 0.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                value,
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
          ),
        ],
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
  final String timeMeetUp;
  final bool userParticipating;

  Race({required this.id, required this.name, required this.status, required this.eventGraphic, required this.timeStart, required this.timeMeetUp, required this.userParticipating});

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
      eventGraphic: json['event_graphic_file'],
      timeStart: json['start_timestamp'],
      timeMeetUp: meetupTimestamp,
      userParticipating: participating,
    );
  }
}