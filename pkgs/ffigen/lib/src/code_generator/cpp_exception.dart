// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../code_generator.dart';
import '../context.dart';
import '../visitor/ast.dart';

import 'binding_string.dart';
import 'scope.dart';
import 'utils.dart';
import 'writer.dart';

/// Carries the C++ exceptions that the glue catches over to Dart, when
/// `Cpp.catchExceptions` is set.
///
/// A glue function that catches an exception stores its `what()` in a thread
/// local and returns a value-initialized result. The Dart side checks for a
/// stored exception right after each glue call, on the same thread, and
/// rethrows it as a [exceptionClass].
///
/// Generated once per library, if it has any C++ class bindings.
class CppExceptionHelpers extends NoLookUpBinding {
  /// Prefix for the native symbols of the helpers, unique to the library like
  /// the `std::string` helpers' one.
  final String _nativePrefix;

  /// The generated Dart exception class.
  final exceptionClass = Symbol('CppException', SymbolKind.klass);

  /// Throws the exception the last glue call on this thread caught, if any.
  final check = Symbol('_cppCheckException', SymbolKind.method);

  final _take = Symbol('_cppTakeException', SymbolKind.method);
  final _free = Symbol('_cppFreeException', SymbolKind.method);

  CppExceptionHelpers(Context context)
    : _nativePrefix =
          'ffigen_${CppStdStringHelpers.libraryId(context.config)}_exception',
      super(
        originalName: 'C++ exception',
        symbol: Symbol('_cppChecked', SymbolKind.method),
        isInternal: true,
      );

  /// Returns its argument, the result of a glue call, after throwing the
  /// exception that call caught, if any.
  Symbol get checked => symbol;

  /// The C++ function that stores a caught exception's message.
  String get _cppSetter => '${_nativePrefix}_set';

  /// The C++ function the glue calls in a `catch (...)` block, which rethrows
  /// the exception to hand its message to [_cppSetter].
  String get _cppCatch => '${_nativePrefix}_catch';

  @override
  BindingString toBindingString(Writer w) {
    final ffi = w.context.libs.prefix(ffiImport);
    final convert = w.context.libs.prefix(convertImport);
    final ptrUint8 = '$ffi.Pointer<$ffi.Uint8>';
    final className = exceptionClass.name;
    if (className != exceptionClass.oldName) {
      w.context.logger.warning(
        'The C++ exception class is generated as $className, since another '
        'binding is named ${exceptionClass.oldName}. Rename that binding to '
        'keep the name ${exceptionClass.oldName}.',
      );
    }

    final s = StringBuffer();
    s.write('''
/// A C++ exception thrown by a C++ method or constructor, which the generated
/// glue caught and rethrew in Dart.
class $className implements Exception {
  /// The exception's `what()`, or a description of the exception if it isn't
  /// a `std::exception`.
  final String message;

  $className(this.message);

  @override
  String toString() => '${className.replaceAll(r'$', r'\$')}: \$message';
}

/// Throws the C++ exception that the last glue call on this thread caught, if
/// any, as a [$className].
void ${check.name}() {
  final exception = ${_take.name}();
  if (exception == $ffi.nullptr) return;
  final String message;
  try {
    var length = 0;
    while (exception[length] != 0) {
      length++;
    }
    message = $convert.utf8.decode(
      exception.asTypedList(length),
      allowMalformed: true,
    );
  } finally {
    ${_free.name}(exception);
  }
  throw $className(message);
}

/// Returns [result], after throwing the C++ exception that the glue call
/// returning it caught, if any.
T ${checked.name}<T>(T result) {
  ${check.name}();
  return result;
}

''');

    s.write(
      makeNativeHelperDeclaration(
        w,
        dartName: _take.name,
        nativeSymbolName: '${_nativePrefix}_take',
        returnType: ptrUint8,
        nativeReturnType: ptrUint8,
        isLeaf: true,
      ),
    );
    s.write(
      makeNativeHelperDeclaration(
        w,
        dartName: _free.name,
        nativeSymbolName: '${_nativePrefix}_free',
        returnType: 'void',
        nativeReturnType: '$ffi.Void',
        params: [(ptrUint8, ptrUint8, 'exception')],
        isLeaf: true,
      ),
    );

    return BindingString(type: BindingStringType.func, string: s.toString());
  }

  /// The C++ side, written before the glue's `extern "C"` block, since the
  /// glue functions call [_cppCatch].
  ///
  /// The message is copied with `malloc`, so a failure to allocate it can't
  /// throw from within a `catch` block. If it does fail, the exception is
  /// still reported, with a fixed message. So is an exception whose `what()`
  /// returns null.
  String cppSupport() =>
      '''
static thread_local char* ${_nativePrefix}_pending = nullptr;
static char ${_nativePrefix}_out_of_memory[] =
    "out of memory while copying a C++ exception's message";

static void $_cppSetter(const char* what) noexcept {
  if (${_nativePrefix}_pending != ${_nativePrefix}_out_of_memory) {
    std::free(${_nativePrefix}_pending);
  }
  if (what == nullptr) what = "a std::exception whose what() is null";
  const std::size_t size = std::strlen(what) + 1;
  auto* copy = static_cast<char*>(std::malloc(size));
  if (copy == nullptr) {
    ${_nativePrefix}_pending = ${_nativePrefix}_out_of_memory;
    return;
  }
  std::memcpy(copy, what, size);
  ${_nativePrefix}_pending = copy;
}

static void $_cppCatch() noexcept {
  try {
    throw;
  } catch (const std::exception& e) {
    $_cppSetter(e.what());
  } catch (...) {
    $_cppSetter("a C++ exception that isn't a std::exception");
  }
}

extern "C" {

FFIGEN_EXPORT char* ${_nativePrefix}_take() {
  char* exception = ${_nativePrefix}_pending;
  ${_nativePrefix}_pending = nullptr;
  return exception;
}

FFIGEN_EXPORT void ${_nativePrefix}_free(char* exception) {
  if (exception != ${_nativePrefix}_out_of_memory) std::free(exception);
}

}

''';

  /// Wraps the statement of a glue function's [body] in a `try` block that
  /// hands a caught exception to [_cppCatch], followed by a value-initialized
  /// return if [returnsValue].
  ///
  /// [guard], the declaration of the `Cpp.glueGuard`, if any, goes in an
  /// outer `try` block, so that an exception from its constructor is caught
  /// too. The inner one catches the call's exceptions within the guard's
  /// scope, so the guard is destroyed by leaving that scope rather than by
  /// stack unwinding, which MSVC skips without `/EHsc`.
  String wrapGlueBody(
    String body, {
    required bool returnsValue,
    required String? guard,
  }) {
    String tryCatch(String body, String indent) =>
        '''
try {
$indent  $body
$indent} catch (...) {
$indent  $_cppCatch();
$indent}''';
    final wrapped = guard == null
        ? tryCatch(body, '  ')
        : tryCatch('$guard\n    ${tryCatch(body, '    ')}', '  ');
    return returnsValue ? '$wrapped\n  return {};' : wrapped;
  }

  @override
  bool get hasNativeHelperFunctions => true;

  @override
  void visitChildren(Visitor visitor) {
    super.visitChildren(visitor);
    visitor.visit(exceptionClass);
    visitor.visit(check);
    visitor.visit(_take);
    visitor.visit(_free);
    visitor.visit(ffiImport);
    visitor.visit(convertImport);
  }
}
