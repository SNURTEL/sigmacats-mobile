import 'package:flutter/material.dart';

class RaceDetails extends StatefulWidget {
  final String itemName;

  RaceDetails(this.itemName);

  @override
  _RaceDetailsState createState() => _RaceDetailsState();
}

class _RaceDetailsState extends State<RaceDetails> {
  String selectedValue = 'Szosa'; // Set an initial selected value

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemName),
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
              child: Text(
                'Additional Details:\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam tristique lorem et volutpat fermentum. Praesent dapibus velit id auctor dignissim. Donec pharetra odio vel semper aliquam. Proin nec ligula in sem gravida fermentum vel in arcu. Nullam ac sem vel ante vehicula interdum. Curabitur ultrices rhoncus finibus. Phasellus eu libero. ',
                style: TextStyle(fontSize: 16.0),
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