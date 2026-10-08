/// How a quantity was typed, so it can be shown back the same way (FR-002).
enum QuantityForm { whole, fraction, mixed, decimal }

/// An exact, positive ingredient amount (research R9).
///
/// Stored as a reduced rational so that splitting "1/3 cup" into parts adds up
/// exactly; floating point cannot represent 1/3. The [form] records how the cook
/// typed it, and [format] returns it in that form.
///
/// `==` compares amount and form, so a document round-trips unchanged. Use
/// [isSameAmountAs] to compare amounts alone, for example in the split rule.
final class Quantity {
  /// Always greater than zero.
  final int numerator;

  /// Always greater than zero, and coprime with [numerator].
  final int denominator;

  final QuantityForm form;

  Quantity._(int numerator, int denominator, this.form)
      : numerator = numerator ~/ _gcd(numerator, denominator),
        denominator = denominator ~/ _gcd(numerator, denominator);

  /// Builds a quantity from parts, as read from storage or a document.
  ///
  /// Throws [ArgumentError] unless both parts are positive.
  factory Quantity(int numerator, int denominator, QuantityForm form) {
    if (numerator <= 0 || denominator <= 0) {
      throw ArgumentError('A quantity must be positive: $numerator/$denominator');
    }
    return Quantity._(numerator, denominator, form);
  }

  static final _whole = RegExp(r'^(\d+)$');
  static final _decimal = RegExp(r'^(\d*)\.(\d+)$');
  static final _fraction = RegExp(r'^(\d+)/(\d+)$');
  static final _mixed = RegExp(r'^(\d+) (\d+)/(\d+)$');

  /// Parses `2`, `0.5`, `.25`, `1/3`, or `1 1/2`.
  ///
  /// Throws [FormatException] for anything else, including zero, negative
  /// amounts, a zero denominator, and a mixed number whose fraction part is not
  /// a proper fraction (`1 3/2`).
  factory Quantity.parse(String text) {
    final s = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    Quantity? result;

    final whole = _whole.firstMatch(s);
    final decimal = _decimal.firstMatch(s);
    final fraction = _fraction.firstMatch(s);
    final mixed = _mixed.firstMatch(s);

    if (whole != null) {
      result = _positive(int.parse(whole[1]!), 1, QuantityForm.whole);
    } else if (decimal != null) {
      final intPart = decimal[1]!.isEmpty ? 0 : int.parse(decimal[1]!);
      final digits = decimal[2]!;
      final scale = _pow10(digits.length);
      result = _positive(intPart * scale + int.parse(digits), scale, QuantityForm.decimal);
    } else if (fraction != null) {
      result = _positive(int.parse(fraction[1]!), int.parse(fraction[2]!), QuantityForm.fraction);
    } else if (mixed != null) {
      final w = int.parse(mixed[1]!);
      final n = int.parse(mixed[2]!);
      final d = int.parse(mixed[3]!);
      if (w > 0 && n > 0 && d > 0 && n < d) {
        result = Quantity._(w * d + n, d, QuantityForm.mixed);
      }
    }

    if (result == null) {
      throw FormatException('Not a quantity: "$text"');
    }
    return result;
  }

  /// Like [Quantity.parse], but returns null instead of throwing.
  static Quantity? tryParse(String text) {
    try {
      return Quantity.parse(text);
    } on FormatException {
      return null;
    }
  }

  static Quantity? _positive(int n, int d, QuantityForm form) =>
      n > 0 && d > 0 ? Quantity._(n, d, form) : null;

  /// The exact sum. Its form is whole when the result is a whole number and
  /// fraction otherwise; sums are for checking amounts, not for display.
  Quantity operator +(Quantity other) {
    final n = numerator * other.denominator + other.numerator * denominator;
    final d = denominator * other.denominator;
    final reducedD = d ~/ _gcd(n, d);
    return Quantity._(n, d, reducedD == 1 ? QuantityForm.whole : QuantityForm.fraction);
  }

  /// True when both are the same amount, whatever form each was typed in.
  bool isSameAmountAs(Quantity other) =>
      numerator == other.numerator && denominator == other.denominator;

  /// The quantity in the form it was entered.
  String format() {
    switch (form) {
      case QuantityForm.whole:
      case QuantityForm.fraction:
        return denominator == 1 ? '$numerator' : '$numerator/$denominator';
      case QuantityForm.mixed:
        final w = numerator ~/ denominator;
        final r = numerator % denominator;
        if (r == 0) return '$w';
        return w == 0 ? '$r/$denominator' : '$w $r/$denominator';
      case QuantityForm.decimal:
        return _formatDecimal();
    }
  }

  String _formatDecimal() {
    // A quantity parsed as a decimal has a denominator whose only prime
    // factors are 2 and 5, so it has a finite decimal expansion.
    var places = 0;
    var scale = 1;
    while ((numerator * scale) % denominator != 0) {
      places++;
      scale *= 10;
      if (places > 18) {
        // Not a terminating decimal; show it as a fraction rather than round.
        return '$numerator/$denominator';
      }
    }
    final scaled = numerator * scale ~/ denominator;
    if (places == 0) return '$scaled';
    final digits = scaled.toString().padLeft(places + 1, '0');
    final cut = digits.length - places;
    return '${digits.substring(0, cut)}.${digits.substring(cut)}';
  }

  @override
  bool operator ==(Object other) =>
      other is Quantity &&
      other.numerator == numerator &&
      other.denominator == denominator &&
      other.form == form;

  @override
  int get hashCode => Object.hash(numerator, denominator, form);

  @override
  String toString() => 'Quantity(${format()}, $form)';

  static int _gcd(int a, int b) {
    a = a.abs();
    b = b.abs();
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a == 0 ? 1 : a;
  }

  static int _pow10(int n) {
    var r = 1;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }
}
