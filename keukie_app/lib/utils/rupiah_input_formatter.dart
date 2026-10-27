import 'package:flutter/services.dart';

class RupiahInputFormatter extends TextInputFormatter {
  static const int maxDigits = 13;

  static String format(String digits) {
    return digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match[1]}.',
    );
  }

  static String fromNumber(num value) => format(value.truncate().toString());

  static int? parse(String text) => int.tryParse(text.replaceAll('.', ''));

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawText = newValue.text;
    var digits = rawText.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    if (digits.length > maxDigits) return oldValue;

    final formatted = format(digits);

    final cursor = newValue.selection.end < 0
        ? rawText.length
        : newValue.selection.end.clamp(0, rawText.length).toInt();

    var remaining = RegExp(r'\d').allMatches(rawText.substring(cursor)).length;

    var offset = formatted.length;

    while (remaining > 0 && offset > 0) {
      offset--;
      if (formatted[offset] != '.') remaining--;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}