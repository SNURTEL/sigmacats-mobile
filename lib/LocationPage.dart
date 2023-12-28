import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
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
  int currentIndex = 4;
  int num_samples = 0;
  bool isTracking = false;

  bg.Location? location;

  final mapController = MapController();

  TileLayer get openStreetMapTileLayer => TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'dev.fleaflet.flutter_map.example',
        // Use the recommended flutter_map_cancellable_tile_provider package to
        // support the cancellation of loading tiles.
        tileProvider: CancellableNetworkTileProvider(),
      );
  
  MarkerLayer get markerLayer => MarkerLayer(
      markers: location != null ? [Marker(
          point: LatLng(
            location!.coords.latitude, location!.coords.longitude
          ),
          child: Icon(Icons.person))] : []
  );

  @override
  void initState() {
    super.initState();

    ////
    // 1.  Listen to events (See docs for all 12 available events).
    //

    // Fired whenever a location is recorded
    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      print('[location] - $location');
      setState(() {
        this.location = location;
        num_samples += 1;
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
        distanceFilter: 0.1,
        stopOnTerminate: false,
        persistMode: bg.Config.PERSIST_MODE_LOCATION,
        startOnBoot: true,
        debug: true,
        logLevel: bg.Config.LOG_LEVEL_VERBOSE));
  }

  @override
  void dispose() {
    // TODO: implement dispose
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
                  initialZoom: 20,
                  // interactionOptions:
                  // InteractionOptions(flags: uploadedGpxObject != null ? InteractiveFlag.all : InteractiveFlag.none)
                ),
                children: [
                  openStreetMapTileLayer,
                  markerLayer
                ],
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
                  } else {
                    bg.BackgroundGeolocation.stop();
                  }
                }),
            SizedBox(
              height: 16,
            ),
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
                child: Text("Update location")),
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
            Text("Samples: ${num_samples}"),
          ],
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
              Navigator.pushReplacementNamed(context, '/race_list', arguments: "");
              break;
            case 1:
              // Ranking
              Navigator.pushReplacementNamed(context, '/ranking', arguments: "");
              break;
            case 2:
              // Aktualny wyścig
              Navigator.pushReplacementNamed(context, '/race_participation', arguments: "");
              break;
            case 3:
              // Mój profil
              Navigator.pushReplacementNamed(context, '/user_profile', arguments: "");
              break;
            case 4:
              break;
          }
        },
      ),
    );
  }
}
