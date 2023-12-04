import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RaceDetails extends StatefulWidget {
  final int id;

  RaceDetails(this.id);

  @override
  _RaceDetailsState createState() => _RaceDetailsState();
}

class _RaceDetailsState extends State<RaceDetails> {
  String selectedValue = 'Szosa';
  String raceName = '';
  String raceDescription = '';

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
        raceDescription = raceDetails['description'];
      });
    } else {
      // If the server did not return a 200 OK response, throw an exception.
      throw Exception('Failed to load race details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(raceName),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'lib/sample_image.png',
              fit: BoxFit.cover,
            ),
            SizedBox(height: 16.0),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text(
                    'Race Description: $raceDescription',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                showAddTextDialog(context);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 8.0),
                  Text('Weź udział w wyścigu!'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showAddTextDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Wybierz swój rower:'),
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
                    items: [
                      'Szosa',
                      'Ostre koło',
                      'Inny',
                      // Add more items as needed
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the dialog
                        },
                        child: Text('Anuluj'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          showNotification(context, 'Udało się zapisać na wyścig!');
                          Navigator.pop(context); // Close the dialog
                        },
                        child: Text('Accept'),
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
      duration: Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}