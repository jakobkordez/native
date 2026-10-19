// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../code_generator.dart';
import '../code_generator/scope.dart';

import 'ast.dart';

/// Picks the default names of C++ methods and constructors, which have to
/// account for overloading, since Dart doesn't support it.
///
/// Fields copied from a base class take the name of the base's field, like
/// inherited methods.
///
///  - A method that overrides, or was copied from, a method of a base class
///    takes that method's name, so that the Dart class still implements its
///    bases. For the first base, the methods share a [Symbol], and the class's
///    scope is a child of the base's scope (see `CreateScopesVisitation`), so
///    the names stay in sync even if the [Scope] renames them.
///  - A const method with a non-const twin, which takes the same parameters,
///    gets a `Const` suffix, so that the plain name calls the non-const
///    overload. Dart has no notion of const, so the non-const overload is the
///    more useful one.
///  - The first constructor is the unnamed Dart constructor, and the others
///    are named `new$1`, `new$2`, etc.
///  - Other overloads keep their C++ name, so they collide, and the [Scope]
///    later appends `$1`, `$2`, etc to all but the first.
///
/// This runs before the user's visitors, so they see and can override these
/// names.
class NameCppMethodsVisitation extends Visitation {
  final _named = <CppClass>{};

  @override
  void visitCppClass(CppClass node) {
    node.visitChildren(visitor);
    _nameMethods(node);
  }

  void _nameMethods(CppClass node) {
    if (!_named.add(node)) return;
    node.bases.forEach(_nameMethods);

    final inherited = <CppMethod>{};
    final inheritedFields = <CppField>{};
    for (final (i, base) in node.bases.indexed) {
      final baseMethods = {
        for (final m in base.methods)
          if (!m.isConstructor) m.signatureKey(): m,
      };
      for (final method in node.methods) {
        if (method.isConstructor || inherited.contains(method)) continue;
        final baseMethod = baseMethods[method.signatureKey()];
        if (baseMethod == null) continue;
        inherited.add(method);
        if (i == 0) {
          method.name = baseMethod.name;
        } else {
          method.name.oldName = baseMethod.name.oldName;
        }
      }

      // A field is only ever inherited, never overridden, so the base's field
      // is the one declared by the same class.
      final baseFields = {
        for (final f in base.fields)
          (f.originatingClass ?? base, f.originalName): f,
      };
      for (final field in node.fields) {
        final declaringClass = field.originatingClass;
        if (declaringClass == null || inheritedFields.contains(field)) continue;
        final baseField = baseFields[(declaringClass, field.originalName)];
        if (baseField == null) continue;
        inheritedFields.add(field);
        if (i == 0) {
          field.name = baseField.name;
        } else {
          field.name.oldName = baseField.name.oldName;
        }
      }
    }

    var constructorCount = 0;
    for (final method in node.methods) {
      if (method.isConstructor) {
        method.name.oldName = constructorCount == 0
            ? ''
            : 'new\$$constructorCount';
        ++constructorCount;
      } else if (!inherited.contains(method) &&
          node.methods.any(method.isConstTwinOf)) {
        method.name.oldName = '${method.name.oldName}Const';
      }
      final suffix = method.isUnnamedConstructor ? 'new' : method.name.oldName;
      method.cBindingSymbol.oldName = '${node.cSymbolPrefix}_$suffix';
    }
  }
}
