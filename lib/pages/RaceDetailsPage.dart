import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gpx/gpx.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';

import 'package:sigmactas_alleycat/util/notification.dart';
import 'package:sigmactas_alleycat/util/settings.dart' as settings;
import 'package:sigmactas_alleycat/util/dark_mode.dart';
import 'package:sigmactas_alleycat/util/dates.dart';


class RaceDetails extends StatefulWidget {
  ///  Race details page widget
  final int id;
  final String accessToken;

  const RaceDetails(this.id, {Key? key, required this.accessToken}) : super(key: key);

  @override
  _RaceDetailsState createState() => _RaceDetailsState();
}

class _RaceDetailsState extends State<RaceDetails> {
  ///  This class defines states of a page for resetting password
  String selectedValue = '';
  String raceName = '';
  String status = '';
  String requirements = 'null';
  String raceDescription = '';
  String meetupTimestamp = 'null';
  String startTimestamp = '2000-01-01T00:00:00';
  String endTimestamp = '2000-01-01T00:00:00';
  String gpxMapLink = '';
  bool isApproved = false;
  Gpx gpxMap = Gpx();
  List<LatLng> points = [];
  late List<Wpt> pointsWpt;
  int numberOfLaps = 0;
  int entryFeeGr = 0;
  List<Map<String, dynamic>> bikes = [];
  String selectedBike = '';
  bool isParticipating = false;
  final mapController = MapController();
  List<String> sponsorBannersUrl = [];

  @override
  void initState() {
    super.initState();
    fetchRaceDetails();
    fetchBikeNames();
  }

  @override
  void dispose() {
    super.dispose();
    mapController.dispose();
  }

  Future<void> fetchRaceDetails() async {
    ///    Fetches race details from the server to be displayed to the user
    final response = await http.get(
      Uri.parse('${settings.apiBaseUrl}/api/rider/race/${widget.id}'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> raceDetails = json.decode(utf8.decode(response.bodyBytes));
      final String? participationStatus = raceDetails['participation_status'];
      final bool userParticipating = participationStatus != null;

      setState(() {
        raceName = raceDetails['name'];
        if (raceDetails['requirements'] != null) {
          requirements = raceDetails['requirements'];
        }
        status = raceDetails['status'];
        numberOfLaps = raceDetails['no_laps'];
        entryFeeGr = raceDetails['entry_fee_gr'];
        raceDescription = raceDetails['description'];
        gpxMapLink = raceDetails['checkpoints_gpx_file'];
        if (gpxMapLink.contains("/")) {
          fetchGpxMap();
        }
        if (raceDetails['meetup_timestamp'] != null) {
          meetupTimestamp = raceDetails['meetup_timestamp'];
        }
        startTimestamp = raceDetails['start_timestamp'];
        endTimestamp = raceDetails['end_timestamp'];
        isApproved = raceDetails['is_approved'];
        isParticipating = userParticipating;
        final sponsorBannersJson = raceDetails['sponsor_banners_uuids_json'];
        if (sponsorBannersJson != null) {
          final List<dynamic> sponsorBannersList = json.decode(sponsorBannersJson);
          sponsorBannersUrl = sponsorBannersList.where((url) => url.toString().contains("/")).map((url) => url.toString()).toList();
        }
      });
    } else {
      throw Exception('Failed to load race details');
    }
  }

  Future<void> fetchGpxMap() async {
    ///    Fetches gpx map of the race from the server to be displayed to the user
    final response = await http.get(
      Uri.parse('${settings.apiBaseUrl}$gpxMapLink'),
    );

    if (response.statusCode == 200) {
      setState(() {
        gpxMap = GpxReader().fromString(utf8.decode(response.bodyBytes));
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

  Future<List<Map<String, dynamic>>> fetchBikeNames() async {
    ///    Fetches bikes assigned to a user from the server
    final response = await http.get(
      Uri.parse('${settings.apiBaseUrl}/api/rider/bike/'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> bikeList = json.decode(utf8.decode(response.bodyBytes));
      final List<Map<String, dynamic>> bikesData =
          bikeList.where((bike) => bike['is_retired'] == false).map((bike) => {'id': bike['id'], 'name': bike['name'].toString()}).toList();
      setState(() {
        bikes = bikesData;
        if (bikes.isNotEmpty) {
          selectedValue = bikes[0]['name'];
        }
      });
      return bikesData;
    } else {
      throw Exception('Failed to load bike names');
    }
  }

  Future<void> joinRace(int bikeId) async {
    ///    Attempts to register user to a race, shows appropriate notification regarding success of the operation
    final response = await http.post(
      Uri.parse('${settings.apiBaseUrl}/api/rider/race/${widget.id}/join?bike_id=$bikeId'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      setState(() {
        isParticipating = true;
      });
      showSnackbarMessage(context, 'Udało się zapisać na wyścig!');
    } else {
      showSnackbarMessage(context, 'Błąd podczas zapisywania na wyścig ${response.statusCode}');
    }
  }

  Future<void> withdrawFromRace() async {
    ///    Withdraws user from a race, shows appropriate notification regarding success of the operation
    final response = await http.post(
      Uri.parse('${settings.apiBaseUrl}/api/rider/race/${widget.id}/withdraw'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      setState(() {
        isParticipating = false;
      });
      showSnackbarMessage(context, 'Wycofano udział z wyścigu');
    } else {
      showSnackbarMessage(context, 'Błąd podczas wycofywania udziału z wyścigu');
    }
  }

  TileLayer get openStreetMapTileLayer => TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'dev.fleaflet.flutter_map.example',
        // Use the recommended flutter_map_cancellable_tile_provider package to
        // support the cancellation of loading tiles.
        tileProvider: CancellableNetworkTileProvider(),
        tileBuilder: context.isDarkMode ? darkModeTileBuilder : null,
      );

  @override
  Widget build(BuildContext context) {
    ///    Builds the race details screen
    return Scaffold(
      appBar: AppBar(
        title: Text(raceName),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ///
              /// Map
              ///
              SizedBox(
                height: 300.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                        initialCenter: const LatLng(52.23202828872916, 21.006132649819673), //Warsaw,
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
              const SizedBox(height: 5.0),
              ///
              /// Race status
              ///
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  late String msg;
                  late Color color;

                  switch (status) {
                    case "in_progress":
                      msg = "W trakcie";
                      color = Colors.greenAccent.withOpacity(0.5);
                      break;
                    case "cancelled":
                      msg = "Odwołany";
                      color = Colors.redAccent.withOpacity(0.5);
                      break;
                    case "ended":
                      if (isApproved) {
                        msg = "Zakończony";
                        color = Colors.grey.withOpacity(0.5);
                      } else {
                        msg = "Oczekuje na zatwierdzenie wyników";
                        color = Colors.amber.withOpacity(0.5);
                      }
                      break;
                  }

                  if (['in_progress', 'ended', 'cancelled'].contains(status)) {
                    return Card(
                      color: color,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              msg,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return SizedBox();
                  }
                },
              ),
              const SizedBox(height: 5.0),
              ///
              /// Title and dates
              ///
              Card(
                child: ListTile(
                  title: Text(
                    raceName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: meetupTimestamp != 'null'
                      ? Text(
                          'Zbiórka: ${formatDateString(meetupTimestamp)}\nCzas trwania: ${formatDateString(startTimestamp)}-${formatDateStringToHours(endTimestamp)}')
                      : Text('Czas trwania: ${formatDateString(startTimestamp)}-${formatDateStringToHours(endTimestamp)}'),
                ),
              ),
              const SizedBox(height: 5.0),
              ///
              /// Entry fee and number of laps
              ///
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wpisowe: ${(entryFeeGr / 100).toStringAsFixed(2)}zł',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Liczba okrążeń: ${numberOfLaps.toString()}',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ///
              /// Race requirements
              ///
              if (requirements != 'null')
                Column(
                  children: [
                    const SizedBox(height: 5.0),
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wymagania:',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 5.0),
                              Text(requirements),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 5.0),
              ///
              /// Desctiption
              ///
              SizedBox(
                width: double.infinity,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Opis:',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 5.0),
                        Text(raceDescription),
                      ],
                    ),
                  ),
                ),
              ),
              ///
              /// Sponsor banners
              ///
              if (sponsorBannersUrl.isNotEmpty)
                Column(
                  children: [
                    const SizedBox(height: 5.0),
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Sponsorzy:',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5.0),
                    buildSponsorBanners(),
                  ],
                ),
              if (status != 'ended' && status != 'cancelled') const SizedBox(height: 60.0),
            ],
          ),
        ),
      ),
      floatingActionButton: status != "pending"
          ? null
          : isParticipating
              ? FloatingActionButton.extended(
                  onPressed: () {
                    withdrawFromRace();
                  },
                  label: const Text('Wycofaj udział'),
                  icon: const Icon(Icons.cancel),
                )
              : FloatingActionButton.extended(
                  onPressed: () {
                    showAddTextDialog(context);
                  },
                  label: const Text('Weź udział w wyścigu!'),
                  icon: const Icon(Icons.add),
                ),
    );
  }

  Widget buildSponsorBanners() {
    ///    Builds a widget for sponsor banners
    return Column(
      children: sponsorBannersUrl.map((bannerUrl) {
        return SizedBox(
          width: double.infinity,
          child: Card(
            child: ClipRRect(
              borderRadius: const BorderRadius.all(
                Radius.circular(16.0),
              ),
              child: Image.network(
                '${settings.apiBaseUrl}$bannerUrl',
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void showAddTextDialog(BuildContext context) async {
    ///    Creates dropdown menu dialog for selecting a bike for a race
    fetchBikeNames();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Wybierz swój rower:'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedValue,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedValue = value!;
                      });
                    },
                    items: bikes.map<DropdownMenuItem<String>>((bike) {
                      return DropdownMenuItem<String>(
                        value: bike['name'],
                        child: Text(bike['name']),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Anuluj'),
                      ),
                      FilledButton(
                        onPressed: () {
                          final selectedBikeId = getSelectedBikeId(selectedValue);
                          joinRace(selectedBikeId);
                          Navigator.pop(context);
                        },
                        child: const Text('Zapisz'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  int getSelectedBikeId(String bikeName) {
    ///    Returns id of a selected bike
    final selectedBike = bikes.firstWhere((bike) => bike['name'] == bikeName, orElse: () => {'id': -1});
    return selectedBike['id'];
  }

  void fitMap() {
    ///    Fits entire race track on the map
    mapController.fitCamera(
      CameraFit.bounds(
          bounds:
              LatLngBounds.fromPoints(pointsWpt.where((e) => e.lat != null && e.lon != null).map((e) => LatLng(e.lat!, e.lon!)).toList()),
          padding: const EdgeInsets.all(32)),
    );
  }
}
