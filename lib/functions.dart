import 'package:intl/intl.dart';

String formatDateString(String dateString) {
  if (dateString == 'null') {
    return  'null';
  }
  DateTime dateTime = DateFormat("yyyy-MM-ddTHH:mm:ss").parse(dateString, true).toLocal();
  String formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
  return formattedDate;
}

String formatDateStringToHours(String dateString) {
  if (dateString == 'null') {
    return  'null';
  }
  DateTime dateTime = DateFormat("yyyy-MM-ddTHH:mm:ss").parse(dateString, true).toLocal();
  String formattedDate = DateFormat('HH:mm').format(dateTime);
  return formattedDate;
}

String formatDateStringDay(String dateString) {
  if (dateString == 'null') {
    return  'null';
  }
  DateTime dateTime = DateFormat("yyyy-MM-ddTHH:mm:ss").parse(dateString, true).toLocal();
  String formattedDate = DateFormat('dd.MM.yyyy').format(dateTime);
  return formattedDate;
}

bool isToday(String dateString) {
  DateTime today = DateTime.now();
  DateTime raceDate = DateFormat("yyyy-MM-ddTHH:mm:ss").parse(dateString, true).toLocal();
  return today.year == raceDate.year &&
      today.month == raceDate.month &&
      today.day == raceDate.day;
}
