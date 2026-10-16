// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:ffigen/ffigen.dart';
import 'package:ffigen/src/context.dart';
import 'package:ffigen/src/header_parser.dart' as parser;
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('cpp_exception_rename', () {
    late String output;
    late String logString;

    setUpAll(() {
      final logArr = <String>[];
      final logger = createTestLogger(
        capturedMessages: logArr,
        level: Level.WARNING,
      );
      final library = parser.parse(
        Context(
          logger,
          FfiGenerator(
            output: Output(
              dart: DartOutput(path: Uri.file('unused')),
              style: const NativeExternalBindings(
                assetId: 'package:ffigen/cpp_test',
              ),
            ),
            input: Input(
              entryPoints: [
                Uri.file(
                  absPath('test/header_parser_tests/cpp_exception_rename.h'),
                ),
              ],
            ),
            cpp: const Cpp(catchExceptions: true),
            visitors: [
              Visitor(
                cppClass: (node) =>
                    node.isIncluded = node.originalName == 'CppException',
              ),
            ],
          ),
        ),
      );
      output = library.generate();
      logString = logArr.join('\n');
    });

    test('the C++ class keeps its name', () {
      expect(output, contains('class CppException implements ffi.Finalizable'));
    });

    test('the exception class is renamed, with a warning', () {
      expect(output, contains(r'class CppException$1 implements Exception'));
      expect(
        logString,
        contains(
          r'The C++ exception class is generated as CppException$1, since '
          'another binding is named CppException.',
        ),
      );
    });

    test("the renamed exception's toString escapes the name", () {
      expect(
        output,
        contains(r"String toString() => 'CppException\$1: $message';"),
      );
    });
  });
}
