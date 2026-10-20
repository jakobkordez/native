// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'cpp_enum_as_int_test_bindings.dart';

void main() {
  group('CppEnumAsInt', () {
    test('the enum is a Dart enum', () {
      expect(eai$Level.values, [eai$Level.kLow, eai$Level.kHigh]);
      expect(eai$Level.fromValue(2), eai$Level.kHigh);
    });

    test('its values cross as ints', () {
      final gauge = eai$Gauge(2);
      expect(gauge.level(), isA<int>());
      expect(eai$Level.fromValue(gauge.level()), eai$Level.kHigh);
      gauge.setLevel(eai$Level.kLow.value);
      expect(gauge.level(), eai$Level.kLow.value);
      gauge.dispose();
    });

    test('a value the enum does not have reaches Dart', () {
      final gauge = eai$Gauge(7);
      expect(gauge.level(), 7);
      gauge.dispose();
    });
  });
}
