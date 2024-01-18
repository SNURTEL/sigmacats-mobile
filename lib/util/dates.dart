import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

///This file contains functions shared between different components of the page

String formatDateString(String dateString) {
  ///  Formats date to a format used by the app
  if (dateString == 'null') {
    return 'null';
  }
  DateTime dateTime = DateFormat("yyyy-MM-ddTHH:mm:ss").parse(dateString, true).toLocal();
  String formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
  return formattedDate;
}

String formatDateStringToHours(String dateString) {
  ///  Formats date to be shown using hours. Used by the app
  if (dateString == 'null') {
    return 'null';
  }
  DateTime dateTime = DateFormat("yyyy-MM-ddTHH:mm:ss").parse(dateString, true).toLocal();
  String formattedDate = DateFormat('HH:mm').format(dateTime);
  return formattedDate;
}

String formatDateStringDay(String dateString) {
  ///  Formats date to be shown using days. Used by the app
  if (dateString == 'null') {
    return 'null';
  }
  DateTime dateTime = DateFormat("yyyy-MM-ddTHH:mm:ss").parse(dateString, true).toLocal();
  String formattedDate = DateFormat('dd.MM.yyyy').format(dateTime);
  return formattedDate;
}

bool isToday(String dateString) {
  ///  Checks if the given day is the current day. Used by the app
  DateTime today = DateTime.now();
  DateTime raceDate = DateFormat("yyyy-MM-ddTHH:mm:ss").parse(dateString, true).toLocal();
  return today.year == raceDate.year && today.month == raceDate.month && today.day == raceDate.day;
}

DateTime clipDay(DateTime d) {
  ///  Returns the day of the given date
  if (!DateUtils.isSameDay(d, DateTime.now())) {
    return DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
  } else {
    return d;
  }
}

Future<DateTime?> selectDate(BuildContext context, {DateTime? initialDate}) async {
  ///    Select date using date picker dialog
  DateTime selectedDate = initialDate ?? DateTime.now();
  final DateTime? pickedDate = await showDatePicker(
      firstDate: DateTime.now().subtract(const Duration(days: 36500)),
      lastDate: DateTime.now(),
      context: context,
      initialDate: selectedDate,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      });
  return pickedDate;
}