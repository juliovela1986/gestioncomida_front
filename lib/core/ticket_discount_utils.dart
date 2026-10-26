/// Utilidades para detectar y calcular descuentos en tickets (multi-supermercado).
library;

double parseTicketAmount(String? raw) {
  if (raw == null || raw.isEmpty) return 0.0;

  var normalized = raw.trim();
  final hasComma = normalized.contains(',');
  final hasDot = normalized.contains('.');

  if (hasComma && hasDot) {
    normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
  } else if (hasComma) {
    normalized = normalized.replaceAll(',', '.');
  }

  return double.tryParse(normalized) ?? 0.0;
}

bool hasDiscountMarkers(String? rawText) {
  if (rawText == null || rawText.isEmpty) return false;

  final markersRegex = RegExp(
    r'(Desc\s*\.\s*total\s*en\s*compra|LIDL\s*PLUS|DTO\.\s*VALE|DESCUENTO\s+EN|TOTAL\s+A\s+PAGAR)',
    caseSensitive: false,
  );

  return markersRegex.hasMatch(rawText);
}

double extractLidlGlobalDiscount(String? rawText) {
  if (rawText == null || rawText.isEmpty) return 0.0;

  final discountRegex = RegExp(
    r'Desc\s*\.?\s*total\s*en\s*compra\s*\|?\s*-?\s*([0-9]+(?:[.,][0-9]{1,2})?)',
    caseSensitive: false,
  );

  final match = discountRegex.firstMatch(rawText);
  if (match == null) return 0.0;
  return parseTicketAmount(match.group(1));
}

double extractCarrefourPaidTotal(String? rawText) {
  if (rawText == null || rawText.isEmpty) return 0.0;

  final totalRegex = RegExp(
    r'(?:\d+\s+ART\.\s+)?TOTAL\s+A\s+PAGAR\s+([0-9]+[.,][0-9]{2})',
    caseSensitive: false,
  );

  for (final line in rawText.split(RegExp(r'\r?\n'))) {
    final match = totalRegex.firstMatch(line.trim());
    if (match != null) {
      return parseTicketAmount(match.group(1));
    }
  }
  return 0.0;
}

double? _extractVoucherAmountFromLine(String line) {
  final negativeAtEnd = RegExp(r'-\s*([0-9]+[.,][0-9]{2})\s*$');
  final negativeMatch = negativeAtEnd.firstMatch(line);
  if (negativeMatch != null) {
    return parseTicketAmount(negativeMatch.group(1));
  }

  final amountRegex = RegExp(r'([0-9]+[.,][0-9]{2})');
  double? last;
  for (final match in amountRegex.allMatches(line)) {
    last = parseTicketAmount(match.group(1));
  }
  return last;
}

double? _extractStandaloneNegativeAmount(String line) {
  final match = RegExp(r'^\s*-\s*([0-9]+[.,][0-9]{2})\s*$').firstMatch(line.trim());
  if (match == null) return null;
  return parseTicketAmount(match.group(1));
}

double extractCarrefourGlobalVoucherDiscount(String? rawText) {
  if (rawText == null || rawText.isEmpty) return 0.0;

  final lines = rawText.split(RegExp(r'\r?\n'));
  var afterSubtotal = false;
  var total = 0.0;

  final dtoValeRegex = RegExp(r'^DTO\.\s*VALE\b', caseSensitive: false);

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;

    if (!afterSubtotal && line.toUpperCase().contains('SUBTOTAL')) {
      afterSubtotal = true;
      continue;
    }
    if (!afterSubtotal) continue;
    if (line.toUpperCase().contains('TOTAL A PAGAR')) break;
    if (!dtoValeRegex.hasMatch(line)) continue;

    var amount = _extractVoucherAmountFromLine(line);
    if ((amount == null || amount <= 0) && i + 1 < lines.length) {
      amount = _extractStandaloneNegativeAmount(lines[i + 1]);
    }
    if (amount != null && amount > 0) {
      total += amount;
    }
  }

  return total;
}

double resolveCarrefourNetPaidTotal({
  required String? rawText,
  required double linesSubtotal,
}) {
  final explicitPaid = extractCarrefourPaidTotal(rawText);
  if (explicitPaid > 0) return explicitPaid;

  final vouchers = extractCarrefourGlobalVoucherDiscount(rawText);
  if (vouchers > 0 && linesSubtotal > vouchers) {
    return linesSubtotal - vouchers;
  }
  return 0.0;
}

double extractTotalFromRawText(String? rawText) {
  if (rawText == null || rawText.isEmpty) return 0.0;

  final carrefourPaid = extractCarrefourPaidTotal(rawText);
  if (carrefourPaid > 0) return carrefourPaid;

  final totalRegex = RegExp(
    r'^\s*TOTAL\s*\|\s*([0-9]+(?:[.,][0-9]{1,2})?)\s*$',
    caseSensitive: false,
    multiLine: true,
  );

  final match = totalRegex.firstMatch(rawText);
  if (match == null) return 0.0;
  return parseTicketAmount(match.group(1));
}

bool isCarrefourTicket({String? supermarketName, String? rawText}) {
  if (supermarketName != null &&
      supermarketName.toUpperCase().contains('CARREFOUR')) {
    return true;
  }
  return rawText != null && rawText.toUpperCase().contains('CARREFOUR');
}

double calculateGlobalDiscount({
  required String? rawText,
  required double subtotal,
  String? backendTicketTotal,
  String? supermarketName,
}) {
  if (rawText == null || rawText.isEmpty || subtotal <= 0) return 0.0;
  if (!hasDiscountMarkers(rawText)) return 0.0;

  final lidlDiscount = extractLidlGlobalDiscount(rawText);
  if (lidlDiscount > 0) return lidlDiscount.clamp(0.0, subtotal);

  if (isCarrefourTicket(supermarketName: supermarketName, rawText: rawText)) {
    final vouchers = extractCarrefourGlobalVoucherDiscount(rawText);
    if (vouchers > 0) return vouchers.clamp(0.0, subtotal);

    final netPaid = resolveCarrefourNetPaidTotal(
      rawText: rawText,
      linesSubtotal: subtotal,
    );
    if (netPaid > 0 && subtotal > netPaid) {
      return (subtotal - netPaid).clamp(0.0, subtotal);
    }
  }

  final backendTotal = parseTicketAmount(backendTicketTotal);
  if (backendTotal > 0 && subtotal > backendTotal) {
    return (subtotal - backendTotal).clamp(0.0, subtotal);
  }

  final rawTotal = extractTotalFromRawText(rawText);
  if (rawTotal > 0 && subtotal > rawTotal) {
    return (subtotal - rawTotal).clamp(0.0, subtotal);
  }

  return 0.0;
}

bool totalsAreConsistent(double a, double b, {double tolerance = 0.05}) {
  return (a - b).abs() <= tolerance;
}

double calculateTicketDisplayTotal({
  required double subtotal,
  required String? rawText,
  String? backendTicketTotal,
  String? supermarketName,
}) {
  if (subtotal <= 0) return 0.0;

  if (isCarrefourTicket(supermarketName: supermarketName, rawText: rawText)) {
    final netPaid = resolveCarrefourNetPaidTotal(
      rawText: rawText,
      linesSubtotal: subtotal,
    );
    if (netPaid > 0) return netPaid;
  }

  final backendTotal = parseTicketAmount(backendTicketTotal);
  if (backendTotal > 0) return backendTotal;

  final discount = calculateGlobalDiscount(
    rawText: rawText,
    subtotal: subtotal,
    backendTicketTotal: backendTicketTotal,
    supermarketName: supermarketName,
  );
  if (discount > 0) {
    return (subtotal - discount).clamp(0.0, double.infinity);
  }

  final rawTotal = extractTotalFromRawText(rawText);
  if (rawTotal > 0 && totalsAreConsistent(rawTotal, subtotal)) {
    return rawTotal;
  }

  return subtotal;
}
