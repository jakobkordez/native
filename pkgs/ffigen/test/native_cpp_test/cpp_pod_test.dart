// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

import 'cpp_pod_test_bindings.dart';

void main() {
  group('CppPod', () {
    test('a POD record is bound as a plain struct regardless of keyword', () {
      // PodPoint is declared with the `class` keyword and PodPair with
      // `struct`; both are plain old data, so both are bound as plain C
      // structs.
      expect(<PodPoint>[], isA<List<ffi.Struct>>());
      expect(<PodPair>[], isA<List<ffi.Struct>>());
    });

    test('POD struct fields are modelled', () {
      final p = calloc<PodPoint>();
      p.ref.x = 3;
      p.ref.y = 4;
      expect(p.ref.x, 3);
      expect(p.ref.y, 4);
      calloc.free(p);
    });

    test('a non-POD record gets the C++ class treatment', () {
      // NonPodCounter is declared with the `struct` keyword, but its
      // user-declared constructor makes it non-POD, so it is bound as a C++
      // class wrapper rather than an ffi.Struct.
      expect(<NonPodCounter>[], isA<List<ffi.Finalizable>>());
      expect(<NonPodCounter>[], isNot(isA<List<ffi.NativeType>>()));
    });

    test('non-POD class wrapper full lifecycle', () {
      final counter = NonPodCounter(5);
      expect(counter.next(), 5);
      expect(counter.next(), 6);
      counter.dispose();
    });

    test('a plain aggregate is bound as a plain struct', () {
      // Its default member initializers make it non-POD, but it's still an
      // aggregate with the layout of a C struct.
      expect(<AggregateRange>[], isA<List<ffi.Struct>>());
      expect(<AggregateSpan>[], isA<List<ffi.Struct>>());
    });

    test('a C function takes and returns a plain aggregate by value', () {
      final range = calloc<AggregateRange>();
      range.ref
        ..lo = 2
        ..hi = 5;
      final widened = widenRange(range.ref, 3);
      expect(widened.lo, -1);
      expect(widened.hi, 8);
      calloc.free(range);
    });

    test('plain aggregate fields are modelled', () {
      final span = calloc<AggregateSpan>();
      span.ref.range.hi = 4;
      span.ref.pairs[1].b = 7;
      span.ref.weight = 0.5;
      expect(span.ref.range.lo, 0);
      expect(span.ref.range.hi, 4);
      expect(span.ref.pairs[1].b, 7);
      expect(span.ref.weight, 0.5);
      calloc.free(span);
    });

    test('a record holding a std::string gets the C++ class treatment', () {
      expect(<NamedRange>[], isA<List<ffi.Finalizable>>());
    });

    test('a record with a constructor gets the C++ class treatment', () {
      // Unlike the struct, the class is constructed, with its default member
      // initializers.
      final range = NonAggregateRange();
      expect(range.lo, -1);
      expect(range.hi, -1);
      range.dispose();
    });
  });
}
