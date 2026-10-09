import 'package:intl/intl.dart';

class CurrencyInfo {
  const CurrencyInfo({
    required this.code,
    required this.symbol,
    this.decimalDigits = 2,
  });

  final String code;
  final String symbol;
  final int decimalDigits;
}

class CurrencyService {
  static const Map<String, CurrencyInfo> _countryToCurrency = {
    'NG': CurrencyInfo(code: 'NGN', symbol: '₦', decimalDigits: 0),
    'US': CurrencyInfo(code: 'USD', symbol: '\$'),
    'GB': CurrencyInfo(code: 'GBP', symbol: '£'),
    'CA': CurrencyInfo(code: 'CAD', symbol: 'CA\$'),
    'AU': CurrencyInfo(code: 'AUD', symbol: 'A\$'),
    'DE': CurrencyInfo(code: 'EUR', symbol: '€'),
    'FR': CurrencyInfo(code: 'EUR', symbol: '€'),
    'ES': CurrencyInfo(code: 'EUR', symbol: '€'),
    'IT': CurrencyInfo(code: 'EUR', symbol: '€'),
    'NL': CurrencyInfo(code: 'EUR', symbol: '€'),
    'IE': CurrencyInfo(code: 'EUR', symbol: '€'),
    'AE': CurrencyInfo(code: 'AED', symbol: 'AED '),
    'SA': CurrencyInfo(code: 'SAR', symbol: 'SAR '),
    'ZA': CurrencyInfo(code: 'ZAR', symbol: 'R'),
    'GH': CurrencyInfo(code: 'GHS', symbol: 'GH₵'),
    'KE': CurrencyInfo(code: 'KES', symbol: 'KSh ', decimalDigits: 0),
  };

  static const CurrencyInfo defaultCurrency = CurrencyInfo(
    code: 'USD',
    symbol: '\$',
  );

  /// Resolves currency info for a given 2-letter country code (e.g. 'NG', 'US')
  static CurrencyInfo getCurrency(String? countryCode) {
    if (countryCode == null) return defaultCurrency;
    final upper = countryCode.toUpperCase();
    return _countryToCurrency[upper] ?? defaultCurrency;
  }

  /// Formats an amount with the appropriate currency symbol and number grouping.
  /// E.g. in Nigeria: ₦15,000; in US: $25.00
  static String format(num? amount, {String? countryCode, String? currencyCode, int? decimalDigits}) {
    if (amount == null) return '\$0.00';

    CurrencyInfo info = defaultCurrency;
    if (countryCode != null) {
      info = getCurrency(countryCode);
    } else if (currencyCode != null) {
      final match = _countryToCurrency.values.firstWhere(
        (c) => c.code.toUpperCase() == currencyCode.toUpperCase(),
        orElse: () => defaultCurrency,
      );
      info = match;
    }

    final formatter = NumberFormat.currency(
      symbol: info.symbol,
      decimalDigits: decimalDigits ?? info.decimalDigits,
    );

    return formatter.format(amount);
  }

  /// Returns the symbol for a given country code (e.g. '₦' for 'NG')
  static String getSymbol(String? countryCode) {
    return getCurrency(countryCode).symbol;
  }

  /// Returns the currency code for a given country code (e.g. 'NGN' for 'NG')
  static String getCode(String? countryCode) {
    return getCurrency(countryCode).code;
  }
}
