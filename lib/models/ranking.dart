class Classification {
  ///  Defines a classification class, used for displaying rankings in the app
  final int id;
  final String name;
  final String description;

  Classification({required this.id, required this.name, required this.description});

  factory Classification.fromJson(Map<String, dynamic> json) {
    ///    Creates a classification class object from JSON
    return Classification(id: json['id'], name: json['name'], description: json['description']);
  }
}

class Season {
  ///  Defines a season class, used for displaying rankings in the app
  final int id;
  final String name;
  final String startTimestamp;
  final String? endTimestamp;

  Season({required this.id, required this.name, required this.startTimestamp, required this.endTimestamp});

  factory Season.fromJson(Map<String, dynamic> json) {
    ///    Creates a season class object from JSON
    return Season(
      id: json['id'],
      name: json['name'],
      startTimestamp: json['start_timestamp'],
      endTimestamp: json['end_timestamp'],
    );
  }
}

class ScoreRow {
  ///  Defines a score row class, used for displaying rankings in the app
  final int score;
  final String name;
  final String surname;
  final String username;

  ScoreRow({required this.score, required this.name, required this.surname, required this.username});

  factory ScoreRow.fromJson(Map<String, dynamic> json) {
    ///    Creates a score row class object from JSON
    return ScoreRow(score: json['score'], name: json['name'], surname: json['surname'], username: json['username']);
  }
}

class User {
  ///  Defines a user class, used for displaying rankings in the app
  final String name;
  final String surname;
  final String username;

  User({required this.name, required this.surname, required this.username});

  factory User.fromJson(Map<String, dynamic> json) {
    ///    Creates a user class object from JSON
    return User(name: json['name'], surname: json['surname'], username: json['username']);
  }
}