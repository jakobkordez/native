// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:test/test.dart';

import 'cpp_overload_test_bindings.dart';

void main() {
  group('C++ overloads', () {
    test('overloaded constructors', () {
      final byDefault = lab$Experiment();
      final withId = lab$Experiment.new$1(7);
      final withWeight = lab$Experiment.new$2(8, 2.5);

      expect(byDefault.getId(), 0);
      expect(withId.getId(), 7);
      expect(withId.getWeight(), 1.0);
      expect(withWeight.getId(), 8);
      expect(withWeight.getWeight(), 2.5);

      byDefault.dispose();
      withId.dispose();
      withWeight.dispose();
    });

    test('const and non-const pairs', () {
      final experiment = lab$Experiment.new$1(1);

      // Both overloads return the same object.
      experiment.properties().setLimit(42);
      expect(experiment.propertiesConst().getLimit(), 42);

      expect(experiment.results().value, 1);
      expect(experiment.resultsConst().value, 3);

      expect(experiment.streams(), 'streams');
      // Renamed by a visitor.
      expect(experiment.constStreams(), 'const streams');

      experiment.dispose();
    });

    test('overloads with different parameters', () {
      final experiment = lab$Experiment();

      expect(experiment.add(1, 2), 3);
      expect(experiment.add$1(1.0, 2.0), 3.5);
      expect(experiment.add$2(1, 2, 3), 6);
      expect(experiment.add$3('foo', 'bar'), 'foobar');
      expect(experiment.describe(), 1);
      expect(experiment.describe$1(5), 105);

      experiment.dispose();
    });

    test('static overloads', () {
      expect(lab$Experiment.scale(3), 6);
      expect(lab$Experiment.scale$1(3.0), 1.5);
    });

    test('operators', () {
      final experiment = lab$Experiment.new$1(3);

      expect(experiment.operatorSubscript(1), 2);
      expect(experiment.operatorCall(4), 12);
      expect(experiment.operatorCall$1(4, 1), 13);
      expect(experiment.operatorLogicalNot(), isFalse);
      expect(experiment.operatorEqual(3), isTrue);
      expect(experiment.operatorEqual(4), isFalse);

      final sum = experiment.operatorPlus(2);
      final difference = experiment.operatorMinus(2);
      final negated = experiment.operatorNegate();
      expect(sum.getId(), 5);
      expect(difference.getId(), 1);
      expect(negated.getId(), -3);

      final old = experiment.operatorPostIncrement(0);
      expect(old.getId(), 3);
      expect(experiment.getId(), 4);

      sum.dispose();
      difference.dispose();
      negated.dispose();
      old.dispose();
      experiment.dispose();
    });

    test('overloads hidden by a subclass', () {
      final variant = lab$Variant(2);
      final lab$Experiment asBase = variant;

      // Variant::add(double, double) overrides the matching overload.
      expect(variant.add$1(2.0, 3.0), 6.0);
      expect(asBase.add$1(2.0, 3.0), 6.0);

      // Variant::add hides the other overloads in C++, but they're still
      // callable from Dart.
      expect(variant.add(2, 3), 5);
      expect(variant.add$2(1, 2, 3), 6);
      expect(variant.add$3('a', 'b'), 'ab');

      expect(variant.describe(), 1);
      expect(variant.describe$1(5), 205);
      expect(asBase.describe$1(5), 205);

      expect(variant.propertiesConst().getLimit(), 10);
      // The visitor renamed Experiment's method, which renamed Variant's too.
      expect(variant.constStreams(), 'const streams');

      variant.dispose();
    });

    test('overloads inherited past the class that hides them', () {
      final refinement = lab$Refinement(2);
      final lab$Variant asBase = refinement;

      expect(refinement.add(2, 3), 5);
      expect(refinement.add$1(2.0, 3.0), 6.0);
      expect(refinement.add$2(1, 2, 3), 6);
      expect(asBase.add(2, 3), 5);
      expect(refinement.describe(), 1);
      expect(refinement.describe$1(5), 205);

      refinement.dispose();
    });
  });
}
