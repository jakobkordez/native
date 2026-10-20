// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

import 'cpp_value_reference_test_bindings.dart';

void main() {
  group('C++ references to values', () {
    late ffi.Pointer<geo$Extent> extent;
    late Box box;

    setUp(() {
      extent = calloc<geo$Extent>();
      extent.ref
        ..width = 2
        ..height = 3;
      box = Box(extent.ref);
    });

    tearDown(() {
      box.dispose();
      calloc.free(extent);
    });

    test('a struct passed by const reference is copied', () {
      // The box keeps its own copy.
      extent.ref.width = 7;
      expect(box.extent().width, 2);
    });

    test('a struct returned by const reference is a copy', () {
      final copy = box.extent();
      expect(copy.width, 2);
      expect(copy.height, 3);
      box.grow(1);
      expect(copy.width, 2);
      expect(box.extent().width, 3);
    });

    test('a struct returned by mutable reference is a pointer into C++', () {
      final ref = box.mutableExtent();
      expect(ref, isA<ffi.Pointer<geo$Extent>>());
      ref.ref.height = 10;
      expect(box.extent().height, 10);
    });

    test('a number passed by const reference is passed by value', () {
      box.grow(5);
      expect(box.extent().width, 7);
      expect(box.extent().height, 8);
    });

    test('a struct passed by mutable reference is written through', () {
      final out = calloc<geo$Extent>();
      box.readInto(out);
      expect(out.ref.width, 2);
      expect(out.ref.height, 3);
      calloc.free(out);
    });

    test('a number passed and returned by mutable reference', () {
      final area = calloc<ffi.Long>();
      final returned = box.areaInto(area);
      expect(area.value, 6);
      expect(returned, area);
      calloc.free(area);
    });

    test('an enum passed and returned by const reference', () {
      expect(box.unit(), geo$Unit.millimeter);
      box.setUnit(geo$Unit.centimeter);
      expect(box.unit(), geo$Unit.centimeter);
    });

    test('an enum returned by mutable reference', () {
      final unit = box.unitRef();
      unit.value = geo$Unit.centimeter.value;
      expect(box.unit(), geo$Unit.centimeter);
    });
  });
}
