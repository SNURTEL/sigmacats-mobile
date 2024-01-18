import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:move_to_background/move_to_background.dart';

import 'package:sigmactas_alleycat/util/notification.dart';
import 'package:sigmactas_alleycat/components/BottomNavigationBar.dart';
import 'package:sigmactas_alleycat/util/dates.dart';
import 'package:sigmactas_alleycat/util/settings.dart' as settings;

class UserProfile extends StatefulWidget {
  ///  User profile page widget
  final String accessToken;

  const UserProfile({super.key, required this.accessToken});

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  ///  User profile page state
  int currentIndex = 3;
  int userId = 0;
  String username = '';
  String name = '';
  String surname = '';
  String email = '';
  String gender = 'Inna';
  String birthDate = '1900-01-01T00:00:00';
  List<Map<String, dynamic>> bikes = [];
  Map<int, bool> isBikeExpanded = {};

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
    fetchBikesDetails();
  }

  Future<void> fetchUserInfo() async {
    ///    Fetches user data from server
    final response = await http.get(
      Uri.parse('${settings.apiBaseUrl}/api/users/me'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> userInfo = json.decode(utf8.decode(response.bodyBytes));

      setState(() {
        userId = userInfo['id'];
        username = userInfo['username'];
        name = userInfo['name'];
        surname = userInfo['surname'];
        email = userInfo['email'];
        if (userInfo['gender'] == 'male') {
          gender = 'Mężczyzna';
        } else if (userInfo['gender'] == 'female') {
          gender = 'Kobieta';
        }
        if (userInfo['birth_date'] != null) {
          birthDate = userInfo['birth_date'];
        }
      });
    } else {
      throw Exception('Failed to load user info');
    }
  }

  Future<void> fetchBikesDetails() async {
    ///    Fetches bikes of a user from server
    final response = await http.get(
      Uri.parse('${settings.apiBaseUrl}/api/rider/bike/'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> bikeList = json.decode(utf8.decode(response.bodyBytes));
      final List<Map<String, dynamic>> bikesData = bikeList
          .where((bike) => bike['is_retired'] == false)
          .map((bike) => {'id': bike['id'], 'name': bike['name'], 'brand': bike['brand'], 'model': bike['model'], 'type': bike['type']})
          .toList();
      final Map<int, bool> initialIsBikeExpanded = {};
      int cardId = 0;
      while (cardId < bikesData.length) {
        initialIsBikeExpanded[cardId] = false;
        cardId += 1;
      }
      setState(() {
        bikes = bikesData;
        isBikeExpanded = initialIsBikeExpanded;
      });
    } else {
      throw Exception('Failed to load bike names');
    }
  }

  Future<void> deleteBike(int bikeId) async {
    ///    Make a delete bike request to server and show notification
    Map data = {"is_retired": "true"};
    var body = json.encode(data);
    final response = await http.patch(
      Uri.parse('${settings.apiBaseUrl}/api/rider/bike/$bikeId'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}', "Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      await fetchUserInfo();
      await fetchBikesDetails();
      setState(() {});
      showNotification(context, 'Udało się usunąć rower!');
    } else {
      showNotification(context, 'Błąd podczas usuwania roweru ${response.statusCode}');
    }
  }

  Future<void> editBike(final bikeInfo) async {
    ///    Make a edit bike request to server and show notification
    Map data = {
      "name": bikeInfo['name'],
      "type": bikeInfo['type'],
      "brand": bikeInfo['brand'],
      "model": bikeInfo['model'],
    };
    var body = json.encode(data);
    final response = await http.patch(
      Uri.parse('${settings.apiBaseUrl}/api/rider/bike/${bikeInfo['id']}'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}', "Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      await fetchUserInfo();
      await fetchBikesDetails();
      setState(() {});
      showNotification(context, 'Udało się edytować rower!');
    } else {
      showNotification(context, 'Błąd podczas edytowania roweru ${response.statusCode}');
    }
  }

  Future<void> addBike(final bikeInfo) async {
    ///    Make a create bike request to server and show notification
    Map data = {
      "name": bikeInfo['name'],
      "type": bikeInfo['type'],
      "brand": bikeInfo['brand'],
      "model": bikeInfo['model'],
    };
    var body = json.encode(data);
    final response = await http.post(
      Uri.parse('${settings.apiBaseUrl}/api/rider/bike/create'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}', "Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      await fetchUserInfo();
      await fetchBikesDetails();
      setState(() {});
      showNotification(context, 'Udało się dodać nowy rower!');
    } else {
      showNotification(context, 'Błąd podczas dodawania roweru ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    ///    Builds the user profile widget
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) {
          return;
        }
        MoveToBackground.moveTaskToBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mój profil'),
          automaticallyImplyLeading: false,
          centerTitle: true,
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
                showNotification(context, 'Wylogowano!');
              },
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                  child: ListTile(
                    title: Text(
                      username,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    subtitle: Text('$name $surname'),
                  ),
                ),
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
                            'Adres e-mail: $email',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Data urodzenia: ${formatDateStringDay(birthDate)}r.',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 110,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Płeć: $gender',
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
                Card(
                  child: ListTile(
                    title: Text(
                      'Twoje rowery',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 5.0),
                Card(
                  child: ExpansionPanelList(
                    expandedHeaderPadding: const EdgeInsets.all(0.0),
                    materialGapSize: 0,
                    elevation: 0,
                    expansionCallback: (int cardId, bool isExpanded) {
                      setState(() {
                        isBikeExpanded[cardId] = isExpanded;
                      });
                    },
                    children: buildBikeExpansionPanels(),
                  ),
                ),
                const SizedBox(height: 5.0),
                ElevatedButton.icon(
                  onPressed: () {
                    showAddBikeDialog(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Dodaj rower',
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBarWidget(
          currentIndex: currentIndex,
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
            switch (currentIndex) {
              case 0:
                Navigator.pushReplacementNamed(context, '/race_list', arguments: widget.accessToken);
                break;
              case 1:
                Navigator.pushReplacementNamed(context, '/ranking', arguments: widget.accessToken);
                break;
              case 2:
                Navigator.pushReplacementNamed(context, '/race_participation', arguments: widget.accessToken);
                break;
              case 3:
                // UserProfile
                break;
            }
          },
        ),
      ),
    );
  }

  List<ExpansionPanel> buildBikeExpansionPanels() {
    ///    Builds expansion panels for choosing bike type
    return bikes.asMap().entries.toList().map((entry) {
      final cardId = entry.key;
      final bike = entry.value;
      Map<String, String> bikeTypesMap = {'other': 'inny', 'road': 'szosa', 'fixie': 'ostre koło'};

      return ExpansionPanel(
        backgroundColor: Colors.transparent,
        headerBuilder: (BuildContext context, bool isExpanded) {
          return ListTile(
            title: Text(
              bike['name'],
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        },
        body: Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Marka: ${bike['brand']}',
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Model: ${bike['model']}',
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Typ: ${bikeTypesMap[bike['type']]}',
                ),
              ),
              const SizedBox(height: 10.0),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      showDeleteBikeDialog(context, bike['id']);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text(
                      'Usuń',
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {
                      showEditBikeDialog(context, bike);
                    },
                    icon: const Icon(Icons.edit_note),
                    label: const Text(
                      'Edytuj',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        isExpanded: isBikeExpanded[cardId] ?? false,
      );
    }).toList();
  }

  void showDeleteBikeDialog(BuildContext context, int bikeId) async {
    ///    Method for showing dialog popup for deleting a bike
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Czy na pewno chcesz usunąć ten rower?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                          deleteBike(bikeId);
                          Navigator.pop(context);
                        },
                        child: const Text('Usuń'),
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

  void showEditBikeDialog(BuildContext context, final bike) async {
    ///    Method for showing dialog popup for editing bike details
    TextEditingController bikeName = TextEditingController(text: bike['name']);
    TextEditingController bikeBrand = TextEditingController(text: bike['brand']);
    TextEditingController bikeModel = TextEditingController(text: bike['model']);
    List<Map<String, String>> bikeTypes = [
      {'display': 'szosa', 'value': 'road'},
      {'display': 'ostre koło', 'value': 'fixie'},
      {'display': 'inny', 'value': 'other'},
    ];
    String selectedBikeType = bike['type'];

    GlobalKey<FormState> editFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Zaktualizuj informacje o swoim rowerze'),
              content: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: editFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Pole nie może zostać puste";
                            }
                            return null;
                          },
                          controller: bikeName,
                          decoration: const InputDecoration(
                            labelText: 'Nazwa',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Pole nie może zostać puste";
                            }
                            return null;
                          },
                          controller: bikeBrand,
                          decoration: const InputDecoration(
                            labelText: 'Marka',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Pole nie może zostać puste";
                            }
                            return null;
                          },
                          controller: bikeModel,
                          decoration: const InputDecoration(
                            labelText: 'Model',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        DropdownButtonFormField<String>(
                          value: selectedBikeType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Typ',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              selectedBikeType = value!;
                            });
                          },
                          items: bikeTypes.map<DropdownMenuItem<String>>(
                            (Map<String, String> bikeType) {
                              return DropdownMenuItem<String>(
                                value: bikeType['value'],
                                child: Text('${bikeType['display']}'),
                              );
                            },
                          ).toList(),
                        ),
                        const SizedBox(height: 30.0),
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
                                if (editFormKey.currentState!.validate()) {
                                  bike['name'] = bikeName.text;
                                  bike['brand'] = bikeBrand.text;
                                  bike['model'] = bikeModel.text;
                                  bike['type'] = selectedBikeType;
                                  editBike(bike);
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text('Zaktualizuj'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showAddBikeDialog(BuildContext context) async {
    ///    Method for showing dialog popup for adding a new bike
    TextEditingController bikeName = TextEditingController();
    TextEditingController bikeBrand = TextEditingController();
    TextEditingController bikeModel = TextEditingController();
    List<Map<String, String>> bikeTypes = [
      {'display': 'szosa', 'value': 'road'},
      {'display': 'ostre koło', 'value': 'fixie'},
      {'display': 'inny', 'value': 'other'},
    ];
    String selectedBikeType = 'road';
    Map<String, String> newBikeInfo = {'name': '', 'brand': '', 'model': '', 'type': ''};

    GlobalKey<FormState> addFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Uzupełnij informacje o swoim rowerze'),
              content: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: addFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Pole nie może zostać puste";
                            }
                            return null;
                          },
                          controller: bikeName,
                          decoration: const InputDecoration(
                            labelText: 'Nazwa',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Pole nie może zostać puste";
                            }
                            return null;
                          },
                          controller: bikeBrand,
                          decoration: const InputDecoration(
                            labelText: 'Marka',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Pole nie może zostać puste";
                            }
                            return null;
                          },
                          controller: bikeModel,
                          decoration: const InputDecoration(
                            labelText: 'Model',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        DropdownButtonFormField<String>(
                          value: selectedBikeType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Typ',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              selectedBikeType = value!;
                            });
                          },
                          items: bikeTypes.map<DropdownMenuItem<String>>(
                            (Map<String, String> bikeType) {
                              return DropdownMenuItem<String>(
                                value: bikeType['value'],
                                child: Text('${bikeType['display']}'),
                              );
                            },
                          ).toList(),
                        ),
                        const SizedBox(height: 30.0),
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
                                if (addFormKey.currentState!.validate()) {
                                  newBikeInfo['name'] = bikeName.text;
                                  newBikeInfo['brand'] = bikeBrand.text;
                                  newBikeInfo['model'] = bikeModel.text;
                                  newBikeInfo['type'] = selectedBikeType;
                                  addBike(newBikeInfo);
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text('Dodaj'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
