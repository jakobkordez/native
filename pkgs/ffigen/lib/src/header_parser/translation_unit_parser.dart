// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../code_generator.dart';
import '../context.dart';
import 'clang_bindings/clang_bindings.dart' as clang_types;
import 'sub_parsers/classdecl_parser.dart';
import 'sub_parsers/functiondecl_parser.dart';
import 'sub_parsers/macro_parser.dart';
import 'sub_parsers/objccategorydecl_parser.dart';
import 'sub_parsers/objcprotocoldecl_parser.dart';
import 'sub_parsers/var_parser.dart';
import 'type_extractor/extractor.dart';
import 'utils.dart';

/// Parses the translation unit and returns the generated bindings.
Set<Binding> parseTranslationUnit(
  Context context,
  clang_types.CXCursor translationUnitCursor,
) {
  final bindings = <Binding>{};
  final logger = context.logger;
  final headers = <String, bool>{};

  translationUnitCursor.visitChildren((cursor) {
    final file = cursor.sourceFileName();
    if (file.isEmpty) return;
    if (headers[file] ??= context.config.input.include(Uri.file(file))) {
      try {
        logger.finest('rootCursorVisitor: ${cursor.completeStringRepr()}');
        switch (clang.clang_getCursorKind(cursor)) {
          case clang_types.CXCursorKind.CXCursor_FunctionDecl:
            addToBindings(bindings, parseFunctionDeclaration(context, cursor));
            break;
          case clang_types.CXCursorKind.CXCursor_UnionDecl:
          case clang_types.CXCursorKind.CXCursor_StructDecl:
            addToBindings(bindings, _getCodeGenTypeFromCursor(context, cursor));
            _visitRecordForEnums(context, cursor, bindings, headers);
            break;
          case clang_types.CXCursorKind.CXCursor_EnumDecl:
          case clang_types.CXCursorKind.CXCursor_ObjCInterfaceDecl:
          case clang_types.CXCursorKind.CXCursor_TypedefDecl:
            addToBindings(bindings, _getCodeGenTypeFromCursor(context, cursor));
            break;
          case clang_types.CXCursorKind.CXCursor_ObjCCategoryDecl:
            addToBindings(
              bindings,
              parseObjCCategoryDeclaration(context, cursor),
            );
            break;
          case clang_types.CXCursorKind.CXCursor_ObjCProtocolDecl:
            addToBindings(
              bindings,
              parseObjCProtocolDeclaration(context, cursor),
            );
            break;
          case clang_types.CXCursorKind.CXCursor_MacroDefinition:
            saveMacroDefinition(context, cursor);
            break;
          case clang_types.CXCursorKind.CXCursor_VarDecl:
            addToBindings(bindings, parseVarDeclaration(context, cursor));
            break;
          case clang_types.CXCursorKind.CXCursor_ClassDecl:
            addToBindings(bindings, parseClassDeclaration(context, cursor));
            _visitRecordForEnums(context, cursor, bindings, headers);
            break;
          case clang_types.CXCursorKind.CXCursor_Namespace:
            _visitNamespaceForEnums(context, cursor, bindings, headers);
            break;
          default:
            logger.finer('rootCursorVisitor: CursorKind not implemented');
        }
      } catch (e, s) {
        logger.severe(e);
        logger.severe(s);
        rethrow;
      }
    } else {
      logger.finest(
        'rootCursorVisitor:(not included) ${cursor.completeStringRepr()}',
      );
    }
  });

  return bindings;
}

/// Adds to binding if unseen and not null.
void addToBindings(Set<Binding> bindings, Binding? b) {
  if (b != null) {
    // This is a set, and hence will not have duplicates.
    bindings.add(b);
  }
}

/// Recurses into a C++ namespace, surfacing only enum declarations.
///
/// For now this is the only declaration kind generated from inside namespaces.
// TODO: Dispatch ClassDecl, FunctionDecl, etc. here for full C++ namespace
// support. Class declarations are currently visited only to find nested enums.
void _visitNamespaceForEnums(
  Context context,
  clang_types.CXCursor namespaceCursor,
  Set<Binding> bindings,
  Map<String, bool> headers,
) {
  final logger = context.logger;
  if (clang.clang_Cursor_isAnonymous(namespaceCursor) != 0) {
    logger.fine('Skipping anonymous namespace.');
    return;
  }
  _visitChildrenForNestedEnums(context, namespaceCursor, bindings, headers);
}

/// Recurses into a C++ record to surface enum declarations nested inside it.
void _visitRecordForEnums(
  Context context,
  clang_types.CXCursor recordCursor,
  Set<Binding> bindings,
  Map<String, bool> headers,
) {
  final logger = context.logger;
  if (clang.clang_Cursor_isAnonymous(recordCursor) != 0) {
    logger.fine('Skipping anonymous record.');
    return;
  }
  _visitChildrenForNestedEnums(context, recordCursor, bindings, headers);
}

void _visitChildrenForNestedEnums(
  Context context,
  clang_types.CXCursor parentCursor,
  Set<Binding> bindings,
  Map<String, bool> headers,
) {
  final logger = context.logger;
  parentCursor.visitChildren((cursor) {
    final kind = clang.clang_getCursorKind(cursor);
    if (!_isNestedEnumScope(kind)) {
      // Bail out before logging anything: `completeStringRepr` computes the
      // cursor's USR, which isn't meaningful for every kind found inside a
      // namespace or record (e.g. destructors).
      logger.finer('nestedEnumCursorVisitor: CursorKind not implemented');
      return;
    }
    final file = cursor.sourceFileName();
    if (file.isEmpty) return;
    if (!(headers[file] ??= context.config.input.include(Uri.file(file)))) {
      logger.finest(
        'nestedEnumCursorVisitor:(not included) ${cursor.completeStringRepr()}',
      );
      return;
    }
    try {
      logger.finest('nestedEnumCursorVisitor: ${cursor.completeStringRepr()}');
      switch (kind) {
        case clang_types.CXCursorKind.CXCursor_Namespace:
          _visitNamespaceForEnums(context, cursor, bindings, headers);
          break;
        case clang_types.CXCursorKind.CXCursor_UnionDecl:
        case clang_types.CXCursorKind.CXCursor_ClassDecl:
        case clang_types.CXCursorKind.CXCursor_StructDecl:
          _visitRecordForEnums(context, cursor, bindings, headers);
          break;
        case clang_types.CXCursorKind.CXCursor_EnumDecl:
          addToBindings(bindings, _getCodeGenTypeFromCursor(context, cursor));
          break;
      }
    } catch (e, s) {
      logger.severe(e);
      logger.severe(s);
      rethrow;
    }
  });
}

/// Whether [_visitChildrenForNestedEnums] descends into cursors of [kind], or
/// generates bindings for them.
bool _isNestedEnumScope(int kind) => switch (kind) {
  clang_types.CXCursorKind.CXCursor_Namespace ||
  clang_types.CXCursorKind.CXCursor_UnionDecl ||
  clang_types.CXCursorKind.CXCursor_ClassDecl ||
  clang_types.CXCursorKind.CXCursor_StructDecl ||
  clang_types.CXCursorKind.CXCursor_EnumDecl => true,
  _ => false,
};

BindingType? _getCodeGenTypeFromCursor(
  Context context,
  clang_types.CXCursor cursor,
) {
  final t = getCodeGenType(context, cursor.type());
  return t is BindingType ? t : null;
}

/// Visits all cursors and builds a map of usr and [clang_types.CXCursor].
void buildUsrCursorDefinitionMap(
  Context context,
  clang_types.CXCursor translationUnitCursor,
) {
  final logger = context.logger;
  translationUnitCursor.visitChildren((cursor) {
    try {
      context.cursorIndex.saveDefinition(cursor);
    } catch (e, s) {
      logger.severe(e);
      logger.severe(s);
      rethrow;
    }
  });
}
