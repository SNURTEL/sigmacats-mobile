import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'RaceDetails.dart';
import 'RaceParticipation.dart';
import 'functions.dart';

class RaceList extends StatefulWidget {
  const RaceList({Key? key}) : super(key: key);

  @override
  _RaceListState createState() => _RaceListState();
}

class _RaceListState extends State<RaceList> {
  List<Race> itemList = [];

  @override
  void initState() {
    super.initState();
    // Fetch the list of races when the widget is created
    fetchRaceList();
  }

  Future<void> fetchRaceList() async {
    final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/rider/race/?rider_id=1'));

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the races from the response
      final List<dynamic> races = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        itemList = races.map((race) => Race.fromJson(race)).toList();
      });
    } else {
      // If the server did not return a 200 OK response, throw an exception.
      throw Exception('Failed to load races');
    }
  }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Dostępne wyścigi'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Scrollbar(
//           child: ListView.builder(
//             itemCount: itemList.length,
//             itemBuilder: (context, index) {
//               Color cardColor = Theme.of(context).colorScheme.surfaceVariant; // Default color
//               // Check if the status is "ended" and set the card color to gray
//               if (itemList[index].status == 'ended') {
//                 cardColor = Theme.of(context).colorScheme.outlineVariant; // Set the color to gray
//               }
//               return Column(
//                 children: [
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => RaceDetails(itemList[index].id),
//                         ),
//                       );
//                     },
//                     child: Card(
//                       margin: const EdgeInsets.all(5.0),
//                       color: cardColor, // Set the color based on the status
//                       child: Column(
//                         children: [
//                           Container(
//                             height: 160.0,
//                             width: double.infinity,
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.only(
//                                 topLeft: Radius.circular(16.0),
//                                 topRight: Radius.circular(16.0),
//                               ),
//                               child: Image.asset(
//                                 'lib/sample_image.png',
//                                 fit: BoxFit.fitWidth,
//                               ),
//                             ),
//                           ),
//                           ListTile(
//                             contentPadding: const EdgeInsets.all(10.0),
//                             title: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   itemList[index].name,
//                                   style: Theme.of(context).textTheme.titleLarge,
//                                 ),
//                                 SizedBox(height: 5.0),
//                                 Text(
//                                   '${formatDateString(itemList[index].timeStart)}-${formatDateStringToHours(itemList[index].timeEnd)}',
//                                   style: Theme.of(context).textTheme.bodyMedium,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 8.0), // Add space between list elements
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => RaceParticipation(),
//             ),
//           );
//         },
//         label: Text('Rozpocznij wyścig'),
//         icon: Icon(Icons.pedal_bike),
//       ),
//     );
//   }
// }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Dostępne wyścigi'),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: RefreshIndicator(
        onRefresh: fetchRaceList, // Fetch data when pulled down
        child: Scrollbar(
          child: ListView.builder(
            itemCount: itemList.length,
            itemBuilder: (context, index) {
              Color cardColor = Theme.of(context).cardColor; // Default color
              // Check if the status is "ended" and set the card color to gray
              if (itemList[index].status == 'ended') {
                cardColor = Theme.of(context).colorScheme.secondaryContainer; // Set the color to gray
              }
              return Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RaceDetails(itemList[index].id),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.all(5.0),
                      color: cardColor, // Set the color based on the status
                      child: Column(
                        children: [
                          Container(
                            height: 160.0,
                            width: double.infinity,
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16.0),
                                topRight: Radius.circular(16.0),
                              ),
                              child: Image.asset(
                                'lib/sample_image.png',
                                fit: BoxFit.fitWidth,
                              ),
                            ),
                          ),
                          ListTile(
                            contentPadding: const EdgeInsets.all(10.0),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  itemList[index].name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                SizedBox(height: 5.0),
                                Text(
                                  '${formatDateString(itemList[index].timeStart)}-${formatDateStringToHours(itemList[index].timeEnd)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8.0), // Add space between list elements
                ],
              );
            },
          ),
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RaceParticipation(),
          ),
        );
      },
      label: Text('Rozpocznij wyścig'),
      icon: Icon(Icons.pedal_bike),
    ),
  );
}
}

class Race {
  final int id;
  final String name;
  final String status;
  final String timeStart;
  final String timeEnd;

  Race({required this.id, required this.name, required this.status, required this.timeStart, required this.timeEnd});

  factory Race.fromJson(Map<String, dynamic> json) {
    return Race(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      timeStart: json['start_timestamp'],
      timeEnd: json['end_timestamp'],
    );
  }
}
