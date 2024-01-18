
class Race {
  ///  Defines a race class, used for displaying races in the app
  final int id;
  final String name;
  final String status;
  final String eventGraphic;
  final String timeStart;
  final String timeMeetUp;
  final String? participationStatus;
  final bool userParticipating;
  final bool isApproved;

  Race(
      {required this.id,
        required this.name,
        required this.status,
        required this.eventGraphic,
        required this.timeStart,
        required this.timeMeetUp,
        required this.userParticipating,
        required this.participationStatus,
        required this.isApproved});

  factory Race.fromJson(Map<String, dynamic> json) {
    ///    Creates a race class object from JSON
    bool participating = false;
    String meetupTimestamp = 'null';
    final String? participationStatus = json['participation_status'];
    if (participationStatus != null) {
      participating = true;
    }
    if (json['meetup_timestamp'] != null) {
      meetupTimestamp = json['meetup_timestamp'];
    }

    return Race(
        id: json['id'],
        name: json['name'],
        status: json['status'],
        eventGraphic: json['event_graphic_file'],
        timeStart: json['start_timestamp'],
        timeMeetUp: meetupTimestamp,
        userParticipating: participating,
        participationStatus: participationStatus,
        isApproved: json['is_approved']);
  }
}

class RaceScores {
  ///  Defines a race scores class, used for displaying race results in the app
  final int id;
  final String riderName;
  final String riderSurname;
  final String riderUsername;
  final int place;
  final double time;

  RaceScores(
      {required this.id,
        required this.riderName,
        required this.riderSurname,
        required this.riderUsername,
        required this.place,
        required this.time});

  factory RaceScores.fromJson(Map<String, dynamic> json) {
    ///    Creates a race scores object from JSON
    return RaceScores(
        id: json['id'],
        riderName: json['rider_name'],
        riderSurname: json['rider_surname'],
        riderUsername: json['rider_username'],
        place: json['place_assigned_overall'],
        time: json['time_seconds']);
  }
}
