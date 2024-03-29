import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gpx/gpx.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:sigmactas_alleycat/util/dark_mode.dart';
import 'package:sigmactas_alleycat/util/notification.dart';
import 'package:uuid/uuid.dart';
import '../util/settings.dart' as settings;

class RaceTrackingPage extends StatefulWidget {
  ///  Race tracking page widget
  final String accessToken;
  final int raceId;

  const RaceTrackingPage(this.raceId, {Key? key, required this.accessToken}) : super(key: key);

  @override
  _RaceTrackingPageState createState() => _RaceTrackingPageState();
}

class _RaceTrackingPageState extends State<RaceTrackingPage> {
  ///  Race tracking page state

  var uuid = const Uuid();

  int numSamples = 0;
  bool isTracking = false;
  bool isFollowing = false;
  bool isFitTrack = true;
  bool isUploading = false;
  bool wasUploadSuccess = false;
  DateTime trackingStartedTimestamp = DateTime.now();

  List<LatLng> trackPoints = [];

  bg.Location? location;
  List<LatLng> locationHistory = [];
  List<DateTime> locationTimestamps = [];

  final mapController = MapController();

  TileLayer get openStreetMapTileLayer => TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'dev.fleaflet.flutter_map.example',
        tileProvider: CancellableNetworkTileProvider(),
        tileBuilder: context.isDarkMode ? darkModeTileBuilder : null,
      );

  PolylineLayer get trackPolylineLayer => PolylineLayer(
        polylines: [
          Polyline(
            points: trackPoints,
            strokeWidth: 5,
            color: Theme.of(context).colorScheme.tertiary.withOpacity(0.8),
          ),
        ],
      );

  PolylineLayer get recordingPolylineLayer => PolylineLayer(
        polylines: [
          Polyline(
            points: locationHistory,
            strokeWidth: 3,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      );

  MarkerLayer get markerLayer => MarkerLayer(
      markers: (location != null
          ? [
              Marker(
                  point: LatLng(location!.coords.latitude, location!.coords.longitude),
                  rotate: true,
                  child: Icon(
                    Icons.pedal_bike,
                    color: context.isDarkMode ? Colors.white : Colors.black54,
                  ))
            ]
          : [])
        ..addAll(trackPoints.isNotEmpty
            ? [
                Marker(
                    point: LatLng(trackPoints.last.latitude, trackPoints.last.longitude),
                    rotate: true,
                    width: 24,
                    height: 24,
                    child: Container(
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, shape: BoxShape.circle),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Image.asset(
                            "finish_line_icon.png",
                            color: context.isDarkMode ? Colors.white : Colors.black87,
                          ),
                        )))
              ]
            : []));

  void initState() {
    super.initState();

    mapController.mapEventStream.listen((event) {
      if (event is MapEventMoveStart) {
        setState(() {
          isFollowing = false;
          isFitTrack = false;
        });
      }
    });

    setupTracking();
    fetchMapGpx();
  }

  @override
  void dispose() {
    super.dispose();
    bg.BackgroundGeolocation.stop();
    bg.BackgroundGeolocation.removeListeners();
    mapController.dispose();
  }

  void setupTracking() {
    ///    Sets up the tracking library
    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      log('[location] - $location');
      setState(() {
        this.location = location;

        final waypoint = LatLng(location.coords.latitude, location.coords.longitude);

        if (isFollowing) {
          mapController.move(
            waypoint,
            18,
          );
        }
        if (isTracking) {
          numSamples += 1;
          locationHistory.add(waypoint);
          locationTimestamps.add(DateFormat("yyyy-MM-ddTHH:mm:ss").parse(location.timestamp, true).toLocal());
        }
      });
    });

    bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
      log('[motionchange] - $location');
    });

    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
      log('[providerchange] - $event');
    });

    bg.BackgroundGeolocation.ready(bg.Config(
        locationTimeout: 0,
        isMoving: true,
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        enableTimestampMeta: true,
        disableElasticity: true,
        // true in debug
        // distanceFilter: 0.1,  // enable in debug
        elasticityMultiplier: 0.5,
        // 1 in debug
        stopOnTerminate: false,
        persistMode: bg.Config.PERSIST_MODE_LOCATION,
        startOnBoot: false,
        stopOnStationary: false,
        // iOS specific
        stationaryRadius: 2,
        debug: true,
        reset: true));

    bg.BackgroundGeolocation.start().then((bg.State state) {
      log('[start] success $state');
    });
    bg.BackgroundGeolocation.changePace(true);
    trackingStartedTimestamp = DateTime.now();
  }

  Future<void> fetchMapGpx() async {
    ///    Fetches gpx file with map of a race
    final detailsResponse = await http.get(
      Uri.parse('${settings.apiBaseUrl}/api/rider/race/${widget.raceId}'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (detailsResponse.statusCode != 200) {
      throw Exception('Failed to load race details');
    }

    final Map<String, dynamic> raceDetails = json.decode(utf8.decode(detailsResponse.bodyBytes));

    final trackGpxPath = raceDetails['checkpoints_gpx_file'];

    final gpxResponse = await http.get(
      Uri.parse('${settings.apiBaseUrl}$trackGpxPath'),
    );

    if (gpxResponse.statusCode != 200) {
      throw Exception('Failed to load GPX map');
    }

    setState(() {
      final gpxMap = GpxReader().fromString(utf8.decode(gpxResponse.bodyBytes));
      trackPoints = gpxMap.trks.first.trksegs.first.trkpts
          .where((element) => element.lat != null && element.lon != null && element.lat!.isFinite && element.lon!.isFinite)
          .map((e) => LatLng(e.lat!, e.lon!))
          .toList();
    });

    mapController.fitCamera(CameraFit.coordinates(coordinates: trackPoints, padding: EdgeInsets.all(24)));
  }

  @override
  Widget build(BuildContext context) {
    ///    Build the race tracking widget
    return PopScope(
        canPop: !isTracking && !isUploading,
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Śledzenie wyścigu'),
              automaticallyImplyLeading: false,
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.cancel_outlined),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Zrezygnować?"),
                            icon: Icon(Icons.mood_bad_outlined),
                            content: Text("Jeśli wycofasz się z wyścigu, powrót nie będzie możliwy!"),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text("Anuluj")),
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                      foregroundColor: Theme.of(context).colorScheme.onError),
                                  onPressed: () async {
                                    final responseCode = await withdrawFromRace();
                                    if (responseCode == 200) {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  child: Text("Zrezygnuj"))
                            ],
                          );
                        });
                  },
                )
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: LatLng(52.23202828872916, 21.006132649819673), // Warsaw
                          initialZoom: 15,
                        ),
                        children: [openStreetMapTileLayer, trackPolylineLayer, recordingPolylineLayer, markerLayer],
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        // add your floating action button
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FloatingActionButton.small(
                                backgroundColor:
                                    isFollowing ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
                                shape: CircleBorder(),
                                onPressed: () {
                                  setState(() {
                                    isFollowing = !isFollowing;
                                    isFitTrack = false;
                                    if (isFollowing && location != null) {
                                      mapController.move(LatLng(location!.coords.latitude, location!.coords.longitude), 18);
                                    }
                                  });
                                },
                                child: Icon(Icons.gps_fixed),
                              ),
                              FloatingActionButton.small(
                                backgroundColor:
                                    isFitTrack ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
                                shape: CircleBorder(),
                                onPressed: () {
                                  setState(() {
                                    isFitTrack = !isFitTrack;
                                    isFollowing = false;
                                    if (isFitTrack && trackPoints.isNotEmpty) {
                                      mapController.rotate(-mapController.camera.rotationRad);
                                      mapController.fitCamera(CameraFit.coordinates(coordinates: trackPoints, padding: EdgeInsets.all(24)));
                                    }
                                  });
                                },
                                child: Icon(Icons.pin_drop_outlined),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                        height: 96,
                        child: Center(
                            child: AnimatedCrossFade(
                          firstChild: TrackingBarContent(),
                          secondChild: NotTrackingBarContent(),
                          duration: const Duration(milliseconds: 100),
                          crossFadeState: isTracking ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
                            return topChild;
                          },
                        ))))
              ],
            )));
  }

  Widget NotTrackingBarContent() {
    ///    Bottom bar with recording button when not location is not being recorded
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: wasUploadSuccess
              ? null
              : () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          icon: Icon(Icons.gps_fixed),
                          title: Text("Wszystko gotowe?"),
                          content: Text("Aplikacja rozpocznie zapisywanie trasy przejazdu. Tej czynności nie da się anulować."),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text("Anuluj")),
                            FilledButton(
                                onPressed: () {
                                  setState(() {
                                    isTracking = true;
                                    isFollowing = true;
                                    isFitTrack = false;

                                    bg.BackgroundGeolocation.getCurrentPosition(
                                            maximumAge: 0, persist: false, desiredAccuracy: 0, timeout: 30000, samples: 1)
                                        .then((bg.Location location) {
                                      log('[getCurrentPosition] - $location');
                                      this.location = location;
                                    }).catchError((error) {
                                      log('[getCurrentPosition] ERROR: $error');
                                    });
                                  });
                                  Navigator.of(context).pop();
                                },
                                child: Text("Zaczynajmy!"))
                          ],
                        );
                      });
                },
          child: Text('START',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onTertiary, fontSize: 16, height: 1.2)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            foregroundColor: Theme.of(context).colorScheme.onTertiary,
            shape: CircleBorder(),
            padding: EdgeInsets.all(40),
          ),
        ),
      ],
    );
  }

  Widget TrackingBarContent() {
    ///    Bottom bar with recording button when not location IS being recorded
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(
          onPressed: wasUploadSuccess
              ? null
              : () {
                  setState(() {
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return EndRecordingDialog(context);
                      },
                    );
                  });
                },
          child:
              Text('STOP', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, fontSize: 16, height: 1.2)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.tertiary,
            side: BorderSide(color: Theme.of(context).colorScheme.tertiary, width: 5),
            shape: CircleBorder(),
            padding: EdgeInsets.all(40),
          ),
        ),
      ],
    );
  }

  Widget EndRecordingDialog(BuildContext context) {
    ///    Dialog shown before stopping tracking and submitting results
    return StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) setState) {
        return PopScope(
          // canPop: !isUploading && !wasUploadSuccess,
          canPop: !isUploading && !wasUploadSuccess,
          child: AlertDialog(
            title: const Text('Zakończyć rejestrowanie?'),
            icon: Icon(Icons.done),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Trasa przejazdu zostanie zapisana i wysłana na serwer. Tej operacji nie można cofnąć.',
                ),
                Visibility(
                    maintainAnimation: true,
                    maintainState: true,
                    visible: isUploading || wasUploadSuccess,
                    child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.fastOutSlowIn,
                        opacity: isUploading || wasUploadSuccess ? 1 : 0,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(wasUploadSuccess ? "Sukces!" : "Przesyłanie..."),
                        )))
              ],
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('Anuluj'),
                onPressed: isUploading || wasUploadSuccess
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
              ),
              SizedBox(
                height: 44,
                width: 104,
                child: Center(
                  child: isUploading
                      ? CircularProgressIndicator()
                      : FilledButton(
                          style: TextButton.styleFrom(
                            textStyle: Theme.of(context).textTheme.labelLarge,
                          ),
                          child: const Text('Zakończ'),
                          onPressed: wasUploadSuccess
                              ? null
                              : () async {
                                  setState(() {
                                    isUploading = true;
                                  });
                                  final responseStatusCode = await uploadResultGpx();

                                  if (responseStatusCode != 202) {
                                    showSnackbarMessage(context, "Błąd przesyłania: $responseStatusCode");
                                    setState(() {
                                      isUploading = false;
                                      wasUploadSuccess = false;
                                    });
                                    return;
                                  }

                                  setState(() {
                                    isUploading = false;
                                    wasUploadSuccess = true;
                                  });
                                  showSnackbarMessage(context, "Przesłano!");
                                  await Future.delayed(Duration(seconds: 3));
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<int> uploadResultGpx() async {
    ///    Uploads a gpx file (a result of tracking) to a server
    final fileUuid = uuid.v4();
    final filename = 'race_${widget.raceId}_ride_${fileUuid}';

    final gpx = dumpGpx(locationHistory, locationTimestamps, fileUuid, "This is a test GPX file");

    final writer = GpxWriter().asString(gpx, pretty: true);

    final url = Uri.parse('${settings.uploadBaseUrl}${widget.raceId}/upload-result');
    log("Upload to ${url}");
    var request = new http.MultipartRequest("POST", url);
    request.fields['name'] = filename;
    request.files.add(http.MultipartFile.fromString('fileobj', writer.toString(), filename: filename));
    request.headers['Authorization'] = "Bearer ${widget.accessToken}";
    return await request.send().then((streamedResponse) async {
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 202) {
        log("Uploaded!");
      } else {
        log("Error ${response.statusCode}: ${json.decode(utf8.decode(response.bodyBytes))}");
      }
      ;
      return response.statusCode;
    });
  }

  Gpx dumpGpx(List<LatLng> trackpoints, List<DateTime> timestamps, [String name = "", String desc = "", DateTime? time]) {
    ///    Dumps recorded trackpoints with timestamps to a GPX file
    time = time ?? DateTime.now();
    final gpx = Gpx();
    gpx.version = '1.1';
    gpx.creator = 'sigmacats rider app';
    gpx.metadata = Metadata();
    gpx.metadata?.name = name;
    gpx.metadata?.desc = desc;
    gpx.metadata?.time = time;
    gpx.trks = [
      Trk(name: name, type: "cycling", trksegs: [
        Trkseg(
            trkpts: List.generate(trackpoints.length, (i) => i)
                .map((i) => Wpt(lat: trackpoints[i].latitude, lon: trackpoints[i].longitude, time: timestamps[i].toUtc()))
                .toList())
      ])
    ];
    return gpx;
  }

  Future<int> withdrawFromRace() async {
    ///    Make a withdraw request to server and show result notification
    final response = await http.post(
      Uri.parse('${settings.apiBaseUrl}/api/rider/race/${widget.raceId}/withdraw'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      showSnackbarMessage(context, 'Wycofano udział z wyścigu');
    } else {
      showSnackbarMessage(context, 'Błąd podczas wycofywania udziału z wyścigu');
    }
    return response.statusCode;
  }
}
