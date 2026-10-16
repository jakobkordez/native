// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Extracts code_gen Type from type.
library;

import '../../code_generator.dart';
import '../../config_provider/config_types.dart';
import '../../context.dart';
import '../../strings.dart' as strings;
import '../clang_bindings/clang_bindings.dart' as clang_types;
import '../sub_parsers/classdecl_parser.dart';
import '../sub_parsers/compounddecl_parser.dart';
import '../sub_parsers/enumdecl_parser.dart';
import '../sub_parsers/function_type_param_parser.dart';
import '../sub_parsers/objc_block_parser.dart';
import '../sub_parsers/objcinterfacedecl_parser.dart';
import '../sub_parsers/objcprotocoldecl_parser.dart';
import '../sub_parsers/typedefdecl_parser.dart';
import '../type_extractor/cxtypekindmap.dart';
import '../utils.dart';

const _padding = '  ';

const maxRecursionDepth = 5;

/// Converts cxtype to a typestring code_generator can accept.
///
/// [cppGlue] is whether [cxtype] is a parameter or return type of a C++ method
/// or constructor. Those are called through generated C++ glue, which can
/// convert some types, like `std::string`, that are unsupported elsewhere.
Type getCodeGenType(
  Context context,
  clang_types.CXType cxtype, {

  /// Cursor of the declaration, currently this is useful only to extract
  /// parameter names in function types.
  clang_types.CXCursor? originalCursor,
  bool supportNonInlineArray = false,
  bool cppGlue = false,
}) {
  context.logger.fine(
    '${_padding}getCodeGenType ${cxtype.completeStringRepr()}',
  );

  // This sees through type sugar by itself, so it comes before the elaborated
  // types are unwrapped.
  if (context.config.cpp != null) {
    final stdType = _extractStdType(context, cxtype, cppGlue: cppGlue);
    if (stdType != null) return stdType;
  }

  // Special case: Elaborated types just refer to another type.
  if (cxtype.kind == clang_types.CXTypeKind.CXType_Elaborated) {
    return getCodeGenType(context, clang.clang_Type_getNamedType(cxtype));
  }

  // Handle C++ templates like std::unique_ptr.
  if (context.config.cpp != null &&
      clang.clang_Type_getNumTemplateArguments(cxtype) >= 1 &&
      isStdDecl(cxtype, 'unique_ptr')) {
    return _extractUniquePtrType(context, cxtype);
  }

  // These basic Objective C types skip the cache, and are conditional on the
  // language flag.
  if (context.config.objectiveC != null) {
    switch (cxtype.kind) {
      case clang_types.CXTypeKind.CXType_ObjCObjectPointer:
        final pt = clang.clang_getPointeeType(cxtype);
        final s = getCodeGenType(context, pt);
        if (s is ObjCInterface) {
          return s;
        }
        final numProtocols = clang.clang_Type_getNumObjCProtocolRefs(pt);
        if (numProtocols > 0) {
          final protocols = <ObjCProtocol>[];
          for (var i = 0; i < numProtocols; ++i) {
            final pdecl = clang.clang_Type_getObjCProtocolDecl(pt, i);
            final p = parseObjCProtocolDeclaration(context, pdecl);
            if (p != null) protocols.add(p);
          }
          if (protocols.isNotEmpty) {
            return ObjCObjectPointerWithProtocols(protocols);
          }
        }
        return PointerType(objCObjectType);
      case clang_types.CXTypeKind.CXType_ObjCId:
      case clang_types.CXTypeKind.CXType_ObjCTypeParam:
      case clang_types.CXTypeKind.CXType_ObjCClass:
        return PointerType(objCObjectType);
      case clang_types.CXTypeKind.CXType_ObjCSel:
        return PointerType(objCSelType);
      case clang_types.CXTypeKind.CXType_BlockPointer:
        return parseObjCBlock(context, cxtype);
    }
  }

  // If the type has a declaration cursor, then use the BindingsIndex to break
  // any potential cycles, and dedupe the Type.
  final cursor = clang.clang_getTypeDeclaration(cxtype);
  if (cursor.kind != clang_types.CXCursorKind.CXCursor_NoDeclFound) {
    final type = _createTypeFromCursor(context, cxtype, cursor);
    if (type == null) {
      return UnimplementedType('${cxtype.kindSpelling()} not implemented');
    }
    _fillFromCursorIfNeeded(context, type, cursor);
    return type;
  }

  // If the type doesn't have a declaration cursor, then it's a basic type such
  // as int, or a simple derived type like a pointer, so doesn't need to be
  // cached.
  switch (cxtype.kind) {
    case clang_types.CXTypeKind.CXType_Pointer:
      final pt = clang.clang_getPointeeType(cxtype);
      final s = getCodeGenType(context, pt, originalCursor: originalCursor);

      // Replace Pointer<_Dart_Handle> with Handle.
      if (s is Struct && s.usr == strings.dartHandleUsr) {
        return HandleType();
      }
      return PointerType(s);
    case clang_types.CXTypeKind.CXType_LValueReference:
      return _extractReference(context, cxtype, cppGlue: cppGlue);
    case clang_types.CXTypeKind.CXType_FunctionProto:
      // Primarily used for function pointers.
      return _extractFromFunctionProto(context, cxtype, cursor: originalCursor);
    case clang_types.CXTypeKind.CXType_FunctionNoProto:
      // Primarily used for function types with zero arguments.
      return _extractFromFunctionProto(context, cxtype, cursor: originalCursor);
    case clang_types.CXTypeKind.CXType_ConstantArray:
      // Primarily used for constant array in struct members.
      final numElements = clang.clang_getNumElements(cxtype);
      final elementType = clang
          .clang_getArrayElementType(cxtype)
          .toCodeGenType(context, supportNonInlineArray: supportNonInlineArray);
      // Handle numElements being 0 as an incomplete array.
      return numElements == 0
          ? IncompleteArray(elementType)
          : ConstantArray(
              numElements,
              elementType,
              useArrayType: supportNonInlineArray,
            );
    case clang_types.CXTypeKind.CXType_IncompleteArray:
      // Primarily used for incomplete array in function parameters.
      return IncompleteArray(
        clang.clang_getArrayElementType(cxtype).toCodeGenType(context),
      );
    case clang_types.CXTypeKind.CXType_Bool:
      return BooleanType();
    case clang_types.CXTypeKind.CXType_Attributed:
    case clang_types.CXTypeKind.CXType_Unexposed:
      // A standard typedef named through a using-declaration, like
      // `std::size_t` on MSVC, has no declaration. Like a typedef, it's
      // mapped by its name, since the type it stands for differs between
      // platforms.
      if (_standardTypedef(cxtype)?.name case final name?) {
        if (suportedTypedefToSuportedNativeType[name] case final type?) {
          return NativeType(type);
        }
        if (supportedTypedefToImportedType[name] case final type?) {
          return type;
        }
      }
      // Attributed types carry the type they modify; other unexposed types
      // (e.g. a using-declared C++ type) have none, so use the canonical type.
      var innerCxType = clang.clang_Type_getModifiedType(cxtype);
      if (innerCxType.kind == clang_types.CXTypeKind.CXType_Invalid) {
        final canonical = clang.clang_getCanonicalType(cxtype);
        // Recursion guard: a type that is already canonical (e.g. a dependent
        // template type) would otherwise resolve to itself forever.
        if (clang.clang_equalTypes(canonical, cxtype) == 0) {
          innerCxType = canonical;
        }
      }
      final innerType = getCodeGenType(
        context,
        innerCxType,
        originalCursor: originalCursor,
      );
      final isNullable =
          clang.clang_Type_getNullability(cxtype) ==
          clang_types.CXTypeNullabilityKind.CXTypeNullability_Nullable;
      return isNullable && ObjCNullable.isSupported(innerType)
          ? ObjCNullable(innerType)
          : innerType;
    default:
      var typeSpellKey = clang
          .clang_getTypeSpelling(cxtype)
          .toStringAndDispose();
      if (typeSpellKey.startsWith('const ')) {
        typeSpellKey = typeSpellKey.replaceFirst('const ', '');
      }
      final imported = context.config.importType(
        Declaration(usr: '', originalName: typeSpellKey),
      );
      if (imported != null) return ImportedType.fromPublic(imported);
      if (cxTypeKindToImportedTypes.containsKey(typeSpellKey)) {
        return cxTypeKindToImportedTypes[typeSpellKey]!;
      } else {
        context.logger.fine(
          'typedeclarationCursorVisitor: getCodeGenType: Type Not '
          'Implemented, ${cxtype.completeStringRepr()}',
        );
        return UnimplementedType('${cxtype.kindSpelling()} not implemented');
      }
  }
}

Type? _createTypeFromCursor(
  Context context,
  clang_types.CXType cxtype,
  clang_types.CXCursor cursor,
) {
  final logger = context.logger;
  final config = context.config;
  final usr = cursor.usr();
  final imported = context.config.importType(cursor.declaration());
  if (imported != null) return ImportedType.fromPublic(imported);
  switch (cxtype.kind) {
    case clang_types.CXTypeKind.CXType_Typedef:
      final spelling = clang.clang_getTypedefName(cxtype).toStringAndDispose();
      if (config.objectiveC != null && spelling == strings.objcBOOL) {
        // Objective C's BOOL type can be either bool or signed char, depending
        // on the platform. We want to present a consistent API to the user, and
        // those two types are ABI compatible, so just return bool regardless.
        return BooleanType();
      }
      final importedTypedef = context.config.importType(
        Declaration(usr: usr, originalName: spelling),
      );
      if (importedTypedef != null) {
        return ImportedType.fromPublic(importedTypedef);
      }
      // Get name from supported typedef name.
      if (suportedTypedefToSuportedNativeType.containsKey(spelling)) {
        logger.fine('  Type Mapped from supported typedef');
        return NativeType(suportedTypedefToSuportedNativeType[spelling]!);
      } else if (supportedTypedefToImportedType.containsKey(spelling)) {
        logger.fine('  Type Mapped from supported typedef');
        return supportedTypedefToImportedType[spelling]!;
      }

      final typealias = parseTypedefDeclaration(context, cursor);

      if (typealias.isAnonymous) {
        // Use underlying type if typealias couldn't be created or if the user
        // excluded this typedef.
        final ct = clang.clang_getTypedefDeclUnderlyingType(cursor);
        return getCodeGenType(context, ct);
      } else {
        return typealias;
      }
    case clang_types.CXTypeKind.CXType_Record:
      return _extractfromRecord(context, cxtype, cursor);
    case clang_types.CXTypeKind.CXType_Enum:
      final enumClass = parseEnumDeclaration(cursor, context);
      if (enumClass.isAnonymous) {
        return enumClass.nativeType;
      } else {
        return enumClass;
      }
    case clang_types.CXTypeKind.CXType_ObjCInterface:
    case clang_types.CXTypeKind.CXType_ObjCObject:
      return parseObjCInterfaceDeclaration(context, cursor);
    default:
      return UnimplementedType('Unknown type: ${cxtype.completeStringRepr()}');
  }
}

void _fillFromCursorIfNeeded(
  Context context,
  Type? type,
  clang_types.CXCursor cursor,
) {
  if (type == null) return;
  if (type is Compound) {
    fillCompoundMembersIfNeeded(type, cursor, context);
  } else if (type is ObjCInterface) {
    fillObjCInterfaceMethodsIfNeeded(context, type, cursor);
  }
}

Type? _extractfromRecord(
  Context context,
  clang_types.CXType cxtype,
  clang_types.CXCursor cursor,
) {
  final logger = context.logger;
  final config = context.config;
  logger.fine('${_padding}_extractfromRecord: ${cursor.completeStringRepr()}');

  final cursorKind = clang.clang_getCursorKind(cursor);

  final isClassOrStruct =
      cursorKind == clang_types.CXCursorKind.CXCursor_ClassDecl ||
      cursorKind == clang_types.CXCursorKind.CXCursor_StructDecl;

  if (config.cpp != null) {
    final seenCppClass = context.bindingsIndex.getSeenCppClass(cursor.usr());
    if (seenCppClass != null) return seenCppClass;

    final hasDefinition =
        clang.clang_Cursor_isNull(clang.clang_getCursorDefinition(cursor)) == 0;
    final isPodType = clang.clang_isPODType(cxtype) == 1;
    // Only non-POD records get the C++ class treatment; a POD record has a
    // layout the plain struct parser models correctly, so it is parsed as a
    // C struct below no matter which keyword declared it.
    if (isClassOrStruct && hasDefinition && !isPodType) {
      final cppClass = parseClassDeclaration(context, cursor);
      if (cppClass != null) return cppClass;
    }
  }

  final isUnion = cursorKind == clang_types.CXCursorKind.CXCursor_UnionDecl;
  if (isClassOrStruct || isUnion) {
    final imported = context.config.importType(cursor.declaration());
    if (imported != null) return ImportedType.fromPublic(imported);
    return isUnion
        ? parseUnionDeclaration(cursor, context)
        : parseStructDeclaration(cursor, context);
  }

  logger.fine(
    'typedeclarationCursorVisitor: _extractfromRecord: '
    'Not Implemented, ${cursor.completeStringRepr()}',
  );
  return UnimplementedType('${cxtype.kindSpelling()} not implemented');
}

/// Returns the type for [cxtype], a `std::unique_ptr`.
Type _extractUniquePtrType(Context context, clang_types.CXType cxtype) {
  final logger = context.logger;
  final spelling = cxtype.spelling();

  // The canonical type has every template argument, unlike the type as
  // written, whose arguments could even be an alias template's.
  final canonical = clang.clang_getCanonicalType(cxtype);
  if (!isStdUniquePtr(canonical)) {
    logger.warning(
      'std::unique_ptr with a custom deleter is not supported '
      '("$spelling"). Skipping.',
    );
    return UnimplementedType('unique_ptr with custom deleter not supported');
  }

  final innerCXType = clang.clang_Type_getTemplateArgumentAsType(canonical, 0);
  final innerType = getCodeGenType(context, innerCXType);

  if (innerType is CppClass) {
    if (!innerType.isDeletable) {
      logger.fine(
        '  unique_ptr<${innerType.originalName}> deletes a class that the '
        'bindings can\'t delete. Skipping.',
      );
      return UnimplementedType(
        'unique_ptr of a class that the bindings can\'t delete',
      );
    }
    logger.fine(
      '  unique_ptr<${innerType.originalName}> is an owned CppUniquePtrType',
    );
    return CppUniquePtrType(innerType);
  }

  logger.warning(
    'std::unique_ptr inner type is not a known C++ class '
    '(got ${innerType.runtimeType} from "$spelling"). Skipping.',
  );
  return UnimplementedType(
    'unique_ptr inner type is not a supported C++ class',
  );
}

/// Returns the type for [cxtype], an lvalue reference.
///
/// Only references to C++ classes are supported, and only by C++ methods and
/// constructors, whose glue passes them as pointers.
Type _extractReference(
  Context context,
  clang_types.CXType cxtype, {
  required bool cppGlue,
}) {
  if (!cppGlue) {
    return UnimplementedType(
      'References are only supported by C++ methods and constructors',
    );
  }
  final cxPointee = clang.clang_getPointeeType(cxtype);
  final pointee = getCodeGenType(context, cxPointee);
  if (pointee.typealiasType case final CppClass cppClass) {
    return CppClassReferenceType(
      cppClass,
      isConst: clang.clang_getCanonicalType(cxPointee).isConstQualified,
    );
  }
  return UnimplementedType('Reference to $pointee');
}

/// Returns the type for [cxtype] if it is a `std::string` or a `std::vector`,
/// or a reference to one, or null otherwise.
///
/// The check is on the canonical type, so it also covers aliases, like
/// `using Name = std::string;`. Either can be passed by value or by a const
/// or rvalue reference, and only to and from C++ methods and constructors.
Type? _extractStdType(
  Context context,
  clang_types.CXType cxtype, {
  required bool cppGlue,
}) {
  final isLValueReference =
      cxtype.kind == clang_types.CXTypeKind.CXType_LValueReference;
  final isReference =
      isLValueReference ||
      cxtype.kind == clang_types.CXTypeKind.CXType_RValueReference;
  final type = isReference ? clang.clang_getPointeeType(cxtype) : cxtype;
  final canonical = clang.clang_getCanonicalType(type);
  final String name;
  if (_isStdString(canonical)) {
    name = 'std::string';
  } else if (_isStdVector(canonical)) {
    name = 'std::vector';
  } else {
    return null;
  }

  if (!cppGlue) {
    return UnimplementedType(
      '$name is only supported by C++ methods and constructors',
    );
  }
  // The callee could modify it through a mutable reference, which would not
  // be reflected in the Dart object.
  if (isLValueReference && !canonical.isConstQualified) {
    return UnimplementedType('Mutable reference to $name');
  }
  return name == 'std::string'
      ? context.cppStdStringType
      : _extractStdVector(context, type, canonical);
}

/// Whether the canonical type [cxtype] is `std::string`, that is,
/// `std::basic_string<char, std::char_traits<char>, std::allocator<char>>`.
bool _isStdString(clang_types.CXType cxtype) {
  if (cxtype.kind != clang_types.CXTypeKind.CXType_Record ||
      clang.clang_Type_getNumTemplateArguments(cxtype) != 3) {
    return false;
  }
  final charType = clang.clang_Type_getTemplateArgumentAsType(cxtype, 0);
  final isChar =
      charType.kind == clang_types.CXTypeKind.CXType_Char_S ||
      charType.kind == clang_types.CXTypeKind.CXType_Char_U;
  return isChar &&
      isStdDecl(cxtype, 'basic_string') &&
      isStdDecl(
        clang.clang_Type_getTemplateArgumentAsType(cxtype, 1),
        'char_traits',
      ) &&
      isStdDecl(
        clang.clang_Type_getTemplateArgumentAsType(cxtype, 2),
        'allocator',
      );
}

/// Returns the type for [vectorType], a `std::vector` whose canonical type is
/// [canonical].
Type _extractStdVector(
  Context context,
  clang_types.CXType vectorType,
  clang_types.CXType canonical,
) {
  final (elementType, elementSpelling) = _stdVectorElement(
    vectorType,
    canonical,
  );
  if (elementSpelling == null) {
    return UnimplementedType(
      "std::vector of a type that can't be spelled in the glue: "
      '${elementType.spelling()}',
    );
  }
  final spelling = 'std::vector<$elementSpelling>';
  if (context.cppStdVectorTypes[spelling] case final vector?) return vector;

  final element = getCodeGenType(context, elementType, cppGlue: true);
  final unsupported = switch (element.typealiasType) {
    _ when element.baseType is UnimplementedType => 'an unsupported type',
    _ when element.isIncompleteCompound => 'an incomplete struct',
    // The glue copies each element to the heap for a Dart object to own.
    CppClass(isAbstract: true) => 'an abstract class',
    CppClass(isDeletable: false) => "a class that the bindings can't delete",
    _ => null,
  };
  if (unsupported != null) {
    return UnimplementedType('std::vector of $unsupported');
  }

  return context.cppStdVectorTypes[spelling] = CppStdVectorType(
    context,
    element: element,
    elementSpelling: elementSpelling,
    elementIsPointerToConst: isPointerToConst(elementType),
  );
}

/// The element type of the `std::vector` [vectorType], whose canonical type
/// is [canonical], and its spelling in the C++ glue, if it can be spelled.
///
/// That's the element type as written, which keeps its typedef names, if
/// available. libclang reports the template arguments of the outermost
/// template in the type's sugar, though, which for an alias template, like
/// `Ptrs<T>` for `template <class T> using Ptrs = std::vector<T*>`, aren't
/// the vector's. So if the written type isn't the element type, or can't be
/// spelled, like a substituted template parameter, it's the canonical one.
(clang_types.CXType, String?) _stdVectorElement(
  clang_types.CXType vectorType,
  clang_types.CXType canonical,
) {
  final element = clang.clang_Type_getTemplateArgumentAsType(canonical, 0);
  final written = clang.clang_Type_getTemplateArgumentAsType(vectorType, 0);
  if (written.kind != clang_types.CXTypeKind.CXType_Invalid &&
      clang.clang_equalTypes(clang.clang_getCanonicalType(written), element) !=
          0) {
    final spelling = _cppSpelling(written);
    if (spelling != null) return (written, spelling);
  }
  return (element, _cppSpelling(element));
}

/// Whether the canonical type [cxtype] is a `std::vector<T>` with the default
/// allocator, `std::allocator<T>`.
bool _isStdVector(clang_types.CXType cxtype) {
  if (cxtype.kind != clang_types.CXTypeKind.CXType_Record ||
      clang.clang_Type_getNumTemplateArguments(cxtype) != 2 ||
      !isStdDecl(cxtype, 'vector')) {
    return false;
  }
  final allocator = clang.clang_Type_getTemplateArgumentAsType(cxtype, 1);
  return isStdDecl(allocator, 'allocator') &&
      clang.clang_equalTypes(
            clang.clang_Type_getTemplateArgumentAsType(allocator, 0),
            clang.clang_Type_getTemplateArgumentAsType(cxtype, 0),
          ) !=
          0;
}

/// The spelling of [cxtype] in the C++ glue, or null if it can't be spelled.
///
/// Every name is fully qualified, since the glue is outside of any namespace,
/// and typedef names are kept, since the types that some of them stand for,
/// like `std::size_t`, differ between platforms.
String? _cppSpelling(clang_types.CXType cxtype) {
  final canonical = clang.clang_getCanonicalType(cxtype);
  final String? spelling;
  switch (cxtype.kind) {
    // Whatever sugar these are written through, which libclang may not expose.
    case _ when _isStdString(canonical):
      spelling = 'std::string';
    case _ when _isStdVector(canonical):
      final (_, element) = _stdVectorElement(cxtype, canonical);
      spelling = element == null ? null : 'std::vector<$element>';
    case _ when isStdUniquePtr(canonical):
      final pointee = _cppSpelling(
        clang.clang_Type_getTemplateArgumentAsType(canonical, 0),
      );
      spelling = pointee == null ? null : 'std::unique_ptr<$pointee>';
    case clang_types.CXTypeKind.CXType_Elaborated:
      spelling = _cppSpelling(clang.clang_Type_getNamedType(cxtype));
    case clang_types.CXTypeKind.CXType_Pointer:
      final pointee = _cppSpelling(clang.clang_getPointeeType(cxtype));
      if (pointee == null) return null;
      return cxtype.isConstQualified ? '$pointee* const' : '$pointee*';
    case clang_types.CXTypeKind.CXType_Typedef:
      final decl = clang.clang_getTypeDeclaration(cxtype);
      spelling = _qualifiedSpelling(decl) ?? _builtinSpelling(cxtype);
    case clang_types.CXTypeKind.CXType_Record:
      // Other templates would need their arguments spelled.
      spelling = clang.clang_Type_getNumTemplateArguments(canonical) > 0
          ? null
          : _qualifiedSpelling(clang.clang_getTypeDeclaration(cxtype));
    case clang_types.CXTypeKind.CXType_Enum:
      spelling = _qualifiedSpelling(clang.clang_getTypeDeclaration(cxtype));
    case clang_types.CXTypeKind.CXType_Unexposed:
      // A typedef named through a using-declaration, like `std::size_t` on
      // MSVC, which libclang exposes with no declaration, so only its
      // spelling as written is known. That spelling is kept for the standard
      // library's typedefs, which are declared at global or `std` scope.
      spelling = _standardTypedef(cxtype)?.spelling ?? _builtinSpelling(cxtype);
    default:
      spelling = _builtinSpelling(cxtype);
  }
  if (spelling == null) return null;
  return cxtype.isConstQualified && !spelling.startsWith('const ')
      ? 'const $spelling'
      : spelling;
}

/// The fully qualified name of the declaration [decl], or null if it isn't
/// declared in a scope that the glue can name, like a class template or a
/// function, or is a member of a class that isn't public.
String? _qualifiedSpelling(clang_types.CXCursor decl) {
  final name = decl.spelling();
  if (name.isEmpty || clang.clang_Cursor_isAnonymous(decl) != 0) return null;
  clang_types.CXCursor parentOf(clang_types.CXCursor cursor) =>
      clang.clang_getCursorSemanticParent(cursor);
  // The translation unit is the only scope without a semantic parent.
  for (
    var member = decl, parent = parentOf(decl);
    clang.clang_Cursor_isNull(parentOf(parent)) == 0;
    member = parent, parent = parentOf(parent)
  ) {
    switch (parent.kind) {
      case clang_types.CXCursorKind.CXCursor_Namespace:
        if (parent.spelling().isEmpty) return null;
      case clang_types.CXCursorKind.CXCursor_LinkageSpec:
        break;
      // The glue can only name the public members of a class.
      case clang_types.CXCursorKind.CXCursor_StructDecl ||
          clang_types.CXCursorKind.CXCursor_ClassDecl ||
          clang_types.CXCursorKind.CXCursor_UnionDecl:
        if (clang.clang_getCXXAccessSpecifier(member) !=
            clang_types.CX_CXXAccessSpecifier.CX_CXXPublic) {
          return null;
        }
      default:
        return null;
    }
  }
  return qualifiedNameFromCursor(decl, name);
}

/// The standard library's typedefs of integer types, which the C++ glue
/// spells by name, and the Dart bindings map by name, if they can, since the
/// types they stand for differ between platforms.
const _standardTypedefNames = {
  'size_t',
  'ptrdiff_t',
  'intptr_t',
  'uintptr_t',
  'intmax_t',
  'uintmax_t',
  'int8_t',
  'int16_t',
  'int32_t',
  'int64_t',
  'uint8_t',
  'uint16_t',
  'uint32_t',
  'uint64_t',
};

/// Matches a spelling like `const std::size_t`, capturing it without `const`,
/// and the name, `size_t`.
final _standardTypedefPattern = RegExp(r'^(?:const )?((?:std::)?(\w+))$');

/// The spelling of [cxtype] without `const`, and its name, if it's one of
/// [_standardTypedefNames], and stands for a builtin type, or null
/// otherwise.
({String spelling, String name})? _standardTypedef(clang_types.CXType cxtype) {
  final match = _standardTypedefPattern.firstMatch(cxtype.spelling());
  if (match == null ||
      !_standardTypedefNames.contains(match[2]) ||
      _builtinSpelling(cxtype) == null) {
    return null;
  }
  return (spelling: match[1]!, name: match[2]!);
}

/// The spelling of the canonical type of [cxtype] if it's a builtin type,
/// like `unsigned int`, or null otherwise.
String? _builtinSpelling(clang_types.CXType cxtype) {
  final canonical = clang.clang_getCanonicalType(cxtype);
  if (canonical.kind < clang_types.CXTypeKind.CXType_FirstBuiltin ||
      canonical.kind > clang_types.CXTypeKind.CXType_LastBuiltin ||
      canonical.kind == clang_types.CXTypeKind.CXType_Void) {
    return null;
  }
  final spelling = canonical.spelling();
  return spelling.startsWith('const ') ? spelling.substring(6) : spelling;
}

// Used for function pointer arguments.
Type _extractFromFunctionProto(
  Context context,
  clang_types.CXType cxtype, {
  clang_types.CXCursor? cursor,
}) {
  final parameters = <Parameter>[];
  final totalArgs = clang.clang_getNumArgTypes(cxtype);
  for (var i = 0; i < totalArgs; i++) {
    final t = clang.clang_getArgType(cxtype, i);
    final pt = getCodeGenType(context, t);

    if (pt.isIncompleteCompound) {
      return UnimplementedType(
        'Incomplete Struct by value in function parameter.',
      );
    } else if (pt.baseType is UnimplementedType) {
      return UnimplementedType('Function parameter has an unsupported type.');
    }

    parameters.add(Parameter(name: '', type: pt, objCConsumed: false));
  }

  final functionType = FunctionType(
    parameters: parameters,
    returnType: clang.clang_getResultType(cxtype).toCodeGenType(context),
  );
  _parseAndMergeParamNames(context, functionType, cursor, maxRecursionDepth);
  return NativeFunc(functionType);
}

void _parseAndMergeParamNames(
  Context context,
  FunctionType functionType,
  clang_types.CXCursor? cursor,
  int recursionDepth,
) {
  if (cursor == null) {
    return;
  }
  if (recursionDepth == 0) {
    final cursorRepr = cursor.completeStringRepr();
    context.logger.warning(
      'Recursion depth exceeded when merging function parameters.'
      ' Last cursor encountered was $cursorRepr',
    );
    return;
  }

  final paramsInfo = parseFunctionPointerParamNames(cursor);
  functionType.addParameterNames(paramsInfo.paramNames);

  for (final param in functionType.parameters) {
    final paramRealType = param.type.typealiasType;
    final paramBaseType = paramRealType.baseType.typealiasType;
    if (paramBaseType is NativeFunc && param.originalName.isNotEmpty) {
      final paramFunctionType = paramBaseType.type;
      final paramCursor = paramsInfo.params[param.originalName];
      _parseAndMergeParamNames(
        context,
        paramFunctionType,
        paramCursor,
        recursionDepth - 1,
      );
    }
  }
}
