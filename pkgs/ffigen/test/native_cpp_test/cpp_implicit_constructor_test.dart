// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'cpp_implicit_constructor_test_bindings.dart';

// The classes that can't be default constructed get no constructor, which
// the expected bindings pin.
void main() {
  group('C++ implicit default constructors', () {
    test('a class that declares no constructor can be constructed', () {
      final settings = Settings();
      expect(settings.name, '');
      // The default member initializers run.
      expect(settings.retries, 3);
      expect(settings.ports, isEmpty);

      settings
        ..name = 'probe'
        ..ports = [80, 443];
      expect(settings.name, 'probe');
      expect(settings.ports, [80, 443]);
      settings.dispose();
    });

    test('the implicit constructor constructs the bases and fields', () {
      final labelled = LabelledSettings();
      expect(labelled.label, 'unnamed');
      expect(labelled.settings.retries, 3);
      labelled.dispose();
    });
  });
}
