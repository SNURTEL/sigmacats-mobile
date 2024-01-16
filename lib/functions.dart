import 'package:intl/intl.dart';

"""
This file contains functions shared between different components of the page
"""

String formatDateString(String dateString) {
  """
  Formats date to a format used by the app
  """
  if (dateString == 'null') {
    return  'null';
  }
  DateTime dateTime = DateFormat("yyyy-MM-ddTHH:mm:ss").parse(dateString, true).toLocal();
  String formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
  return formattedDate;
}

String formatDateStringToHours(String dateString) {
  """
  Formats date to be shown using hours. Used by the app
  """
  if (dateString == 'null') {
    return  'null';
  }
  DateTime dateTime = DateFormat("yyyy-MM-ddTHH:mm:ss").parse(dateString, true).toLocal();
  String formattedDate = DateFormat('HH:mm').format(dateTime);
  return formattedDate;
}

String formatDateStringDay(String dateString) {
  """
  Formats date to be shown using days. Used by the app
  """
  if (dateString == 'null') {
    return  'null';
  }
  DateTime dateTime = DateFormat("yyyy-MM-ddTHH:mm:ss").parse(dateString, true).toLocal();
  String formattedDate = DateFormat('dd.MM.yyyy').format(dateTime);
  return formattedDate;
}

bool isToday(String dateString) {
  """
  Checks if the given day is the current day. Used by the app
  """
  DateTime today = DateTime.now();
  DateTime raceDate = DateFormat("yyyy-MM-ddTHH:mm:ss").parse(dateString, true).toLocal();
  return today.year == raceDate.year &&
      today.month == raceDate.month &&
      today.day == raceDate.day;
}
