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
        path: testDir.resolve('cpp_constexpr_test_bindings.dart'),
      ),
    ),
    input: Input(
      entryPoints: [testDir.resolve('cpp_constexpr_test.h')],
      compilerOptions: [
        '-x',
        'c++',
        '-std=c++17',
        if (Platform.isMacOS) ...['-isysroot', macSdkPath],
      ],
    ),
    visitors: [
      Visitor(
        // `constexpr` / `static constexpr` variables are parsed as const
        // Globals.
        global: (node) => node.isIncluded = {
          'topInt',
          'topDouble',
          'topStr',
          'topDerived',
          'ns::nsInt',
          'ns::inner::nsInt',
          'Box::memberInt',
          'Box::memberDouble',
          'Widget::classInt',
          'scoped::Gadget::gadgetInt',
        }.contains(node.originalName),
      ),
    ],
  );
}
