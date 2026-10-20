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
    fields: <CppField>[],
    bases: <CppClass>[],
    isAbstract: clang.clang_CXXRecord_isAbstract(cursor) != 0,
    hasPublicDestructor: hasPublicDestructor,
    isDeletable:
        hasPublicDestructor &&
        (destructor.isVirtual || !_isPolymorphic(cursor)),
    isCopyable: _isCopyable(cursor),
  );

  context.bindingsIndex.addCppClassToSeen(usr, cppClass);

  cursor.visitChildren((child) {
    if (child.kind == clang_types.CXCursorKind.CXCursor_FieldDecl) {
      _parseField(context, child, cppClass);
      return;
    }
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

/// Whether the class or enum at [cursor] can be named from outside of it,
/// which the generated glue functions need to do.
///
/// A class or enum nested in a private or protected section of a class can't
/// be, and neither can anything nested in it.
bool _isAccessible(clang_types.CXCursor cursor) {
  for (
    var c = cursor;
    _isRecordKind(clang.clang_getCursorKind(c)) ||
        clang.clang_getCursorKind(c) ==
            clang_types.CXCursorKind.CXCursor_EnumDecl;
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

/// Whether the record at [cursor], a definition, is a plain aggregate, like
/// `struct Range { int lo = -1; int hi = -1; };`, which libclang doesn't
/// report as POD only because a default member initializer makes its default
/// constructor non-trivial.
///
/// It has the layout and the copy semantics of a C struct, so it's bound as
/// one, which a C function can then take or return by value, unlike a C++
/// class. Like a POD record, its methods aren't bound, and a struct that Dart
/// allocates starts out zeroed, not with the default values.
///
/// It declares no constructor, destructor or assignment operator, no virtual
/// method and no function template, has no base, and all of its fields are
/// public and [_isPlainFieldType].
bool isPlainAggregate(clang_types.CXCursor cursor) =>
    cursor.findChildWhere(
      (child) => switch (child.kind) {
        clang_types.CXCursorKind.CXCursor_CXXBaseSpecifier ||
        clang_types.CXCursorKind.CXCursor_Constructor ||
        clang_types.CXCursorKind.CXCursor_Destructor ||
        clang_types.CXCursorKind.CXCursor_FunctionTemplate => true,
        clang_types.CXCursorKind.CXCursor_CXXMethod =>
          child.spelling() == 'operator=' ||
              clang.clang_CXXMethod_isVirtual(child) != 0,
        clang_types.CXCursorKind.CXCursor_FieldDecl =>
          clang.clang_getCXXAccessSpecifier(child) !=
                  clang_types.CX_CXXAccessSpecifier.CX_CXXPublic ||
              !_isPlainFieldType(clang.clang_getCursorType(child)),
        _ => false,
      },
    ) ==
    null;

/// Whether a field of [type] keeps a record a plain aggregate, see
/// [isPlainAggregate]: it's a mutable scalar, pointer, POD record or plain
/// aggregate, or an array of them.
bool _isPlainFieldType(clang_types.CXType type) {
  var t = clang.clang_getCanonicalType(type);
  while (t.kind == clang_types.CXTypeKind.CXType_ConstantArray) {
    t = clang.clang_getCanonicalType(clang.clang_getArrayElementType(t));
  }
  // A struct field can always be assigned.
  if (t.isConstQualified ||
      t.kind == clang_types.CXTypeKind.CXType_LValueReference ||
      t.kind == clang_types.CXTypeKind.CXType_RValueReference) {
    return false;
  }
  if (t.kind != clang_types.CXTypeKind.CXType_Record) return true;
  if (clang.clang_isPODType(t) != 0) return true;
  // libclang doesn't expose the members of an implicit instantiation of a
  // class template, like `std::string`, so it would look like an empty plain
  // aggregate.
  if (clang.clang_Type_getNumTemplateArguments(t) != -1) return false;
  final definition = clang.clang_getCursorDefinition(
    clang.clang_getTypeDeclaration(t),
  );
  return !definition.isNull && isPlainAggregate(definition);
}

/// The ways the glue copies an object.
enum _Copy {
  /// Copy constructing a new object, to pass it by value.
  construction,

  /// Copy assigning to an existing object, to set a field.
  assignment,
}

/// Whether the glue can copy an object of the class at [cursor], in the way
/// of [copy], which needs a public copy constructor, or copy assignment
/// operator, that isn't deleted.
///
/// libclang doesn't expose an implicit copy constructor or copy assignment
/// operator, so whether the class has one is derived from its declarations:
/// it's deleted if the class declares a move constructor or a move assignment
/// operator, or if a base or a field can't be copied. [isBase] is whether a
/// derived class copies it, which can also call a protected copy constructor
/// or copy assignment operator.
///
/// [visited] holds the USRs of the classes already checked, or being checked,
/// which a field like `std::vector<Node> children` makes recursive. They count
/// as copyable, since one that isn't ends the check as soon as it's known.
bool _isCopyable(
  clang_types.CXCursor cursor, {
  _Copy copy = _Copy.construction,
  bool isBase = false,
  Set<String>? visited,
}) {
  final usr = cursor.usr();
  visited ??= {};
  if (!visited.add(usr)) return true;

  // Whether [function] takes a single parameter of the class, by a reference
  // of [kind], or by value if [kind] is `CXType_Record`.
  bool takesClass(clang_types.CXCursor function, int kind) {
    if (clang.clang_Cursor_getNumArguments(function) != 1) return false;
    final type = clang.clang_getCanonicalType(
      clang.clang_getCursorType(clang.clang_Cursor_getArgument(function, 0)),
    );
    if (type.kind != kind) return false;
    final classType = kind == clang_types.CXTypeKind.CXType_Record
        ? type
        : clang.clang_getPointeeType(type);
    return clang.clang_getTypeDeclaration(classType).usr() == usr;
  }

  final copyFunctions = <clang_types.CXCursor>[];
  var declaresMove = false;
  final fieldTypes = <clang_types.CXType>[];
  cursor.visitChildren((child) {
    switch (child.kind) {
      case clang_types.CXCursorKind.CXCursor_Constructor:
        if (takesClass(child, clang_types.CXTypeKind.CXType_LValueReference)) {
          if (copy == _Copy.construction) copyFunctions.add(child);
        } else if (takesClass(
          child,
          clang_types.CXTypeKind.CXType_RValueReference,
        )) {
          declaresMove = true;
        }
      case clang_types.CXCursorKind.CXCursor_CXXMethod
          when child.spelling() == 'operator=':
        if (takesClass(child, clang_types.CXTypeKind.CXType_LValueReference) ||
            takesClass(child, clang_types.CXTypeKind.CXType_Record)) {
          if (copy == _Copy.assignment) copyFunctions.add(child);
        } else if (takesClass(
          child,
          clang_types.CXTypeKind.CXType_RValueReference,
        )) {
          declaresMove = true;
        }
      case clang_types.CXCursorKind.CXCursor_FieldDecl:
        fieldTypes.add(clang.clang_getCursorType(child));
    }
  });

  if (copyFunctions.isNotEmpty) {
    return copyFunctions.any((function) {
      final access = clang.clang_getCXXAccessSpecifier(function);
      return clang.clang_getCursorAvailability(function) !=
              clang_types.CXAvailabilityKind.CXAvailability_NotAvailable &&
          (access == clang_types.CX_CXXAccessSpecifier.CX_CXXPublic ||
              isBase &&
                  access == clang_types.CX_CXXAccessSpecifier.CX_CXXProtected);
    });
  }
  return !declaresMove &&
      _baseDefinitions(cursor).every(
        (base) => _isCopyable(base, copy: copy, isBase: true, visited: visited),
      ) &&
      fieldTypes.every((type) => _isTypeCopyable(type, copy, visited!));
}

/// Whether the glue can copy a field of [type], in the way of [copy], see
/// [_isCopyable].
///
/// libclang doesn't expose the members of an implicit instantiation of a
/// class template, so of the standard library's templates, only a
/// `std::unique_ptr`, and a `std::vector` of something that can't be copied,
/// are known not to be copyable.
bool _isTypeCopyable(
  clang_types.CXType type,
  _Copy copy, [
  Set<String>? visited,
]) {
  visited ??= {};
  var t = clang.clang_getCanonicalType(type);
  while (t.kind == clang_types.CXTypeKind.CXType_ConstantArray) {
    t = clang.clang_getArrayElementType(t);
  }
  // A const object can't be assigned, and a reference can't be rebound.
  if (copy == _Copy.assignment &&
      (t.isConstQualified ||
          t.kind == clang_types.CXTypeKind.CXType_LValueReference)) {
    return false;
  }
  if (t.kind == clang_types.CXTypeKind.CXType_RValueReference) return false;
  if (t.kind != clang_types.CXTypeKind.CXType_Record) return true;
  if (isStdUniquePtr(t)) return false;
  if (isStdDecl(t, 'vector')) {
    // Assigning a vector copy constructs the elements it doesn't have yet.
    final element = clang.clang_Type_getTemplateArgumentAsType(t, 0);
    return _isTypeCopyable(element, copy, visited) &&
        (copy == _Copy.construction ||
            _isTypeCopyable(element, _Copy.construction));
  }
  final definition = clang.clang_getCursorDefinition(
    clang.clang_getTypeDeclaration(t),
  );
  return definition.isNull ||
      _isCopyable(definition, copy: copy, visited: visited);
}

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

/// Parses the field at [cursor], a non-static data member of [cppClass].
///
/// The Dart class gets a getter for the field, and a setter if the field can
/// be assigned, which call glue functions that read and assign it.
void _parseField(
  Context context,
  clang_types.CXCursor cursor,
  CppClass cppClass,
) {
  final logger = context.logger;
  final fieldName = cursor.spelling();
  // An unnamed bit-field only pads the class's layout.
  if (fieldName.isEmpty) return;
  if (clang.clang_getCXXAccessSpecifier(cursor) !=
      clang_types.CX_CXXAccessSpecifier.CX_CXXPublic) {
    logger.fine('  ---- Skipping non-public field $fieldName');
    return;
  }
  final apiAvailability = ApiAvailability.fromCursor(cursor, context);
  if (apiAvailability.availability == Availability.none) {
    logger.fine('  ---- Skipping unavailable field $fieldName');
    return;
  }

  final cxType = clang.clang_getCursorType(cursor);
  if (_whyCantAccessField(cxType) case final reason?) {
    logger.fine('  ---- Skipping field $fieldName, $reason');
    return;
  }
  final type = cursor.toCodeGenType(context, cppGlue: true);
  if (type.baseType is UnimplementedType) {
    logger.fine('  ---- Skipping field $fieldName due to unsupported type');
    return;
  } else if (type.isIncompleteCompound) {
    logger.fine('  ---- Skipping field $fieldName, incomplete struct');
    return;
  }

  // The getter of a C++ class field returns a reference to it, and the getter
  // of a std::unique_ptr field returns the pointer it holds, rather than
  // copying or moving it out of the object.
  final canonical = clang.clang_getCanonicalType(cxType);
  final getterType = switch (type.typealiasType) {
    final CppClass cppClass => CppClassReferenceType(
      cppClass,
      isConst: canonical.isConstQualified,
    ),
    CppUniquePtrType(:final cppClass) => CppClassPointerType(cppClass),
    CppStdVectorType(isCopyable: false) => null,
    _ => type,
  };
  if (getterType == null) {
    logger.fine(
      "  ---- Skipping field $fieldName, its std::vector can't be copied",
    );
    return;
  }

  // A const field can't be assigned, and a reference field can't be rebound.
  final canAssign =
      !canonical.isConstQualified &&
      canonical.kind != clang_types.CXTypeKind.CXType_LValueReference &&
      canonical.kind != clang_types.CXTypeKind.CXType_RValueReference &&
      switch (type.typealiasType) {
        // The glue moves these from the value that Dart passes.
        CppUniquePtrType() || CppStdStringType() => true,
        final CppStdVectorType vector => vector.canPassFromDart,
        _ => _isTypeCopyable(cxType, _Copy.assignment),
      };
  if (type.typealiasType case final CppStdVectorType vector when canAssign) {
    vector.markPassedFromDart();
  }

  Symbol glueSymbol(String accessor) => Symbol(
    '${cppClass.cSymbolPrefix}_${accessor}_$fieldName',
    SymbolKind.method,
  );
  logger.fine('  ++++ field: $fieldName (setter=$canAssign)');
  cppClass.fields.add(
    CppField(
      name: Symbol(fieldName, SymbolKind.field),
      getterSymbol: glueSymbol('get'),
      setterSymbol: canAssign ? glueSymbol('set') : null,
      originalName: fieldName,
      dartDoc: getCursorDocComment(
        context,
        cursor,
        availability: apiAvailability.dartDoc,
      ),
      type: type,
      getterType: _nullableIfPointer(getterType),
      getterReturnsPointerToConst: switch (getterType.typealiasType) {
        CppClassReferenceType(:final isConst) => isConst,
        _ => isPointerToConst(cxType),
      },
    ),
  );
}

/// Why the glue can't access a field of [cxType], or null if it can.
///
/// The glue has to return the field's type, and name it.
String? _whyCantAccessField(clang_types.CXType cxType) {
  var t = clang.clang_getCanonicalType(cxType);
  if (t.kind == clang_types.CXTypeKind.CXType_LValueReference ||
      t.kind == clang_types.CXTypeKind.CXType_RValueReference) {
    t = clang.clang_getCanonicalType(clang.clang_getPointeeType(t));
  }
  switch (t.kind) {
    case clang_types.CXTypeKind.CXType_ConstantArray ||
        clang_types.CXTypeKind.CXType_IncompleteArray ||
        clang_types.CXTypeKind.CXType_VariableArray ||
        clang_types.CXTypeKind.CXType_DependentSizedArray:
      return "arrays aren't supported";
  }
  while (t.kind == clang_types.CXTypeKind.CXType_Pointer) {
    t = clang.clang_getCanonicalType(clang.clang_getPointeeType(t));
  }
  switch (t.kind) {
    case clang_types.CXTypeKind.CXType_FunctionProto ||
        clang_types.CXTypeKind.CXType_FunctionNoProto:
      return "function pointers aren't supported";
    case clang_types.CXTypeKind.CXType_Record ||
        clang_types.CXTypeKind.CXType_Enum:
      final declaration = clang.clang_getTypeDeclaration(t);
      if (clang.clang_Cursor_isAnonymous(declaration) != 0) {
        return 'its type is anonymous';
      }
      if (!_isAccessible(declaration)) return "its type isn't public";
  }
  return null;
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
  } else if (parameters.map((p) => _whyCantPass(p.type)).nonNulls.firstOrNull
      case final reason?) {
    logger.fine('  ---- Skipping method $methodName, $reason');
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
  } else if (returnType.typealiasType case CppStdVectorType(
    isCopyable: false,
  ) when cxReturnType.kind == clang_types.CXTypeKind.CXType_LValueReference) {
    logger.fine(
      '  ---- Skipping method $methodName, the std::vector it returns by '
      "reference can't be copied",
    );
    return;
  }

  // Only the vectors that are passed from Dart need the helpers copying a
  // List into one.
  for (final parameter in parameters) {
    if (parameter.type.typealiasType case final CppStdVectorType vector) {
      vector.markPassedFromDart();
    }
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
      returnType: _nullableIfPointer(returnType),
      parameters: parameters,
      isConstant: isConst,
      isStatic: isStatic,
      kind: kind,
      // The glue returns a reference to a class as a pointer.
      returnsPointerToConst: switch (returnType.typealiasType) {
        CppClassReferenceType(:final isConst) => isConst,
        _ => isPointerToConst(cxReturnType),
      },
    ),
  );
}

/// Why a glue function can't take a parameter of [type], or null if it can.
///
/// A C++ class passed by value is copied, and the copy destroyed when the call
/// ends. A `std::vector` is copied from a Dart [List].
String? _whyCantPass(Type type) => switch (type.typealiasType) {
  CppClass(isAbstract: true) || CppClass(hasPublicDestructor: false) =>
    "class passed by value can't be destroyed",
  CppClass(isCopyable: false) => "class passed by value can't be copied",
  CppStdVectorType(canPassFromDart: false) =>
    "the elements of a std::vector parameter can't be passed from Dart",
  _ => null,
};

/// [type], which a C++ method or a field getter returns, as nullable if it's a
/// pointer to a C++ class, or a `std::unique_ptr` to one, since C++ can return
/// a null one.
///
/// A reference can't be null.
Type _nullableIfPointer(Type type) => switch (type.typealiasType) {
  CppClassReferenceType() => type,
  CppClassPointerType() => CppNullablePointerType(type),
  _ => type,
};

/// Whether a glue function can return [type] by value.
///
/// The glue function returns a C++ class by copying it to the heap, for the
/// Dart object to own, and delete.
bool _canReturnByValue(Type type) => switch (type.typealiasType) {
  final CppClass c => !c.isAbstract && c.isDeletable,
  _ => true,
};

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
