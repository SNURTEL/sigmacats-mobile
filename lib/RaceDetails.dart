import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'functions.dart';

class RaceDetails extends StatefulWidget {
  final int id;

  const RaceDetails(this.id, {super.key});

  @override
  _RaceDetailsState createState() => _RaceDetailsState();
}

class _RaceDetailsState extends State<RaceDetails> {
  String selectedValue = '';
  String raceName = '';
  String requirements = '';
  String raceDescription = '';
  String meetupTimestamp = '2000-01-01T00:00:00'; // Dummy date
  int numberOfLaps = 0;
  int entryFeeGr = 0;
  List<String> bikeNames = [];
  String selectedBike = '';

  @override
  void initState() {
    super.initState();
    // Fetch additional details for the race when the widget is created
    fetchRaceDetails();
  }

  Future<void> fetchRaceDetails() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/api/rider/race/${widget.id}'));

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the race details
      final Map<String, dynamic> raceDetails = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        raceName = raceDetails['name'];
        requirements = raceDetails['requirements'];
        numberOfLaps = raceDetails['no_laps'];
        entryFeeGr = raceDetails['entry_fee_gr'];
        raceDescription = raceDetails['description'];
        meetupTimestamp = raceDetails['meetup_timestamp'];
      });
    } else {
      // If the server did not return a 200 OK response, throw an exception.
      throw Exception('Failed to load race details');
    }
  }

  Future<void> fetchBikeNames() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/api/rider/bike/?rider_id=1'));

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the bike names
      final List<dynamic> bikes = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        bikeNames = bikes.map((bike) => bike['name'].toString()).toList();
        if (bikeNames.isNotEmpty) {
          selectedValue = bikeNames[0]; // Set the default selected bike
        }
      });
    } else {
      // If the server did not return a 200 OK response, throw an exception.
      throw Exception('Failed to load bike names');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(formatDateString(meetupTimestamp)),
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
                              'Wpisowe: ${(entryFeeGr/100).toStringAsFixed(2)}zł',
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
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
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
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
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5.0),
                        Text(
                          requirements,
                          style: TextStyle(fontSize: 14.0),
                        ),
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
                          'Opis',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5.0),
                        Text(
                          raceDescription,
                          style: TextStyle(fontSize: 14.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showAddTextDialog(context);
        },
        label: const Text('Weź udział w wyścigu!'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void showAddTextDialog(BuildContext context) {
    fetchBikeNames(); // Fetch bike names before showing the dialog
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
                    items: bikeNames.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
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
                          showNotification(context, 'Udało się zapisać na wyścig!');
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

  void showNotification(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
