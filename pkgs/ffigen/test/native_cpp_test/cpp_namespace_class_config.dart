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
      dart: DartOutput(
        path: testDir.resolve('cpp_namespace_class_test_bindings.dart'),
      ),
      style: const NativeExternalBindings(assetId: 'package:ffigen/cpp_test'),
    ),
    input: Input(entryPoints: [testDir.resolve('cpp_namespace_class_test.h')]),
    cpp: const Cpp(),
    visitors: [
      Visitor(
        // Scoped classes are matched by their qualified C++ name.
        cppClass: (node) => node.isIncluded = {
          'Creature',
          'zoo::Creature',
          'zoo::Dog',
          'zoo::Keeper',
          'zoo::Keeper::Badge',
          'zoo::Keeper::Secret',
          'zoo::aquarium::Creature',
          'farm::Creature',
        }.contains(node.originalName),
        struct: (node) =>
            node.isIncluded = node.originalName == 'zoo::Position',
      ),
    ],
  );
}
