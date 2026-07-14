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

  void rootCursorVisitor(clang_types.CXCursor cursor) {
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
            _visitRecordForNestedDecls(context, cursor, bindings, headers);
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
            _visitRecordForNestedDecls(context, cursor, bindings, headers);
            break;
          case clang_types.CXCursorKind.CXCursor_Namespace:
            _visitNamespaceForNestedDecls(context, cursor, bindings, headers);
            break;
          case clang_types.CXCursorKind.CXCursor_LinkageSpec:
            // Declarations inside `extern "C" { ... }` blocks are wrapped in
            // a LinkageSpec cursor when parsing in C++ mode. Recurse into it
            // so they're dispatched like top-level declarations.
            cursor.visitChildren(rootCursorVisitor);
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
  }

  translationUnitCursor.visitChildren(rootCursorVisitor);

  return bindings;
}

/// Adds to binding if unseen and not null.
void addToBindings(Set<Binding> bindings, Binding? b) {
  if (b != null) {
    // This is a set, and hence will not have duplicates.
    bindings.add(b);
  }
}

/// Recurses into a C++ namespace, surfacing enum, struct and union
/// declarations.
///
/// For now these are the only declaration kinds generated from inside
/// namespaces.
// TODO: Dispatch ClassDecl, FunctionDecl, etc. here for full C++ namespace
// support. Class declarations are currently visited only to find nested
// enums, structs and unions.
void _visitNamespaceForNestedDecls(
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
  _visitChildrenForNestedDecls(context, namespaceCursor, bindings, headers);
}

/// Recurses into a C++ record to surface enum, struct and union declarations
/// nested inside it.
void _visitRecordForNestedDecls(
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
  _visitChildrenForNestedDecls(context, recordCursor, bindings, headers);
}

void _visitChildrenForNestedDecls(
  Context context,
  clang_types.CXCursor parentCursor,
  Set<Binding> bindings,
  Map<String, bool> headers,
) {
  final logger = context.logger;
  parentCursor.visitChildren((cursor) {
    final kind = clang.clang_getCursorKind(cursor);
    if (!_isNestedDeclScope(kind)) {
      // Bail out before logging anything: `completeStringRepr` computes the
      // cursor's USR, which isn't meaningful for every kind found inside a
      // namespace or record (e.g. destructors).
      logger.finer('nestedDeclCursorVisitor: CursorKind not implemented');
      return;
    }
    final file = cursor.sourceFileName();
    if (file.isEmpty) return;
    if (!(headers[file] ??= context.config.input.include(Uri.file(file)))) {
      logger.finest(
        'nestedDeclCursorVisitor:(not included) ${cursor.completeStringRepr()}',
      );
      return;
    }
    try {
      logger.finest('nestedDeclCursorVisitor: ${cursor.completeStringRepr()}');
      switch (kind) {
        case clang_types.CXCursorKind.CXCursor_Namespace:
          _visitNamespaceForNestedDecls(context, cursor, bindings, headers);
          break;
        case clang_types.CXCursorKind.CXCursor_LinkageSpec:
          // Recurse into `extern "C" { ... }` blocks.
          _visitChildrenForNestedDecls(context, cursor, bindings, headers);
          break;
        case clang_types.CXCursorKind.CXCursor_UnionDecl:
        case clang_types.CXCursorKind.CXCursor_StructDecl:
          // Anonymous records are handled as members of their parent record,
          // not as top-level bindings.
          if (clang.clang_Cursor_isAnonymous(cursor) == 0 &&
              _isIncludedCompound(context, cursor, kind)) {
            addToBindings(bindings, _getCodeGenTypeFromCursor(context, cursor));
          }
          _visitRecordForNestedDecls(context, cursor, bindings, headers);
          break;
        case clang_types.CXCursorKind.CXCursor_ClassDecl:
          _visitRecordForNestedDecls(context, cursor, bindings, headers);
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

/// Whether the nested struct or union at [cursor] may be parsed at all.
///
/// Unlike the visitor filters that run after parsing, this check happens up
/// front, because parsing a record also parses its methods and every type they
/// mention. A record nested in an included system header (`std::` and friends)
/// would drag in an unbounded amount of the C++ standard library, so nested
/// records in system headers are never parsed. (Inclusion itself moved to the
/// AST visitors, which cannot run this early — this location check preserves
/// the old `config.structs.include(...)` guard's intent without a config
/// query.) Enums are leaves, so they don't need the same treatment.
bool _isIncludedCompound(
  Context context,
  clang_types.CXCursor cursor,
  int kind,
) {
  return !cursor.isInSystemHeader();
}

/// Whether [_visitChildrenForNestedDecls] descends into cursors of [kind], or
/// generates bindings for them.
bool _isNestedDeclScope(int kind) => switch (kind) {
  clang_types.CXCursorKind.CXCursor_Namespace ||
  clang_types.CXCursorKind.CXCursor_LinkageSpec ||
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
  void visitor(clang_types.CXCursor cursor) {
    try {
      if (clang.clang_getCursorKind(cursor) ==
          clang_types.CXCursorKind.CXCursor_LinkageSpec) {
        // Declarations inside `extern "C" { ... }` blocks are wrapped in a
        // LinkageSpec cursor when parsing in C++ mode.
        cursor.visitChildren(visitor);
      } else {
        context.cursorIndex.saveDefinition(cursor);
      }
    } catch (e, s) {
      logger.severe(e);
      logger.severe(s);
      rethrow;
    }
  }

  translationUnitCursor.visitChildren(visitor);
}
