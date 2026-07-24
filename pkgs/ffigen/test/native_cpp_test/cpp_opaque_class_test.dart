// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi' as ffi;

import 'package:test/test.dart';

import 'cpp_opaque_class_test_bindings.dart';

void main() {
  group('CppOpaqueClass', () {
    test('forward-declared class is emitted as an opaque type', () {
      // Subtype check: MyHandle extends ffi.Opaque.
      expect(<MyHandle>[], isA<List<ffi.Opaque>>());
      expect(<OtherHandle>[], isA<List<ffi.Opaque>>());
    });

    test('functions using pointers to a forward-declared class exist', () {
      // Signature checks on the tear-offs. The functions are never invoked,
      // so no native library is needed.
      expect(my_handle_create, isA<ffi.Pointer<MyHandle> Function()>());
      expect(my_handle_destroy, isA<void Function(ffi.Pointer<MyHandle>)>());
      expect(
        my_handle_clone,
        isA<ffi.Pointer<MyHandle> Function(ffi.Pointer<MyHandle>)>(),
      );
      expect(other_handle_create, isA<ffi.Pointer<OtherHandle> Function()>());
    });
  });
}
