import 'package:intl/intl.dart';
import '../../core/constants/app_config.dart';

class PriceFormatter {
  static final _formatter = NumberFormat.currency(
    locale: AppConfig.currencyLocale,
    symbol: 'FCFA ',
    decimalDigits: 0,
  );

  static String format(double amount) {
    return _formatter.format(amount);
  }

  static String formatString(String amount) {
    final value = double.tryParse(amount) ?? 0;
    return format(value);
  }
}
