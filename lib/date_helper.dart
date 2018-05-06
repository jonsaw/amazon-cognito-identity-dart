
final List<String> monthNames =
  ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
final List<String> weekNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class DateHelper {
  /**
   * The current time in "ddd MMM D HH:mm:ss UTC YYYY" format.
   */
  String getNowString() {
    DateTime now = new DateTime.now().toUtc();

    final String weekDay = weekNames[now.weekday];
    final String month = monthNames[now.month];
    final String day = now.day.toString();
    String hours = now.hour.toString();
    if (now.hour < 10) {
      hours = '0${now.hour.toString()}';
    }
    String minutes = now.minute.toString();
    if (now.minute < 10) {
      minutes = '0${now.minute.toString()}';
    }
    String seconds = now.second.toString();
    if (now.second < 10) {
      seconds = '0${now.second.toString()}';
    }
    String year = now.year.toString();

    return '${weekDay} ${month} ${day} ${hours}:${minutes}:${seconds} UTC ${year}';
  }
}
