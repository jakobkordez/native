// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:ffigen/ffigen.dart';

FfiGenerator getConfig([Uri? packageRoot]) {
  packageRoot ??= Uri.directory(Directory.current.path);
  final testDir = packageRoot.resolve('test/native_cpp_test/');
  return FfiGenerator(
    output: Output(
      dart: DartOutput(path: testDir.resolve('cpp_field_test_bindings.dart')),
      style: const NativeExternalBindings(assetId: 'package:ffigen/cpp_test'),
    ),
    input: Input(entryPoints: [testDir.resolve('cpp_field_test.h')]),
    cpp: const Cpp(),
    visitors: [
      Visitor(
        enumClass: (node) => node.silenceWarning = true,
        cppClass: (node) =>
            node.isIncluded = node.originalName.startsWith('fld::'),
        cppField: (node) {
          if (node.parent.originalName != 'fld::Settings') return;
          switch (node.originalName) {
            case 'renamed':
              node.name = 'wasRenamed';
            case 'excluded':
              node.isIncluded = false;
          }
        },
      ),
    ],
  );
}
