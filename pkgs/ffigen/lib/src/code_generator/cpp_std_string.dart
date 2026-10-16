// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;

import '../code_generator.dart';
import '../config_provider/config.dart';
import '../context.dart';
import '../visitor/ast.dart';

import 'binding_string.dart';
import 'local_variables.dart';
import 'scope.dart';
import 'utils.dart';
import 'writer.dart';

/// A C++ `std::string`, which Dart code sees as a [String].
///
/// Only C++ methods and constructors can take or return one, because the
/// conversion happens in their generated C++ glue: a `std::string` crosses the
/// `extern "C"` boundary as an owned `std::string*`, which [helpers] convert
/// to and from a Dart [String], as UTF-8.
///
/// The same type stands for a `std::string` passed by value or by a const or
/// rvalue reference, since the glue converts all of them the same way.
class CppStdStringType extends Type {
  final CppStdStringHelpers helpers;

  CppStdStringType(Context context) : helpers = CppStdStringHelpers(context);

  @override
  String getCType(Context context) {
    final ffi = context.libs.prefix(ffiImport);
    return '$ffi.Pointer<$ffi.Void>';
  }

  @override
  String getDartType(Context context) => 'String';

  @override
  String getNativeType(Context context, {String varName = ''}) =>
      'std::string $varName';

  @override
  String getExternCType(Context context, {String varName = ''}) =>
      'std::string* $varName';

  @override
  bool get sameNativeAndExternCType => false;

  // The argument is a temporary that the Dart side deletes after the call, so
  // it can be moved from.
  @override
  String convertExternCTypeToNativeType(Context context, String value) =>
      'std::move(*$value)';

  @override
  String convertNativeTypeToExternCType(Context context, String value) =>
      'new std::string($value)';

  @override
  bool get sameFfiDartAndCType => true;

  @override
  bool get sameDartAndCType => false;

  @override
  bool get sameDartAndFfiDartType => false;

  @override
  String convertDartTypeToFfiDartType(
    Context context,
    String value, {
    required bool objCRetain,
    required bool objCAutorelease,
    required LocalVariables localVariables,
  }) => localVariables.addVariable(
    value,
    '${helpers.fromDart.name}($value)',
    cleanup: (name) => '${helpers.delete.name}($name);',
  );

  @override
  String convertFfiDartTypeToDartType(
    Context context,
    String value, {
    required bool objCRetain,
    String? objCEnclosingClass,
  }) => '${helpers.toDart.name}($value)';

  @override
  String toString() => 'std::string';

  @override
  String cacheKey() => 'std::string';

  @override
  void visitChildren(Visitor visitor) {
    super.visitChildren(visitor);
    visitor.visit(helpers);
    visitor.visit(ffiImport);
  }
}

/// Converts between Dart [String]s and natively allocated `std::string`s.
///
/// Generated once per library, if any of its bindings use a
/// [CppStdStringType].
class CppStdStringHelpers extends NoLookUpBinding {
  /// Prefix for the native symbols of the helpers.
  ///
  /// Every library's C++ glue defines the helpers, and the glue of several
  /// libraries may be linked into one dynamic library, so the prefix is unique
  /// to the library.
  final String _nativePrefix;

  /// Copies a Dart [String] into a new `std::string`.
  final fromDart = Symbol('_stdStringFromDart', SymbolKind.method);

  /// Deletes a `std::string`.
  final delete = Symbol('_stdStringDelete', SymbolKind.method);

  final _new = Symbol('_stdStringNew', SymbolKind.method);
  final _data = Symbol('_stdStringData', SymbolKind.method);
  final _size = Symbol('_stdStringSize', SymbolKind.method);

  CppStdStringHelpers(Context context)
    : _nativePrefix = 'ffigen_${libraryId(context.config)}_std_string',
      super(
        originalName: 'std::string',
        symbol: Symbol('_stdStringToDart', SymbolKind.method),
        isInternal: true,
      );

  /// Copies a `std::string` into a Dart [String], and deletes it.
  Symbol get toDart => symbol;

  /// A unique (but not human readable) ID for the generated library, based on
  /// a hash of parts of the config, to prefix the native symbols of helpers
  /// that every library's glue defines.
  static String libraryId(FfiGenerator config) => fnvHash32(
    [
      ...config.input.entryPoints,
      config.output.dart.path,
      config.output.cppBindingsFile,
    ].map((uri) => path.basename(uri.toFilePath())).join('\n'),
  ).toRadixString(36);

  @override
  BindingString toBindingString(Writer w) {
    final ffi = w.context.libs.prefix(ffiImport);
    final convert = w.context.libs.prefix(convertImport);
    final ptrVoid = '$ffi.Pointer<$ffi.Void>';
    final ptrUint8 = '$ffi.Pointer<$ffi.Uint8>';

    final s = StringBuffer();
    s.write('''
/// Copies [value] into a new `std::string`, encoded as UTF-8.
///
/// The `std::string` must be deleted with [${delete.name}].
$ptrVoid ${fromDart.name}(String value) {
  final bytes = $convert.utf8.encode(value);
  return ${_new.name}(bytes.address, bytes.length);
}

/// Copies the `std::string` [value] into a [String], decoding it as UTF-8, and
/// deletes [value].
String ${toDart.name}($ptrVoid value) {
  try {
    final bytes = ${_data.name}(value).asTypedList(${_size.name}(value));
    return $convert.utf8.decode(bytes);
  } finally {
    ${delete.name}(value);
  }
}

''');

    // The helpers are trivial and never call back into Dart, so they are leaf
    // calls. That also lets [fromDart] pass its bytes without copying them.
    void writeNative(
      Symbol dartSymbol,
      String nativeSuffix, {
      required String returnType,
      required String nativeReturnType,
      required List<(String, String, String)> params,
    }) => s.write(
      makeNativeHelperDeclaration(
        w,
        dartName: dartSymbol.name,
        nativeSymbolName: '${_nativePrefix}_$nativeSuffix',
        returnType: returnType,
        nativeReturnType: nativeReturnType,
        params: params,
        isLeaf: true,
      ),
    );

    writeNative(
      _new,
      'new',
      returnType: ptrVoid,
      nativeReturnType: ptrVoid,
      params: [(ptrUint8, ptrUint8, 'data'), ('$ffi.Size', 'int', 'size')],
    );
    writeNative(
      _data,
      'data',
      returnType: ptrUint8,
      nativeReturnType: ptrUint8,
      params: [(ptrVoid, ptrVoid, 'value')],
    );
    writeNative(
      _size,
      'size',
      returnType: 'int',
      nativeReturnType: '$ffi.Size',
      params: [(ptrVoid, ptrVoid, 'value')],
    );
    writeNative(
      delete,
      'delete',
      returnType: 'void',
      nativeReturnType: '$ffi.Void',
      params: [(ptrVoid, ptrVoid, 'value')],
    );

    return BindingString(type: BindingStringType.func, string: s.toString());
  }

  @override
  String toCppBindingString(Writer w) =>
      '''
FFIGEN_EXPORT std::string* ${_nativePrefix}_new(const char* data, std::size_t size) {
  return new std::string(data, size);
}

FFIGEN_EXPORT const char* ${_nativePrefix}_data(const std::string* value) {
  return value->data();
}

FFIGEN_EXPORT std::size_t ${_nativePrefix}_size(const std::string* value) {
  return value->size();
}

FFIGEN_EXPORT void ${_nativePrefix}_delete(std::string* value) {
  delete value;
}

''';

  @override
  bool get hasNativeHelperFunctions => true;

  @override
  void visitChildren(Visitor visitor) {
    super.visitChildren(visitor);
    visitor.visit(fromDart);
    visitor.visit(delete);
    visitor.visit(_new);
    visitor.visit(_data);
    visitor.visit(_size);
    visitor.visit(ffiImport);
    visitor.visit(convertImport);
  }
}
