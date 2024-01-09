import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'BottomNavigationBar.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map/flutter_map.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({Key? key}) : super(key: key);

  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  late String _localPath;
  late bool _permissionReady;
  late TargetPlatform? platform;

  int numSamples = 0;
  bool isTracking = false;
  DateTime trackingStartedTimestamp = DateTime.now();

  bg.Location? location;
  List<LatLng> locationHistory = [];
  List<DateTime> locationTimestamps = [];

  final mapController = MapController();

  TileLayer get openStreetMapTileLayer => TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'dev.fleaflet.flutter_map.example',
        // Use the recommended flutter_map_cancellable_tile_provider package to
        // support the cancellation of loading tiles.
        tileProvider: CancellableNetworkTileProvider(),
        tileBuilder: context.isDarkMode ? darkModeTileBuilder : null,
      );

  PolylineLayer get polylineLayer => PolylineLayer(
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
                    color: context.isDarkMode ? Colors.white : Colors.black54,
                  ))
            ]
          : []);

  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid) {
      platform = TargetPlatform.android;
    } else {
      platform = TargetPlatform.iOS;
    }

    ////
    // 1.  Listen to events (See docs for all 12 available events).
    //

    // Fired whenever a location is recorded
    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      print('[location] - $location');
      setState(() {
        this.location = location;

        final waypoint = LatLng(location.coords.latitude, location.coords.longitude);

        mapController.fitCamera(CameraFit.coordinates(
            coordinates: [waypoint],
          padding: const EdgeInsets.all(32),
          maxZoom: 18,
          minZoom: 14,
          forceIntegerZoomLevel: false
        ));
        numSamples += 1;
        locationHistory.add(waypoint);
        locationTimestamps.add(DateTime.parse(location.timestamp));
      });
    });

    // Fired whenever the plugin changes motion-state (stationary->moving and vice-versa)
    bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
      print('[motionchange] - $location');
    });

    // Fired whenever the state of location-services changes.  Always fired at boot
    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
      print('[providerchange] - $event');
    });

    ////
    // 2.  Configure the plugin
    //
    bg.BackgroundGeolocation.ready(bg.Config(
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        enableTimestampMeta: true,
        distanceFilter: 0.1,  // set to 1m in production
        stopOnTerminate: false,
        persistMode: bg.Config.PERSIST_MODE_LOCATION,
        startOnBoot: true,
        debug: true,
        stopOnStationary: false,
        reset: true,
        logLevel: bg.Config.LOG_LEVEL_VERBOSE));
  }

  @override
  void dispose() {
    super.dispose();
    mapController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokalizacja'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: LatLng(52.23202828872916, 21.006132649819673), // Warsaw
                  initialZoom: 15,
               ),
                children: [openStreetMapTileLayer, polylineLayer, markerLayer],
              ),
            ),
            SizedBox(
              height: 16,
            ),
            Text("Toggle tracking"),
            Switch(
                value: isTracking,
                onChanged: (v) {
                  setState(() {
                    isTracking = v;
                  });
                  if (v) {
                    bg.BackgroundGeolocation.start().then((bg.State state) {
                      print('[start] success $state');
                    });
                    bg.BackgroundGeolocation.changePace(true);
                    trackingStartedTimestamp = DateTime.now();
                  } else {
                    bg.BackgroundGeolocation.stop();
                  }
                }),
            SizedBox(
              height: 16,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(
                    onPressed: () {
                      setState(() {
                        bg.BackgroundGeolocation.getCurrentPosition(
                                maximumAge: 0,
                                persist: false,
                                // <-- do not persist this location
                                desiredAccuracy: 0,
                                // <-- desire best possible accuracy
                                timeout: 30000,
                                // <-- wait 30s before giving up.
                                samples: 1 // <-- sample 3 location before selecting best.
                                )
                            .then((bg.Location location) {
                          print('[getCurrentPosition] - $location');
                          this.location = location;
                        }).catchError((error) {
                          print('[getCurrentPosition] ERROR: $error');
                        });
                      });
                    },
                    child: Text("Force update")),
                SizedBox(
                  width: 16,
                ),
                OutlinedButton(
                    onPressed: () {
                      setState(() {
                        locationHistory.clear();
                        locationTimestamps.clear();
                        numSamples = 0;
                      });
                    },
                    child: Text("Clear history")),
              ],
            ),
            SizedBox(
              height: 16,
            ),
            Text(
              "Last location:",
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text("lat: ${location?.coords.latitude}\n"
                "lon: ${location?.coords.longitude}\n"
                "last update: ${location?.timestamp}\n"
                "activity type: ${location?.activity.type}\n"
                "confidence: ${location?.activity.confidence}"),
            SizedBox(
              height: 16,
            ),
            Text("Samples: ${numSamples}"),
            SizedBox(
              height: 16,
            ),
            OutlinedButton(
                onPressed: () async {
                  _permissionReady = await _checkPermission();
                  if (!_permissionReady) {
                    showNotification(context, "Missing permissions");
                    return;
                  }

                  await _prepareSaveDir();
                  print("Saving gpx...");

                  final uuid = Uuid().v1();
                  final gpx = dumpGpx(
                    locationHistory,
                    locationTimestamps,
                    uuid,
                    "This is a test GPX file"
                  );
                  final writer = GpxWriter().asString(gpx, pretty: true);
                  final path = "${_localPath}ride_$uuid";
                  final file = File(path);
                  file.writeAsString(writer.toString());
                  showNotification(context, "Wrote to $path");
                },
                child: Text("Dump GPX")),
            SizedBox(
              height: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkPermission() async {
    if (platform == TargetPlatform.android) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.manageExternalStorage.request();
        if (result == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

  Future<void> _prepareSaveDir() async {
    _localPath = (await _findLocalPath())!;

    print(_localPath);
    final savedDir = Directory(_localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
  }

  Future<String?> _findLocalPath() async {
    if (platform == TargetPlatform.android) {
      return "/sdcard/download/";
    } else {
      var directory = await getApplicationDocumentsDirectory();
      return directory.path + Platform.pathSeparator + 'Download';
    }
  }

  void showNotification(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
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

extension DarkMode on BuildContext {
  /// is dark mode currently enabled?
  bool get isDarkMode {
    final brightness = MediaQuery.of(this).platformBrightness;
    return brightness == Brightness.dark;
  }
}


