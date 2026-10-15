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
        path: testDir.resolve('cpp_overload_test_bindings.dart'),
      ),
      style: const NativeExternalBindings(assetId: 'package:ffigen/cpp_test'),
    ),
    input: Input(entryPoints: [testDir.resolve('cpp_overload_test.h')]),
    cpp: const Cpp(),
    visitors: [
      Visitor(
        cppClass: (node) => node.isIncluded = {
          'lab::Properties',
          'lab::Experiment',
          'lab::Variant',
          'lab::Refinement',
        }.contains(node.originalName),
        cppMethod: (node) {
          // Renaming a base class method also renames it in the subclasses.
          if (node.parent.originalName == 'lab::Experiment' &&
              node.name == 'streamsConst') {
            node.name = 'constStreams';
          }
        },
      ),
    ],
  );
}
