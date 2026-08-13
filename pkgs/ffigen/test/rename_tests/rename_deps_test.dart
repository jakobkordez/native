// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:ffigen/src/code_generator.dart';
import 'package:ffigen/src/config_provider/config.dart';
import 'package:ffigen/src/config_provider/public_ast.dart' as ast;
import 'package:ffigen/src/header_parser.dart' as parser;
import 'package:test/test.dart';

import '../test_utils.dart';

/// Records the original name of every declaration the visitor is handed, and
/// renames it.
final class _Renamer extends ast.Visitor {
  final List<String> seen;

  _Renamer(this.seen) : super.base();

  void _rename(ast.DeclNode node) {
    seen.add(node.originalName);
    node.name = 'renamed_${node.originalName}';
  }

  @override
  void visitStruct(ast.Struct node) => _rename(node);

  @override
  void visitUnion(ast.Union node) => _rename(node);

  @override
  void visitEnum(ast.EnumClass node) => _rename(node);

  @override
  void visitTypealias(ast.Typealias node) => _rename(node);
}

void main() {
  group('rename_deps_test', () {
    late Library library;
    late List<String> seen;

    setUpAll(() {
      seen = <String>[];
      final entryPoint = Uri.file(absPath('test/rename_tests/rename_deps.h'));
      final context = testContext(
        FfiGenerator(
          output: Output(dartFile: Uri.file('unused')),
          input: Input(
            entryPoints: [entryPoint],
            // `rename_deps_dep.h` is deliberately excluded, so its
            // declarations are never parsed as top level bindings. They're
            // only reachable as dependencies of the functions below.
            include: (header) => header == entryPoint,
          ),
          // The functions are the only declarations named by a filter.
          functions: Functions.includeAll,
          visitors: [_Renamer(seen)],
        ),
      );
      library = parser.parse(context);
    });

    test('dependency-only declarations are passed to the visitors', () {
      expect(
        seen,
        containsAll([
          'dep_struct',
          'dep_union',
          'dep_enum',
          'dep_typedef',
          'dep_typedef_struct',
        ]),
      );
    });

    test('the names the visitors set are used in the bindings', () {
      final names = library.bindings.map((b) => b.name).toSet();
      expect(
        names,
        containsAll([
          'renamed_dep_struct',
          'renamed_dep_union',
          'renamed_dep_enum',
          // The typealias itself isn't emitted, but the struct it refers to
          // is, and it's only reachable through the typealias.
          'renamed_dep_typedef_struct',
        ]),
      );
    });
  });
}
