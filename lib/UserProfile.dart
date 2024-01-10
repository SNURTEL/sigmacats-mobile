import 'dart:convert';
import 'functions.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'BottomNavigationBar.dart';

class UserProfile extends StatefulWidget {
  final String accessToken;
  const UserProfile({Key? key, required this.accessToken}) : super(key: key);

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
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
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/users/me'),
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
        if (userInfo['gender'] == 'male')
          {
            gender = 'Mężczyzna';
          }
        else if (userInfo['gender'] == 'female')
          {
            gender = 'Kobieta';
          }
        if (userInfo['birth_date'] != null){
          birthDate = userInfo['birth_date'];
        }
      });
    } else {
      throw Exception('Failed to load user info');
    }
  }

  Future<void> fetchBikesDetails() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:80/api/rider/bike/'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mój profil'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Płeć: $gender',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
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
    );
  }

  List<ExpansionPanel> buildBikeExpansionPanels() {
    return bikes.asMap().entries.toList().map((entry) {
      final cardId = entry.key;
      final bike = entry.value;
      String bikeType = 'inny';
      if(bike['type'] == 'road' || bike['type'] == 'szosa')
        {
          bikeType = 'szosa';
        }
      else if(bike['type'] == 'fixie' || bike['type'] == 'ostre koło')
      {
        bikeType = 'szosa';
      }

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
                  //style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Model: ${bike['model']}',
                  //style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Type: $bikeType',
                  //style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ),
        isExpanded: isBikeExpanded[cardId] ?? false,
      );
    }).toList();
  }

}
