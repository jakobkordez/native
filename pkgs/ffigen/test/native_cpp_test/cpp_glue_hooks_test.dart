// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'cpp_glue_hooks_test_bindings.dart';

Matcher throwsCppException(String message) =>
    throwsA(isA<CppException>().having((e) => e.message, 'message', message));

void main() {
  group('catchExceptions', () {
    late hooks$Thrower thrower;

    setUp(() => thrower = hooks$Thrower(10));
    tearDown(() => thrower.dispose());

    test('a call that does not throw returns normally', () {
      expect(thrower.divide(2), 5);
      expect(thrower.describe(false), 'Thrower(10)');
      expect(hooks$Thrower.answer(false), 42);
    });

    test('a std::exception from a method is rethrown in Dart', () {
      expect(() => thrower.divide(0), throwsCppException('division by zero'));
    });

    test('a std::exception from a constructor is rethrown in Dart', () {
      expect(() => hooks$Thrower(-1), throwsCppException('negative value'));
    });

    test('a std::string return is not converted when it throws', () {
      expect(
        () => thrower.describe(true),
        throwsCppException('cannot describe'),
      );
    });

    test('a void method is checked after the call', () {
      expect(() => thrower.set(-1), throwsCppException('negative value'));
      expect(thrower.value(), 10);
      thrower.set(3);
      expect(thrower.value(), 3);
    });

    test('a void method through a typedef is checked after the call', () {
      expect(() => thrower.reset(-1), throwsCppException('negative value'));
      expect(thrower.value(), 10);
      thrower.reset(4);
      expect(thrower.value(), 4);
    });

    test('a pointer return is not wrapped when it throws', () {
      expect(() => thrower.self(true), throwsCppException('no self'));
      expect(thrower.self(false).value(), 10);
    });

    test('a static method is checked', () {
      expect(() => hooks$Thrower.answer(true), throwsCppException('no answer'));
    });

    test('an exception that is not a std::exception is described', () {
      expect(
        thrower.throwInt,
        throwsCppException("a C++ exception that isn't a std::exception"),
      );
    });

    test('an exception whose what() is null is described', () {
      expect(
        thrower.throwNullWhat,
        throwsCppException('a std::exception whose what() is null'),
      );
    });

    test('a caught exception does not leak into the next call', () {
      expect(() => thrower.divide(0), throwsA(isA<CppException>()));
      expect(thrower.divide(5), 2);
    });

    test('toString names the exception', () {
      expect(CppException('boom').toString(), 'CppException: boom');
    });
  });

  group('glueGuard', () {
    test('every glue call constructs one guard', () {
      final thrower = hooks$Thrower(1);
      // Each call counts its own guard.
      final before = hooks$Thrower.guardCount();
      thrower.value();
      expect(hooks$Thrower.guardCount(), before + 2);

      // So does the delete glue.
      final beforeDispose = hooks$Thrower.guardCount();
      thrower.dispose();
      expect(hooks$Thrower.guardCount(), beforeDispose + 2);
    });

    test('the guard is alive during the call', () {
      expect(hooks$Thrower.guardDepth(), 1);
    });

    test('the guard is released when the call throws', () {
      final thrower = hooks$Thrower(1);
      addTearDown(thrower.dispose);
      expect(() => thrower.divide(0), throwsA(isA<CppException>()));
      expect(() => hooks$Thrower(-1), throwsA(isA<CppException>()));
      expect(hooks$Thrower.guardDepth(), 1);
    });

    test("an exception from the guard's constructor is rethrown in Dart", () {
      final thrower = hooks$Thrower(1);
      addTearDown(thrower.dispose);
      hooks$Thrower.failNextGuard();
      expect(thrower.value, throwsCppException('guard failed'));
      expect(thrower.value(), 1);
      expect(hooks$Thrower.guardDepth(), 1);
    });
  });
}
