// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../code_generator.dart';
import '../../code_generator/scope.dart';
import '../../context.dart';
import '../clang_bindings/clang_bindings.dart' as clang_types;
import '../utils.dart';
import 'api_availability.dart';
import 'functiondecl_parser.dart';

/// Parses a C++ class declaration.
CppClass? parseClassDeclaration(Context context, clang_types.CXCursor cursor) {
  final config = context.config;
  final logger = context.logger;

  // If C++ support is not configured, skip all C++ class cursors immediately.
  if (config.cpp == null) return null;

  final usr = cursor.usr();

  final cachedClass = context.bindingsIndex.getSeenCppClass(usr);
  if (cachedClass != null) return cachedClass;

  cursor = context.cursorIndex.getDefinition(cursor);

  // Use the libclang API to detect anonymous classes reliably.
  final String className;
  if (clang.clang_Cursor_isAnonymous(cursor) == 0) {
    className = cursor.spelling();
  } else {
    logger.fine('Skipping anonymous C++ class.');
    return null;
  }

  if (className.isEmpty) {
    logger.fine('Skipping anonymous C++ class.');
    return null;
  }

  final qualifiedName = qualifiedNameFromCursor(cursor, className);

  if (!_isAccessible(cursor)) {
    logger.fine('Skipping non-public nested C++ class $qualifiedName.');
    return null;
  }

  final apiAvailability = ApiAvailability.fromCursor(cursor, context);
  if (apiAvailability.availability == Availability.none) {
    logger.info('Omitting deprecated C++ class $qualifiedName');
    return null;
  }

  logger.fine(
    '++++ Adding C++ Class: Name: $qualifiedName, '
    '${cursor.completeStringRepr()}',
  );

  final destructor = _destructorOf(cursor);
  final hasPublicDestructor =
      destructor.access == clang_types.CX_CXXAccessSpecifier.CX_CXXPublic;
  final cppClass = CppClass(
    usr: usr,
    dartDoc: getCursorDocComment(
      context,
      cursor,
      availability: apiAvailability.dartDoc,
    ),
    originalName: qualifiedName,
    name: flattenQualifiedName(qualifiedName),
    context: context,
    methods: <CppMethod>[],
    fields: <CppMember>[],
    bases: <CppClass>[],
    isAbstract: clang.clang_CXXRecord_isAbstract(cursor) != 0,
    hasPublicDestructor: hasPublicDestructor,
    isDeletable:
        hasPublicDestructor &&
        (destructor.isVirtual || !_isPolymorphic(cursor)),
  );

  context.bindingsIndex.addCppClassToSeen(usr, cppClass);

  cursor.visitChildren((child) {
    final kind = switch (child.kind) {
      clang_types.CXCursorKind.CXCursor_CXXMethod => CppMethodKind.method,
      clang_types.CXCursorKind.CXCursor_Constructor =>
        CppMethodKind.constructor,
      _ => null,
    };
    if (kind == null) return;
    if (!_isCallable(child)) {
      logger.fine(
        '  ---- Skipping non-public or deleted ${kind.name} '
        '${child.spelling()}',
      );
    } else if (kind == CppMethodKind.constructor && cppClass.isAbstract) {
      logger.fine('  ---- Skipping constructor of abstract class');
    } else {
      _parseAnyMethod(context, child, cppClass, kind);
    }
  });

  // Parse public base classes (only public specifiers; non-public are ignored).
  cppClass.bases.addAll(_parsePublicBases(context, cursor));

  return cppClass;
}

/// Parses the direct public base classes of [cursor].
List<CppClass> _parsePublicBases(Context context, clang_types.CXCursor cursor) {
  final bases = <CppClass>[];

  cursor.visitChildren((child) {
    final kind = clang.clang_getCursorKind(child);
    if (kind != clang_types.CXCursorKind.CXCursor_CXXBaseSpecifier) return;

    final access = clang.clang_getCXXAccessSpecifier(child);
    if (access != clang_types.CX_CXXAccessSpecifier.CX_CXXPublic) return;

    final baseType = clang.clang_getCursorType(child);
    final baseDeclCursor = clang.clang_getTypeDeclaration(baseType);
    final baseUsr = baseDeclCursor.usr();

    final baseClass = context.bindingsIndex.getSeenCppClass(baseUsr);
    if (baseClass == null) {
      final parsed = parseClassDeclaration(context, baseDeclCursor);
      if (parsed != null) bases.add(parsed);
    } else {
      bases.add(baseClass);
    }
  });

  return bases;
}

/// Whether the class at [cursor] can be named from outside of it, which the
/// generated glue functions need to do.
///
/// A class nested in a private or protected section of another class can't be,
/// and neither can anything nested in it.
bool _isAccessible(clang_types.CXCursor cursor) {
  for (
    var c = cursor;
    _isRecordKind(clang.clang_getCursorKind(c));
    c = clang.clang_getCursorSemanticParent(c)
  ) {
    final access = clang.clang_getCXXAccessSpecifier(c);
    if (access == clang_types.CX_CXXAccessSpecifier.CX_CXXPrivate ||
        access == clang_types.CX_CXXAccessSpecifier.CX_CXXProtected) {
      return false;
    }
  }
  return true;
}

bool _isRecordKind(int kind) =>
    kind == clang_types.CXCursorKind.CXCursor_ClassDecl ||
    kind == clang_types.CXCursorKind.CXCursor_StructDecl ||
    kind == clang_types.CXCursorKind.CXCursor_UnionDecl;

/// Whether the member function at [cursor] can be called from outside of its
/// class, which the generated glue functions need to do.
///
/// It has to be public, and not deleted, which libclang reports as
/// unavailable.
bool _isCallable(clang_types.CXCursor cursor) =>
    clang.clang_getCXXAccessSpecifier(cursor) ==
        clang_types.CX_CXXAccessSpecifier.CX_CXXPublic &&
    clang.clang_getCursorAvailability(cursor) !=
        clang_types.CXAvailabilityKind.CXAvailability_NotAvailable;

/// The access of the destructor of the class at [cursor], and whether it's
/// virtual.
///
/// libclang doesn't expose an implicit destructor, so its properties are
/// derived from the bases. A deleted destructor is reported as private, since
/// nothing can call it.
({int access, bool isVirtual}) _destructorOf(clang_types.CXCursor cursor) {
  final declared = cursor.findChildWithKind(
    clang_types.CXCursorKind.CXCursor_Destructor,
  );
  if (declared != null) {
    return (
      access:
          clang.clang_getCursorAvailability(declared) ==
              clang_types.CXAvailabilityKind.CXAvailability_NotAvailable
          ? clang_types.CX_CXXAccessSpecifier.CX_CXXPrivate
          : clang.clang_getCXXAccessSpecifier(declared),
      isVirtual: clang.clang_CXXMethod_isVirtual(declared) != 0,
    );
  }

  // An implicit destructor is public, but it's deleted if it can't call the
  // destructor of a base, and it's virtual if the destructor of a base is.
  var access = clang_types.CX_CXXAccessSpecifier.CX_CXXPublic;
  var isVirtual = false;
  for (final base in _baseDefinitions(cursor)) {
    final baseDestructor = _destructorOf(base);
    if (baseDestructor.access ==
        clang_types.CX_CXXAccessSpecifier.CX_CXXPrivate) {
      access = clang_types.CX_CXXAccessSpecifier.CX_CXXPrivate;
    }
    isVirtual = isVirtual || baseDestructor.isVirtual;
  }
  return (access: access, isVirtual: isVirtual);
}

/// Whether the class at [cursor] declares or inherits a virtual method.
bool _isPolymorphic(clang_types.CXCursor cursor) =>
    cursor.findChildWhere(
          (child) => switch (child.kind) {
            clang_types.CXCursorKind.CXCursor_CXXMethod ||
            clang_types.CXCursorKind.CXCursor_Destructor ||
            clang_types.CXCursorKind.CXCursor_ConversionFunction =>
              clang.clang_CXXMethod_isVirtual(child) != 0,
            _ => false,
          },
        ) !=
        null ||
    _baseDefinitions(cursor).any(_isPolymorphic);

/// The definitions of the direct bases of the class at [cursor], whatever
/// their access.
List<clang_types.CXCursor> _baseDefinitions(clang_types.CXCursor cursor) {
  final bases = <clang_types.CXCursor>[];
  cursor.visitChildren((child) {
    if (child.kind != clang_types.CXCursorKind.CXCursor_CXXBaseSpecifier) {
      return;
    }
    final declaration = clang.clang_getTypeDeclaration(
      clang.clang_getCursorType(child),
    );
    final definition = clang.clang_getCursorDefinition(declaration);
    bases.add(definition.isNull ? declaration : definition);
  });
  return bases;
}

void _parseAnyMethod(
  Context context,
  clang_types.CXCursor cursor,
  CppClass cppClass,
  CppMethodKind kind,
) {
  final logger = context.logger;
  final methodName = cursor.spelling();
  final dartName = _dartMethodName(
    methodName,
    clang.clang_Cursor_getNumArguments(cursor),
  );
  if (dartName == null) {
    logger.fine('  ---- Skipping unsupported operator $methodName');
    return;
  }
  final isStatic =
      kind == CppMethodKind.constructor ||
      clang.clang_CXXMethod_isStatic(cursor) != 0;
  final isConst =
      kind == CppMethodKind.method &&
      clang.clang_CXXMethod_isConst(cursor) != 0;

  final (
    :parameters,
    :hasIncompleteStruct,
    :hasUnimplementedType,
    unsupportedTypes: _,
  ) = parseParameters(
    context,
    cursor,
    cppGlue: true,
  );
  if (hasIncompleteStruct || hasUnimplementedType) {
    logger.fine(
      '  ---- Skipping method $methodName due to unsupported parameter type',
    );
    return;
  } else if (!parameters.every((p) => _canPassByValue(p.type))) {
    logger.fine(
      '  ---- Skipping method $methodName, class passed by value can\'t be '
      'destroyed',
    );
    return;
  }

  final cxReturnType = clang.clang_getCursorResultType(cursor);
  final returnType = cxReturnType.toCodeGenType(context, cppGlue: true);
  if (returnType.baseType is UnimplementedType) {
    logger.fine(
      '  ---- Skipping method $methodName due to unsupported return type',
    );
    return;
  } else if (returnType.isIncompleteCompound) {
    logger.fine(
      '  ---- Skipping method $methodName, incomplete struct returned by value',
    );
    return;
  } else if (!_canReturnByValue(returnType)) {
    logger.fine(
      '  ---- Skipping method $methodName, class returned by value can\'t be '
      'deleted',
    );
    return;
  }

  // NameCppMethodsVisitation picks the final names, once all the overloads
  // are known.
  final name = switch (kind) {
    CppMethodKind.constructor => '',
    CppMethodKind.method => dartName,
  };

  logger.fine('  ++++ ${kind.name}: $methodName (const=$isConst)');
  cppClass.methods.add(
    CppMethod(
      name: Symbol(name, SymbolKind.method),
      cBindingSymbol: Symbol(
        '${cppClass.cSymbolPrefix}_${name.isEmpty ? 'new' : name}',
        SymbolKind.method,
      ),
      originalName: methodName,
      returnType: returnType,
      parameters: parameters,
      isConstant: isConst,
      isStatic: isStatic,
      kind: kind,
      // The glue returns a reference to a class as a pointer.
      returnsPointerToConst: switch (returnType.typealiasType) {
        CppClassReferenceType(:final isConst) => isConst,
        _ => _isPointerToConst(cxReturnType),
      },
    ),
  );
}

/// Whether a glue function can pass [type] by value.
///
/// The parameter is a copy of a C++ class, which the glue function destroys
/// when the call ends.
bool _canPassByValue(Type type) => switch (type.typealiasType) {
  final CppClass c => !c.isAbstract && c.hasPublicDestructor,
  _ => true,
};

/// Whether a glue function can return [type] by value.
///
/// The glue function returns a C++ class by copying it to the heap, for the
/// Dart object to own, and delete.
bool _canReturnByValue(Type type) => switch (type.typealiasType) {
  final CppClass c => !c.isAbstract && c.isDeletable,
  _ => true,
};

/// Whether [type] is a pointer to const at any level, like `const T*` or
/// `T* const*`.
bool _isPointerToConst(clang_types.CXType type) {
  for (
    var t = clang.clang_getCanonicalType(type);
    t.kind == clang_types.CXTypeKind.CXType_Pointer;
    t = clang.clang_getPointeeType(t)
  ) {
    if (clang.clang_getPointeeType(t).isConstQualified) return true;
  }
  return false;
}

/// The Dart name of the C++ method [spelling], which takes [numParams]
/// parameters, or null if it's an operator that isn't supported.
///
/// An operator can't keep its C++ name, like `operator==`, so it's named after
/// the operation instead, like `operatorEqual`.
String? _dartMethodName(String spelling, int numParams) {
  final match = _operatorPattern.matchAsPrefix(spelling);
  if (match == null) return spelling;
  final op = match[1]!;
  final name =
      switch (numParams) {
        0 => _unaryOperatorNames[op],
        1 => _postfixOperatorNames[op],
        _ => null,
      } ??
      _operatorNames[op];
  return name == null ? null : 'operator$name';
}

/// Matches `operator==`, `operator new` etc, but not a method that's merely
/// named starting with "operator", like `operators`.
final _operatorPattern = RegExp(r'operator(?![\w$])\s*(.*)');

/// The names of the C++ operators that can be bound, after the `operator`
/// prefix.
///
/// The allocation operators (`new`, `delete`, `new[]` and `delete[]`) and
/// `co_await` are left out.
const _operatorNames = {
  '+': 'Plus',
  '-': 'Minus',
  '*': 'Multiply',
  '/': 'Divide',
  '%': 'Modulo',
  '^': 'BitwiseXor',
  '&': 'BitwiseAnd',
  '|': 'BitwiseOr',
  '~': 'BitwiseNot',
  '!': 'LogicalNot',
  '&&': 'LogicalAnd',
  '||': 'LogicalOr',
  '<<': 'ShiftLeft',
  '>>': 'ShiftRight',
  '==': 'Equal',
  '!=': 'NotEqual',
  '<': 'Less',
  '<=': 'LessEqual',
  '>': 'Greater',
  '>=': 'GreaterEqual',
  '<=>': 'Compare',
  '=': 'Assign',
  '+=': 'PlusAssign',
  '-=': 'MinusAssign',
  '*=': 'MultiplyAssign',
  '/=': 'DivideAssign',
  '%=': 'ModuloAssign',
  '^=': 'BitwiseXorAssign',
  '&=': 'BitwiseAndAssign',
  '|=': 'BitwiseOrAssign',
  '<<=': 'ShiftLeftAssign',
  '>>=': 'ShiftRightAssign',
  '++': 'Increment',
  '--': 'Decrement',
  ',': 'Comma',
  '->': 'Arrow',
  '->*': 'ArrowStar',
  '()': 'Call',
  '[]': 'Subscript',
};

/// The names of operators that are unary when they take no parameters, and
/// binary otherwise.
const _unaryOperatorNames = {
  '+': 'UnaryPlus',
  '-': 'Negate',
  '*': 'Dereference',
  '&': 'AddressOf',
};

/// The names of the postfix increment and decrement operators, which take a
/// dummy `int` parameter to tell them apart from the prefix ones.
const _postfixOperatorNames = {'++': 'PostIncrement', '--': 'PostDecrement'};
