import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sigmactas_alleycat/models/race.dart';
import 'package:sigmactas_alleycat/models/ranking.dart';
import 'package:sigmactas_alleycat/util/dark_mode.dart';
import 'RaceTrackingPage.dart';
import 'RaceDetailsPage.dart';
import 'RankingPage.dart';
import 'package:http/http.dart' as http;
import 'package:gpx/gpx.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:move_to_background/move_to_background.dart';

import 'package:sigmactas_alleycat/components/BottomNavigationBar.dart';
import 'package:sigmactas_alleycat/util/dates.dart';
import 'package:sigmactas_alleycat/util/settings.dart' as settings;

class RaceParticipation extends StatefulWidget {
  ///  Race participation screen widget
  final String accessToken;

  const RaceParticipation({Key? key, required this.accessToken}) : super(key: key);

  @override
  _RaceParticipationState createState() => _RaceParticipationState();
}

class _RaceParticipationState extends State<RaceParticipation> {
  ///  Race participation page state
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  int currentIndex = 2;
  List<Race> itemList = [];
  List<RaceScores> scoreRows = [];
  User currentUser = User(name: 'default', surname: 'default', username: 'd');
  String gpxMapLink = '';
  List<LatLng> points = [];
  late List<Wpt> pointsWpt;
  Race? todayRace;
  final mapController = MapController();

  TileLayer get openStreetMapTileLayer => TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'dev.fleaflet.flutter_map.example',
        tileProvider: CancellableNetworkTileProvider(),
        tileBuilder: context.isDarkMode ? darkModeTileBuilder : null,
      );

  @override
  void initState() {
    super.initState();
    reloadRaces();
  }

  Future<void> reloadRaces() async {
    ///  Reloads races displayed to the user
    fetchRaceList().then((value) {
      for (Race race in itemList) {
        if (race.userParticipating && isToday(race.timeStart)) {
          todayRace = race;
          break;
        }
      }
      if (todayRace != null) {
        fetchRaceDetails(todayRace!.id);
        fetchRaceScores(todayRace!.id);
      }
    });
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  void fitMap() {
    ///  Fits the entire track on the map
    mapController.fitCamera(
      CameraFit.bounds(
          bounds:
              LatLngBounds.fromPoints(pointsWpt.where((e) => e.lat != null && e.lon != null).map((e) => LatLng(e.lat!, e.lon!)).toList()),
          padding: const EdgeInsets.all(32)),
    );
  }

  Future<List<Race>> fetchRaceList() async {
    ///    Fetches list of races to be displayed to the user
    final response = await http.get(
      Uri.parse('${settings.apiBaseUrl}/api/rider/race/'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> races = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        itemList = races.map((race) => Race.fromJson(race)).toList();
      });
      return races.map((race) => Race.fromJson(race)).toList();
    } else {
      throw Exception('Failed to load races: ${response.statusCode}');
    }
  }

  Future<void> fetchRaceDetails(int id) async {
    ///    Fetches details of a given race
    final response = await http.get(
      Uri.parse('${settings.apiBaseUrl}/api/rider/race/$id'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> raceDetails = json.decode(utf8.decode(response.bodyBytes));
      if (raceDetails['checkpoints_gpx_file'].contains("/")) {
        gpxMapLink = raceDetails['checkpoints_gpx_file'];
        fetchGpxMap();
      }
    } else {
      throw Exception('Failed to load race details');
    }
  }

  Future<void> fetchGpxMap() async {
    ///    Fetches gpx file with map of a race
    final response = await http.get(
      Uri.parse('${settings.apiBaseUrl}$gpxMapLink'),
    );

    if (response.statusCode == 200) {
      setState(() {
        Gpx gpxMap = GpxReader().fromString(utf8.decode(response.bodyBytes));
        pointsWpt = gpxMap.trks.first.trksegs.first.trkpts;
        points = gpxMap.trks.first.trksegs.first.trkpts
            .where((element) => element.lat != null && element.lon != null && element.lat!.isFinite && element.lon!.isFinite)
            .map((e) => LatLng(e.lat!, e.lon!))
            .toList();
        fitMap();
      });
    } else {
      throw Exception('Failed to load GPX map');
    }
  }

  Future<void> fetchRaceScores(int raceId) async {
    ///    Fetches scores of a race for a given race
    final response = await http.get(
      Uri.parse('${settings.apiBaseUrl}/api/rider/race/$raceId/participation/all'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> scores = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        scoreRows = scores.map((score) => RaceScores.fromJson(score)).toList();
      });
    } else {
      throw Exception('Failed to load race scores');
    }
  }

  Future<void> fetchCurrentUser() async {
    ///    Fetches current user of the app
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

  Color getBorderColorForPlace(int index) {
    ///    Returns card border color for a given place in the race
    if (index == 0) {
      return Colors.amber;
    } else if (index == 1) {
      return Colors.blueGrey.shade300;
    } else if (index == 2) {
      return Colors.deepOrange;
    } else {
      return Colors.white;
    }
  }

  Color getCardColorForPlace(int index) {
    ///    Returns card background color for a given place in the race
    if (scoreRows[index].riderName == currentUser.name && scoreRows[index].riderSurname == currentUser.surname) {
      return Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.5);
    } else {
      return Theme.of(context).colorScheme.surface;
    }
  }

  String formatSeconds(double seconds) {
    ///    Formats duration in seconds to Hh Mmin Ss format
    int hours = (seconds / 3600).floor();
    int minutes = ((seconds - hours * 3600) / 60).floor();
    int newSeconds = (seconds - hours * 3600 - minutes * 60).floor();
    return "${hours}h ${minutes}min ${newSeconds}s";
  }

  @override
  Widget build(BuildContext context) {
    ///    Builds the race participation widget
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
          title: const Text('Wyścig'),
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
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 3 * AppBar().preferredSize.height),
                child: Center(
                  child: todayRace != null ? buildTodayRaceWidget(todayRace!) : NoRaceContent(),
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
      ),
    );
  }

  Future<void> _handleRefresh() async {
    ///    Handles refreshes of a page
    await reloadRaces();
    await fetchCurrentUser();
    setState(() {});
  }

  Widget buildTodayRaceWidget(Race race) {
    ///    Returns widget of a today's race of a given user
    if (race.status == 'pending') {
      return PendingRaceContent(race);
    } else if (race.status == 'in_progress') {
      return InProgressRaceContent(race);
    } else if (race.status == 'ended' && race.isApproved == false) {
      return FinishedRaceContent(race);
    } else if (race.status == 'ended') {
      return EndedRaceContent(race);
    } else {
      return NoRaceContent();
    }
  }

  int findNextRaceIndex() {
    ///    Finds Id of the next closest race that a user has joined
    DateTime today = DateTime.now();
    int closestIndex = -1;
    DateTime closestDate = today;

    for (int i = 0; i < itemList.length; i++) {
      DateTime startDate = DateFormat("yyyy-MM-ddTHH:mm:ss").parse(itemList[i].timeStart, true).toLocal();
      if (itemList[i].userParticipating && startDate.isAfter(today) && (closestDate == today || startDate.isBefore(closestDate))) {
        closestIndex = i;
        closestDate = startDate;
      }
    }

    return closestIndex;
  }

  Widget NoRaceContent() {
    ///    Page content when there are no upcoming races in current day
    int nextRaceIndex = findNextRaceIndex();

    return Container(
      alignment: Alignment.bottomCenter,
      height: MediaQuery.of(context).size.height - 3 * AppBar().preferredSize.height,
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
                SizedBox(height: MediaQuery.of(context).size.height / 8),
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
                        builder: (context) => RaceDetails(
                          itemList[nextRaceIndex].id,
                          accessToken: widget.accessToken,
                        ),
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
                                    '${settings.apiBaseUrl}${itemList[nextRaceIndex].eventGraphic}',
                                    fit: BoxFit.fitHeight,
                                  )
                                : Image.asset(
                                    'sample_image.png',
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
                SizedBox(height: MediaQuery.of(context).size.height / 5),
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

  Widget PendingRaceContent(Race race) {
    ///    Page content when there is a pending race in the current day
    DateTime startTime = DateFormat("yyyy-MM-ddTHH:mm:ss").parse(race.timeStart, true).toLocal();

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
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
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
                    builder: (context) => RaceDetails(
                      race.id,
                      accessToken: widget.accessToken,
                    ),
                  ),
                );
              },
              child: const Text('Szczegóły wyścigu'),
            ),
          ],
        ),
        SizedBox(
          height: 16,
        ),
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            late Icon icon;
            late String msg;
            switch (race.participationStatus) {
              case "approved":
                icon = Icon(
                  Icons.done,
                  color: Colors.green,
                  size: 32,
                );
                msg = "Zatwierdzone";
                break;
              case "rejected":
                icon = Icon(
                  Icons.close,
                  color: Colors.red,
                  size: 32,
                );
                msg = "Odrzucone";
                break;
              default:
                icon = Icon(
                  Icons.question_mark,
                  color: Colors.amber,
                  size: 32,
                );
                msg = "Oczekuje na zatwierdzenie";
                break;
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: icon,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Status uczestnictwa",
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      msg,
                      style: Theme.of(context).textTheme.titleLarge,
                    )
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget InProgressRaceContent(Race race) {
    ///    Page content when a race in which the rider is participating is currently in progress
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
                      interactionOptions: InteractionOptions(flags: gpxMapLink.contains("/") ? InteractiveFlag.all : InteractiveFlag.none)),
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
              onPressed: race.participationStatus == 'approved'
                  ? () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RaceTrackingPage(
                              race.id,
                              accessToken: widget.accessToken,
                            ),
                          ));
                      setState(() async {
                        await _handleRefresh();
                        await fetchRaceDetails(race.id);
                      });
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(double.infinity, 50.0),
              ),
              child: Text('Przejdź do wyścigu', style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        SizedBox(
          height: 16,
        ),
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            late Icon icon;
            late String msg;
            switch (race.participationStatus) {
              case "approved":
                icon = Icon(
                  Icons.done,
                  color: Colors.green,
                  size: 32,
                );
                msg = "Zatwierdzone";
                break;
              case "rejected":
                icon = Icon(
                  Icons.close,
                  color: Colors.red,
                  size: 32,
                );
                msg = "Odrzucone";
                break;
              default:
                icon = Icon(
                  Icons.question_mark,
                  color: Colors.amber,
                  size: 32,
                );
                msg = "Oczekuje na zatwierdzenie";
                break;
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: icon,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Status uczestnictwa",
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      msg,
                      style: Theme.of(context).textTheme.titleLarge,
                    )
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget FinishedRaceContent(Race race) {
    ///    Page content when the current race is awaiting result confirmation from coordinator
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
                      interactionOptions: InteractionOptions(flags: gpxMapLink.contains("/") ? InteractiveFlag.all : InteractiveFlag.none)),
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
            SizedBox(
                height: 128,
                child: Text(
                  "Trasa przejazdu została przesłana! Wyniki będą dostępne po zatwierdzeniu ich przez koordynatora.",
                  style: Theme.of(context).textTheme.bodyLarge,
                ))
          ],
        ),
      ],
    );
  }

  Widget EndedRaceContent(Race race) {
    ///    Page content when a race in the given day has ended (show race ranking)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                "${race.name} - wyniki",
                style: Theme.of(context).textTheme.headlineMedium,
                maxLines: 5,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(
                height: 32,),
        ListView.builder(
        shrinkWrap: true,
        itemCount: scoreRows.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 16.0, right: 16.0),
                    child: Text(
                      "${scoreRows[index ].place}",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: Card(
                        color: getCardColorForPlace(index),
                        margin: const EdgeInsets.only(right: 16.0, bottom: 16.0),
                        shape: RoundedRectangleBorder(
                            side: BorderSide(color: getBorderColorForPlace(index), width: 3.0), borderRadius: BorderRadius.circular(10.0)),
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
                                      scoreRows[index].riderUsername,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    Text(
                                      "${scoreRows[index].riderName} ${scoreRows[index].riderSurname}",
                                      style: Theme.of(context).textTheme.labelMedium,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  formatSeconds(scoreRows[index].time),
                                  style: Theme.of(context).textTheme.labelLarge,
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
      )],
    );
  }
}

class CountdownTimer extends StatelessWidget {
  ///  Class used for building a countdown timer to a nearest race
  final DateTime startTime;

  const CountdownTimer({super.key, required this.startTime});

  @override
  Widget build(BuildContext context) {
    ///    Builds countdown timer to a nearest race
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
    ///    Provides data for a countdown timer
    while (true) {
      DateTime currentTime = DateTime.now();
      int remainingSeconds = startTime.difference(currentTime).inSeconds;

      yield remainingSeconds;

      await Future.delayed(const Duration(seconds: 1));
    }
  }
}

class CountdownCard extends StatelessWidget {
  ///  Countdown card widget
  final String label;
  final String value;
  final double left;
  final double right;

  const CountdownCard({super.key, required this.label, required this.value, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    ///    Build the countdown card widget
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
