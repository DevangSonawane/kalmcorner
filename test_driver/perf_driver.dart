import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// Writes the perf + haptics report from integration_test/perf_test.dart.
Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    final dir = Directory('build/perf')..createSync(recursive: true);
    File('${dir.path}/perf_report.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
  },
);
