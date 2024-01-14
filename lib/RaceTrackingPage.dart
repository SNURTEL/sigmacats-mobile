import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'settings.dart' as settings;

var uuid = Uuid();

class RaceTrackingPage extends StatefulWidget {
  final String accessToken;
  final int raceId;

  const RaceTrackingPage(this.raceId, {Key? key, required this.accessToken}) : super(key: key);

  @override
  _RaceTrackingPageState createState() => _RaceTrackingPageState();
}

class _RaceTrackingPageState extends State<RaceTrackingPage> {
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

  final Future<String> _calculation = Future<String>.delayed(
    const Duration(seconds: 10),
    () => 'Data Loaded',
  );

  TileLayer get openStreetMapTileLayer => TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'dev.fleaflet.flutter_map.example',
        // Use the recommended flutter_map_cancellable_tile_provider package to
        // support the cancellation of loading tiles.
        tileProvider: CancellableNetworkTileProvider(),
        tileBuilder: context.isDarkMode1 ? darkModeTileBuilder : null,
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
      markers: location != null
          ? [
              Marker(
                  point: LatLng(location!.coords.latitude, location!.coords.longitude),
                  rotate: true,
                  child: Icon(
                    Icons.pedal_bike,
                    color: context.isDarkMode1 ? Colors.white : Colors.black54,
                  ))
            ]
          : []);

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
    mapController.dispose();
  }

  void setupTracking() {
    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      print('[location] - $location');
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
          locationTimestamps.add(DateTime.parse(location.timestamp));
        }
      });
    });

    bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
      print('[motionchange] - $location');
    });

    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
      print('[providerchange] - $event');
    });

    bg.BackgroundGeolocation.ready(bg.Config(
        locationTimeout: 0,
        isMoving: true,
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        enableTimestampMeta: true,
        disableElasticity: true,
        // set to false in production
        distanceFilter: 0.1,
        // set to 0m in production
        elasticityMultiplier: 1,
        // set to 0.5 in production
        stopOnTerminate: false,
        persistMode: bg.Config.PERSIST_MODE_LOCATION,
        startOnBoot: false,
        stopOnStationary: false,
        // iOS specific
        stationaryRadius: 2,
        debug: true,
        reset: true));

    bg.BackgroundGeolocation.start().then((bg.State state) {
      print('[start] success $state');
    });
    bg.BackgroundGeolocation.changePace(true);
    trackingStartedTimestamp = DateTime.now();
  }

  Future<void> fetchMapGpx() async {
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
    return PopScope(
        canPop: !isTracking && !isUploading,
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Śledzenie wyścigu'),
              automaticallyImplyLeading: false,
              centerTitle: true,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: wasUploadSuccess ? null : () {
            setState(() {
              isTracking = true;
              isFollowing = true;
              isFitTrack = false;
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(
          onPressed: wasUploadSuccess ? null : () {
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

  void showNotification(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget EndRecordingDialog(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) setState) {
        return PopScope(
          // canPop: !isUploading && !wasUploadSuccess,
          canPop: !isUploading && !wasUploadSuccess,
          child: AlertDialog(
            title: const Text('Zakończyć rejestrowanie?'),
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
                          child: Text(wasUploadSuccess ? "Sukces!" : "Przesyłanie..." ),
                        )
                    )
                )
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
                  child: isUploading ? CircularProgressIndicator() : FilledButton(
                    style: TextButton.styleFrom(
                      textStyle: Theme.of(context).textTheme.labelLarge,
                    ),
                    child: const Text('Zakończ'),
                    onPressed: wasUploadSuccess ? null : () async {
                      setState(() {
                        isUploading = true;
                      });
                      final responseStatusCode = await uploadResultGpx();

                      if (responseStatusCode != 202) {
                        showNotification(context, "Błąd przesyłania: $responseStatusCode");
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
                      showNotification(context, "Przesłano!");
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
    final fileUuid = uuid.v4();
    final filename = 'race_${widget.raceId}_ride_${fileUuid}';

    final gpx = dumpGpx(
        locationHistory,
        locationTimestamps,
        fileUuid,
        "This is a test GPX file"
    );

    final writer = GpxWriter().asString(gpx, pretty: true);

    final url = Uri.parse('${settings.uploadBaseUrl}${widget.raceId}/upload-result');
    print("Upload to ${url}");
    var request = new http.MultipartRequest("POST", url);
    request.fields['name'] = filename;
    request.files.add(http.MultipartFile.fromString('fileobj', writer.toString(), filename: filename));
    request.headers['Authorization'] = "Bearer ${widget.accessToken}";
    return await request.send().then((streamedResponse) async {
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        print("Uploaded!");
      } else {
        print("Error ${response.statusCode}: ${json.decode(utf8.decode(response.bodyBytes))}");
      };
      return response.statusCode;
    });
  }

  Gpx dumpGpx(List<LatLng> trackpoints, List<DateTime> timestamps, [String name = "", String desc = "", DateTime? time]) {
    time = time ?? DateTime.now();
    final gpx = Gpx();
    gpx.version = '1.1';
    gpx.creator = 'sigmacats rider app';
    gpx.metadata = Metadata();
    gpx.metadata?.name = name;
    gpx.metadata?.desc = desc;
    gpx.metadata?.time = time;
    gpx.trks = [Trk(
        name: name,
        type: "cycling",
        trksegs: [
          Trkseg(
              trkpts: List.generate(trackpoints.length, (i) => i).map(
                      (i) => Wpt(
                      lat: trackpoints[i].latitude,
                      lon: trackpoints[i].longitude,
                      time: timestamps[i]
                  )).toList()
          )
        ]
    )];
    return gpx;
  }
}

extension DarkMode on BuildContext {
  bool get isDarkMode1 {
    final brightness = MediaQuery.of(this).platformBrightness;
    return brightness == Brightness.dark;
  }
}
