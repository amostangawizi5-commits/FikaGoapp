String? normalizeTzPhone(String value) {
  var digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('255')) {
    digits = digits.substring(3);
  } else if (digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  if (!RegExp(r'^\d{9}$').hasMatch(digits)) return null;
  return '+255$digits';
}

String nationalTzPhoneDigits(String value) {
  final normalized = normalizeTzPhone(value);
  return normalized == null ? value : normalized.substring(4);
}
