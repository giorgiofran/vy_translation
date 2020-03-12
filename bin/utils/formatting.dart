/*String formatTimeRef(DateTime time) {
  String timeString = time.toIso8601String().replaceAll('T', ' ');
  int dotIndex = timeString.indexOf('.');
  return timeString.substring(0, dotIndex);
}*/

String formatTimeRef(DateTime time) =>
    time.toIso8601String().replaceFirst('T', ' ').split('.').first;
