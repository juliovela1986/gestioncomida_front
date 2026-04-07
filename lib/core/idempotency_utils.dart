import 'dart:math';

final Random _secureRandom = Random.secure();

String generateClientRequestId() {
  final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  String hex(int value) => value.toRadixString(16).padLeft(2, '0');
  final hexBytes = bytes.map(hex).toList();

  return '${hexBytes.sublist(0, 4).join()}-'
      '${hexBytes.sublist(4, 6).join()}-'
      '${hexBytes.sublist(6, 8).join()}-'
      '${hexBytes.sublist(8, 10).join()}-'
      '${hexBytes.sublist(10, 16).join()}';
}

