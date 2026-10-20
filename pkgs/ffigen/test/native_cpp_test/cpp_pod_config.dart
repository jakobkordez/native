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
      dart: DartOutput(path: testDir.resolve('cpp_pod_test_bindings.dart')),
      style: const NativeExternalBindings(assetId: 'package:ffigen/cpp_test'),
    ),
    input: Input(entryPoints: [testDir.resolve('cpp_pod_test.h')]),
    cpp: const Cpp(),
    visitors: [
      Visitor(
        // Struct vs C++ class is decided by POD-ness, not by the
        // `class`/`struct` keyword: the POD records (one of them declared
        // with `class`) and the plain aggregates must arrive as struct nodes,
        // and the other non-POD records as C++ class nodes.
        struct: (node) {
          const include = {
            'PodPoint',
            'PodPair',
            'AggregateRange',
            'AggregateSpan',
          };
          node.isIncluded = include.contains(node.originalName);
        },
        cppClass: (node) {
          const include = {'NonPodCounter', 'NonAggregateRange', 'NamedRange'};
          node.isIncluded = include.contains(node.originalName);
        },
        // Of these, only widenRange is bound: the others hold a C++ class by
        // value, so they're skipped, and the union loses its members.
        func: (node) {
          const include = {
            'widenRange',
            'counterNext',
            'makeCounter',
            'adoptCounter',
            'callWithCounter',
          };
          node.isIncluded = include.contains(node.originalName);
        },
        global: (node) =>
            node.isIncluded = node.originalName == 'sharedCounter',
        union: (node) => node.isIncluded = node.originalName == 'CounterOrInt',
      ),
    ],
  );
}
