// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'scope.dart';

/// Manages local variable declarations for a method or block of code.
class LocalVariables {
  final Scope scope;
  final List<String> _declarations = [];
  final List<String> _cleanups = [];

  LocalVariables(this.scope);

  /// Adds a new local variable with the given [value] and returns its name.
  ///
  /// If [cleanup] is given, it is called with the variable's name and returns
  /// a statement that releases the variable. [wrapWithCleanups] runs these
  /// statements after the code that uses the variables.
  String addVariable(
    String nameHint,
    String value, {
    String Function(String name)? cleanup,
  }) {
    final name = scope.addPrivate('_\$\$$nameHint');
    _declarations.add('final $name = $value;');
    if (cleanup != null) _cleanups.add(cleanup(name));
    return name;
  }

  /// Returns whether any local variables have been declared.
  bool get isNotEmpty => _declarations.isNotEmpty;

  /// Generates the declarations of all local variables.
  String generateDeclarations() {
    return _declarations.join('  \n');
  }

  /// Wraps [body] so that the variables' cleanup statements run after it,
  /// even if it throws.
  String wrapWithCleanups(String body) {
    if (_cleanups.isEmpty) return body;
    return '''
try {
      $body
    } finally {
      ${_cleanups.join('\n')}
    }''';
  }
}
