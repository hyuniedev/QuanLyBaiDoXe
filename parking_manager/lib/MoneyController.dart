import 'package:intl/intl.dart';

class MoneyController {
  static String formatCurrency(String numberString) {
    try {
      final number = double.parse(numberString);
      final formatter = NumberFormat('#,###', 'vi_VN');
      return formatter.format(number);
    } catch (e) {
      print("Lỗi khi định dạng số: $e");
      return numberString;
    }
  }
}
