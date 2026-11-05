import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('corrupt JSON fallback returns null', () {
    const corrupt = '{not valid json';
    Map<String, dynamic>? result;
    try {
      result = jsonDecode(corrupt) as Map<String, dynamic>;
    } catch (_) {
      result = null;
    }
    expect(result, isNull);
  });
}
