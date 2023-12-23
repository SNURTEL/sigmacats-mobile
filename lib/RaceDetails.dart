import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'functions.dart';

class RaceDetails extends StatefulWidget {
  final int id;

  const RaceDetails(this.id, {Key? key}) : super(key: key);

  @override
  _RaceDetailsState createState() => _RaceDetailsState();
}

class _RaceDetailsState extends State<RaceDetails> {
  String selectedValue = '';
  String raceName = '';
  String status = '';
  String requirements = '';
  String raceDescription = '';
  String meetupTimestamp = 'null';
  String startTimestamp = '2000-01-01T00:00:00';
  String endTimestamp = '2000-01-01T00:00:00';
  int numberOfLaps = 0;
  int entryFeeGr = 0;
  List<Map<String, dynamic>> bikes = [];
  String selectedBike = '';
  bool isParticipating = false;

  @override
  void initState() {
    super.initState();
    // Fetch additional details for the race when the widget is created
    fetchRaceDetails();
  }

  Future<void> fetchRaceDetails() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:80/api/rider/race/${widget.id}?rider_id=1'));

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the race details
      final Map<String, dynamic> raceDetails = json.decode(utf8.decode(response.bodyBytes));

      // Extract participation status from the response
      final String? participationStatus = raceDetails['participation_status'];

      // Check if the user is participating
      final bool userParticipating = participationStatus != null;

      setState(() {
        raceName = raceDetails['name'];
        requirements = raceDetails['requirements'];
        status = raceDetails['status'];
        numberOfLaps = raceDetails['no_laps'];
        entryFeeGr = raceDetails['entry_fee_gr'];
        raceDescription = raceDetails['description'];
        if (raceDetails['meetup_timestamp'] != null){
          meetupTimestamp = raceDetails['meetup_timestamp'];
        }
        startTimestamp = raceDetails['start_timestamp'];
        endTimestamp = raceDetails['end_timestamp'];
        isParticipating = userParticipating;
      });
    } else {
      // If the server did not return a 200 OK response, throw an exception.
      throw Exception('Failed to load race details');
    }
  }

  Future<List<Map<String, dynamic>>> fetchBikeNames() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:80/api/rider/bike/?rider_id=1'));

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the bike names and ids
      final List<dynamic> bikeList = json.decode(utf8.decode(response.bodyBytes));
      final List<Map<String, dynamic>> bikesData = bikeList
          .map((bike) => {'id': bike['id'], 'name': bike['name'].toString()})
          .toList();
      setState(() {
        bikes = bikesData;
        if (bikes.isNotEmpty) {
          selectedValue = bikes[0]['name']; // Set the default selected bike
        }
      });
      return bikesData;
    } else {
      // If the server did not return a 200 OK response, throw an exception.
      throw Exception('Failed to load bike names');
    }
  }

  Future<void> joinRace(int bikeId) async {
    final response = await http.post(
        Uri.parse('http://10.0.2.2:80/api/rider/race/${widget.id}/join?rider_id=1&bike_id=$bikeId'));

    if (response.statusCode == 200) {
      setState(() {
        isParticipating = true;
      });
      showNotification(context, 'Udało się zapisać na wyścig!');
    } else {
      showNotification(context, 'Błąd podczas zapisywania na wyścig');
    }
  }

  Future<void> withdrawFromRace() async {
    final response =
    await http.post(Uri.parse('http://10.0.2.2:80/api/rider/race/${widget.id}/withdraw?rider_id=1'));

    if (response.statusCode == 200) {
      setState(() {
        isParticipating = false;
      });
      showNotification(context, 'Wycofano udział z wyścigu');
    } else {
      showNotification(context, 'Błąd podczas wycofywania udziału z wyścigu');
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Image.asset(
                  'lib/sample_image.png',
                  fit: BoxFit.fitWidth, // Ensure the image fills the container
                ),
              ),
              const SizedBox(height: 5.0),
              // Card with race name and meetupTimestamp
              Card(
                child: ListTile(
                  title: Text(
                    raceName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: meetupTimestamp != 'null'
                      ? Text('Zbiórka: ${formatDateString(meetupTimestamp)}\nCzas trwania: ${formatDateString(startTimestamp)}-${formatDateStringToHours(endTimestamp)}')
                      : Text('Czas trwania: ${formatDateString(startTimestamp)}-${formatDateStringToHours(endTimestamp)}'),
                ),
              ),
              const SizedBox(height: 5.0),
              // Two separate cards for entryFeeGr and numberOfLaps (each taking half width)
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
                              'Ilość okrążeń: ${numberOfLaps.toString()}',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5.0),
              // Card with requirements (full width)
              Container(
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
              const SizedBox(height: 5.0),
              // Card with raceDescription (full width)
              Container(
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
              if (status != 'ended') const SizedBox(height: 60.0),  // Add SizedBox conditionally
            ],
          ),
        ),
      ),
      floatingActionButton: status == 'ended'
          ? null  // Set onPressed to null when status is 'ended'
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

  void showAddTextDialog(BuildContext context) async {
    // Fetch bike names before showing the dialog
    final bikeNames = await fetchBikeNames();
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
                  DropdownButton<String>(
                    value: selectedValue,
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
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the dialog
                        },
                        child: const Text('Anuluj'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Get the selected bike id based on the name
                          final selectedBikeId = getSelectedBikeId(selectedValue);
                          joinRace(selectedBikeId);
                          Navigator.pop(context); // Close the dialog
                        },
                        child: const Text('Accept'),
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
    final selectedBike = bikes.firstWhere((bike) => bike['name'] == bikeName, orElse: () => {'id': -1});
    return selectedBike['id'];
  }

  void showNotification(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
