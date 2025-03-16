import 'package:intl/intl.dart';

class TimeController {
  static DateTime? convertToDateTime(String dateString) {
    try {
      return DateTime.parse(dateString).toLocal();
    } catch (e) {
      print("Lỗi khi chuyển đổi ngày giờ: $e");
      return null;
    }
  }

  static String? convertToFormattedString(String dateString) {
    try {
      DateTime dateTime = DateTime.parse(dateString).toLocal();
      DateFormat outputFormat = DateFormat("HH:mm:ss dd/MM/yyyy");
      return outputFormat.format(dateTime);
    } catch (e) {
      print("Lỗi khi định dạng ngày giờ: $e");
      return null;
    }
  }
}
