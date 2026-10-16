// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../code_generator.dart';
import '../context.dart';
import '../visitor/ast.dart';

import 'binding_string.dart';
import 'local_variables.dart';
import 'scope.dart';
import 'utils.dart';
import 'writer.dart';

/// A C++ `std::vector<T>`, which Dart code sees as a [List] of the Dart type
/// of `T`.
///
/// Only C++ methods and constructors can take or return one, because the
/// conversion happens in their generated C++ glue: a `std::vector` crosses
/// the `extern "C"` boundary as an owned `std::vector*`, which [helpers] copy
/// to and from a Dart [List], element by element.
///
/// The same type stands for a `std::vector` passed by value or by a const or
/// rvalue reference, since the glue converts all of them the same way.
///
/// The elements are converted like a parameter or return value of their own
/// type: numbers, enums, `std::string`s, pointers and `std::unique_ptr`s to
/// C++ classes, C++ classes by value (as copies the Dart objects own), POD
/// structs, and nested `std::vector`s. Pointers to C++ classes that a method
/// returns are borrowed from the object it was called on, like a returned
/// pointer.
class CppStdVectorType extends Type {
  /// The element type.
  final Type element;

  /// The C++ spelling of the element type, as the glue writes it.
  ///
  /// It keeps typedef names like `std::size_t`, since the type they stand for
  /// differs between platforms, and a `std::vector` of one isn't a
  /// `std::vector` of the other.
  final String elementSpelling;

  /// Whether the element type is a pointer to const, like `const T*` or
  /// `std::unique_ptr<const T>`, which the glue returns as a pointer to
  /// non-const.
  final bool elementIsPointerToConst;

  late final CppStdVectorHelpers helpers;

  /// Whether a C++ method or constructor takes this type as a parameter, so
  /// that [helpers] have to copy Dart [List]s into vectors of it, see
  /// [markPassedFromDart].
  bool get isPassedFromDart => _isPassedFromDart;
  bool _isPassedFromDart = false;

  CppStdVectorType(
    Context context, {
    required this.element,
    required this.elementSpelling,
    required this.elementIsPointerToConst,
  }) {
    helpers = CppStdVectorHelpers(context, this);
  }

  /// The C++ spelling of this type.
  String get cppSpelling => 'std::vector<$elementSpelling>';

  /// Marks this type as [isPassedFromDart], and so the types of nested
  /// vectors, which are copied from Dart too.
  void markPassedFromDart() {
    _isPassedFromDart = true;
    if (element.typealiasType case final CppStdVectorType vector) {
      vector.markPassedFromDart();
    }
  }

  /// Whether the elements are pointers to C++ objects that the vector
  /// doesn't own.
  ///
  /// The Dart objects for the elements of a vector that a method returns
  /// borrow their pointers from the object it was called on, like a returned
  /// pointer. The objects of a vector passed to C++ are kept from being
  /// garbage collected until the call returns.
  bool get borrowsElements => switch (element.typealiasType) {
    CppUniquePtrType() => false,
    CppClassPointerType() => true,
    final CppStdVectorType vector => vector.borrowsElements,
    _ => false,
  };

  /// Whether the elements are `std::unique_ptr`s, whose objects move their
  /// ownership between Dart and C++.
  ///
  /// The objects of a vector passed to C++ keep their ownership until the
  /// call returns. Then the ones whose `std::unique_ptr` C++ took out of the
  /// vector give it to C++, see [CppStdVectorHelpers.reclaim].
  bool get movesElements => element.typealiasType is CppUniquePtrType;

  /// Whether the vector can be copied, which the glue does to return a
  /// reference to one.
  ///
  /// A `std::unique_ptr`, or a C++ class without a usable copy constructor,
  /// can only be moved.
  bool get isCopyable => switch (element.typealiasType) {
    CppUniquePtrType() => false,
    final CppClass cppClass => cppClass.isCopyable,
    final CppStdVectorType vector => vector.isCopyable,
    _ => true,
  };

  /// Whether a Dart [List] can be copied into the vector, to pass it to C++.
  ///
  /// The elements are copied, except `std::unique_ptr`s, see [movesElements].
  /// Only a vector of those can return the ownership of the objects that C++
  /// didn't take, not a vector of vectors of them.
  bool get canPassFromDart => switch (element.typealiasType) {
    final CppClass cppClass => cppClass.isCopyable,
    final CppStdVectorType vector =>
      vector.canPassFromDart && !vector.movesElements,
    _ => true,
  };

  /// Whether copying or moving an element runs the code of a C++ class, its
  /// copy or move constructor.
  bool get copyingElementsRunsClassCode => element.typealiasType is CppClass;

  /// Whether destroying the elements runs the code of a C++ class, its
  /// destructor.
  bool get destroyingElementsRunsClassCode => switch (element.typealiasType) {
    CppClass() || CppUniquePtrType() => true,
    final CppStdVectorType vector => vector.destroyingElementsRunsClassCode,
    _ => false,
  };

  @override
  String getCType(Context context) {
    final ffi = context.libs.prefix(ffiImport);
    return '$ffi.Pointer<$ffi.Void>';
  }

  @override
  String getDartType(Context context) =>
      'List<${element.getDartType(context)}>';

  @override
  String getNativeType(Context context, {String varName = ''}) =>
      '$cppSpelling $varName';

  @override
  String getExternCType(Context context, {String varName = ''}) =>
      '$cppSpelling* $varName';

  @override
  bool get sameNativeAndExternCType => false;

  // The argument is a temporary that the Dart side deletes after the call, so
  // it can be moved from.
  @override
  String convertExternCTypeToNativeType(Context context, String value) =>
      'std::move(*$value)';

  @override
  String convertNativeTypeToExternCType(Context context, String value) =>
      'new $cppSpelling($value)';

  @override
  bool get sameFfiDartAndCType => true;

  @override
  bool get sameDartAndCType => false;

  @override
  bool get sameDartAndFfiDartType => false;

  // The vector is deleted after the call. Pointers in it borrow from the Dart
  // objects in [value], which are kept alive by holding them in a
  // [CppStdVectorArgument] until then.
  @override
  String convertDartTypeToFfiDartType(
    Context context,
    String value, {
    required bool objCRetain,
    required bool objCAutorelease,
    required LocalVariables localVariables,
  }) {
    final fromDart = '${helpers.fromDart.name}($value)';
    if (movesElements) {
      return localVariables.addVariable(
        value,
        fromDart,
        cleanup: (name) => '${helpers.reclaim.name}($name, $value);',
      );
    }
    if (borrowsElements) {
      final argument = context.cppStdVectorArgument.name;
      final name = localVariables.addVariable(
        value,
        '$argument($fromDart, $value)',
        cleanup: (name) => '${helpers.delete.name}($name.pointer);',
      );
      return '$name.pointer';
    }
    return localVariables.addVariable(
      value,
      fromDart,
      cleanup: (name) => '${helpers.delete.name}($name);',
    );
  }

  @override
  String convertFfiDartTypeToDartType(
    Context context,
    String value, {
    required bool objCRetain,
    String? objCEnclosingClass,
  }) => '${helpers.toDart.name}($value)';

  /// If the elements are pointers to C++ classes, the Dart objects for them
  /// borrow their pointers from the object that [isOwnerAlive] belongs to.
  @override
  String convertReturnedToDartType(
    Context context,
    String value, {
    required String? isOwnerAlive,
  }) => borrowsElements && isOwnerAlive != null
      ? '${helpers.toDart.name}($value, $isOwnerAlive)'
      : '${helpers.toDart.name}($value)';

  @override
  String toString() => 'std::vector<$element>';

  @override
  String cacheKey() => 'std::vector<${element.cacheKey()}>';

  @override
  void visitChildren(Visitor visitor) {
    super.visitChildren(visitor);
    visitor.visit(element);
    visitor.visit(helpers);
    visitor.visit(ffiImport);
  }
}

/// Copies between Dart [List]s and natively allocated `std::vector`s of one
/// element type.
///
/// Generated once per element type, if any of the library's bindings use a
/// [CppStdVectorType] of it.
class CppStdVectorHelpers extends NoLookUpBinding {
  final Context _context;

  final CppStdVectorType vector;

  /// Prefix for the native symbols of the helpers, unique to the library and
  /// the element type, like the `std::string` helpers' one.
  final String _nativePrefix;

  /// Copies a Dart [List] into a new `std::vector`.
  final Symbol fromDart;

  /// Deletes a `std::vector`.
  final Symbol delete;

  /// Deletes a `std::vector` of `std::unique_ptr`s that [fromDart] copied a
  /// [List] into, after passing it to C++.
  ///
  /// The Dart objects whose `std::unique_ptr`s C++ took out of the vector
  /// give their ownership to C++, the others keep it. See
  /// [CppStdVectorType.movesElements].
  final Symbol reclaim;

  final Symbol _new;
  final Symbol _push;
  final Symbol _size;
  final Symbol _get;
  final Symbol _release;

  /// Matches the parts of a C++ type's spelling that [_symbolName] converts.
  static final _spellingTokens = RegExp(r'\w+|::|\*|<');

  CppStdVectorHelpers._(
    this._context,
    this.vector,
    String symbolBase,
    this._nativePrefix,
  ) : fromDart = Symbol('${symbolBase}FromDart', SymbolKind.method),
      delete = Symbol('${symbolBase}Delete', SymbolKind.method),
      reclaim = Symbol('${symbolBase}Reclaim', SymbolKind.method),
      _new = Symbol('${symbolBase}New', SymbolKind.method),
      _push = Symbol('${symbolBase}Push', SymbolKind.method),
      _size = Symbol('${symbolBase}Size', SymbolKind.method),
      _get = Symbol('${symbolBase}Get', SymbolKind.method),
      _release = Symbol('${symbolBase}Release', SymbolKind.method),
      super(
        originalName: vector.cppSpelling,
        symbol: Symbol('${symbolBase}ToDart', SymbolKind.method),
        isInternal: true,
      );

  factory CppStdVectorHelpers(Context context, CppStdVectorType vector) {
    final spelling = vector.cppSpelling;
    return CppStdVectorHelpers._(
      context,
      vector,
      '_stdVectorOf${_symbolName(vector.elementSpelling)}',
      'ffigen_${CppStdStringHelpers.libraryId(context.config)}_std_vector_'
          '${fnvHash32(spelling).toRadixString(36)}',
    );
  }

  /// Copies a `std::vector` into a Dart [List], and deletes it.
  Symbol get toDart => symbol;

  Type get _element => vector.element;

  /// Whether the helpers copying and moving elements catch C++ exceptions.
  bool get _catchesExceptions =>
      vector.copyingElementsRunsClassCode &&
      (_context.config.cpp?.catchExceptions ?? false);

  /// A Dart identifier part naming the C++ type [spelling], like
  /// `ConstMucore$PropertyPtr` for `const mucore::Property*`.
  static String _symbolName(String spelling) {
    final s = StringBuffer();
    for (final token in _spellingTokens.allMatches(spelling)) {
      switch (token[0]!) {
        case '::':
          s.write(r'$');
        case '*':
          s.write('Ptr');
        case '<':
          s.write('Of');
        case final word:
          s.write(word[0].toUpperCase() + word.substring(1));
      }
    }
    return s.toString();
  }

  @override
  BindingString toBindingString(Writer w) {
    final ctx = w.context;
    final ffi = ctx.libs.prefix(ffiImport);
    final ptrVoid = '$ffi.Pointer<$ffi.Void>';
    final dartList = vector.getDartType(ctx);
    final elementFfiDart = _element.getFfiDartType(ctx);
    final cppSpelling = vector.cppSpelling;

    // The helpers' parameters and locals get names that are unique in the
    // library, since the element conversions refer to other bindings, whose
    // names they must not shadow.
    String local(String name) => ctx.rootScope.addPrivate('_$name');

    final s = StringBuffer();

    // toDart.
    {
      final value = local('value');
      final index = local('index');
      final isOwnerAlive = vector.borrowsElements
          ? local('isOwnerAlive')
          : null;
      var ffiElement = '${_get.name}($value, $index)';
      if (_catchesExceptions) {
        ffiElement = '${ctx.cppExceptionHelpers.checked.name}($ffiElement)';
      }
      final element = _element.convertReturnedToDartType(
        ctx,
        ffiElement,
        isOwnerAlive: isOwnerAlive,
      );
      s.write('''
/// Copies the `$cppSpelling` [$value] into a [List], and deletes [$value].
''');
      if (isOwnerAlive != null) {
        s.write('''
///
/// The elements borrow their pointers from the object that [$isOwnerAlive]
/// belongs to, if given, like a pointer returned by its method.
''');
      }
      s.write('''
$dartList ${toDart.name}($ptrVoid $value${isOwnerAlive == null ? '' : ', [bool Function()? $isOwnerAlive]'}) {
  try {
    return List.generate(${_size.name}($value), ($index) => $element);
  } finally {
    ${delete.name}($value);
  }
}

''');
    }

    if (vector.isPassedFromDart) {
      if (vector.movesElements) {
        _writeMovingFromDart(s, ctx, local);
      } else {
        _writeFromDart(s, ctx, local);
      }
    }

    // Copying, moving or destroying an element that is a C++ class runs its
    // code, which could call back into Dart, so those helpers aren't leaf
    // calls. The others are trivial.
    void writeNative(
      Symbol dartSymbol,
      String nativeSuffix, {
      required String returnType,
      required String nativeReturnType,
      required List<(String, String, String)> params,
      bool runsClassCode = false,
    }) => s.write(
      makeNativeHelperDeclaration(
        w,
        dartName: dartSymbol.name,
        nativeSymbolName: '${_nativePrefix}_$nativeSuffix',
        returnType: returnType,
        nativeReturnType: nativeReturnType,
        params: params,
        isLeaf: !runsClassCode,
      ),
    );

    final self = (ptrVoid, ptrVoid, 'self');
    if (vector.isPassedFromDart) {
      writeNative(
        _new,
        'new',
        returnType: ptrVoid,
        nativeReturnType: ptrVoid,
        params: [('$ffi.Size', 'int', 'capacity')],
      );
      writeNative(
        _push,
        'push',
        returnType: 'void',
        nativeReturnType: '$ffi.Void',
        params: [self, (_element.getCType(ctx), elementFfiDart, 'value')],
        runsClassCode: vector.copyingElementsRunsClassCode,
      );
      if (vector.movesElements) {
        writeNative(
          _release,
          'release',
          returnType: 'bool',
          nativeReturnType: '$ffi.Bool',
          params: [
            self,
            ('$ffi.Size', 'int', 'index'),
            (_element.getCType(ctx), elementFfiDart, 'pointer'),
          ],
        );
      }
    }
    writeNative(
      _size,
      'size',
      returnType: 'int',
      nativeReturnType: '$ffi.Size',
      params: [self],
    );
    writeNative(
      _get,
      'get',
      returnType: elementFfiDart,
      nativeReturnType: _element.getCType(ctx),
      params: [self, ('$ffi.Size', 'int', 'index')],
      runsClassCode: vector.copyingElementsRunsClassCode,
    );
    writeNative(
      delete,
      'delete',
      returnType: 'void',
      nativeReturnType: '$ffi.Void',
      params: [self],
      runsClassCode: vector.destroyingElementsRunsClassCode,
    );

    return BindingString(type: BindingStringType.func, string: s.toString());
  }

  /// Writes [fromDart], which copies each element into the vector.
  void _writeFromDart(
    StringBuffer s,
    Context ctx,
    String Function(String) local,
  ) {
    final ffi = ctx.libs.prefix(ffiImport);
    final value = local('value');
    final result = local('vector');
    final element = local('element');
    final localVars = LocalVariables(ctx.rootScope);
    final ffiElement = _element.convertDartTypeToFfiDartType(
      ctx,
      element,
      objCRetain: false,
      objCAutorelease: false,
      localVariables: localVars,
    );
    final push = localVars.wrapWithCleanups(
      _catchesExceptions
          ? '${_push.name}($result, $ffiElement);\n'
                '      ${ctx.cppExceptionHelpers.check.name}();'
          : '${_push.name}($result, $ffiElement);',
    );
    s.write('''
/// Copies [$value] into a new `${vector.cppSpelling}`.
///
/// The `std::vector` must be deleted with [${delete.name}].
$ffi.Pointer<$ffi.Void> ${fromDart.name}(${vector.getDartType(ctx)} $value) {
  final $result = ${_new.name}($value.length);
  try {
    for (final $element in $value) {
      ${localVars.generateDeclarations()}
      $push
    }
  } catch (_) {
    ${delete.name}($result);
    rethrow;
  }
  return $result;
}

''');
  }

  /// Writes [fromDart] and [reclaim] for a vector of `std::unique_ptr`s.
  ///
  /// The objects of the [List] keep their ownership while the vector is
  /// passed to C++, so that it's left with them if the call fails before
  /// reaching C++, like when another argument is invalid. Afterwards,
  /// [reclaim] gives the ownership of each object whose `std::unique_ptr` C++
  /// took to C++.
  void _writeMovingFromDart(
    StringBuffer s,
    Context ctx,
    String Function(String) local,
  ) {
    final ffi = ctx.libs.prefix(ffiImport);
    final ptrVoid = '$ffi.Pointer<$ffi.Void>';
    final dartList = vector.getDartType(ctx);
    final className = _element.getDartType(ctx);
    final cppSpelling = vector.cppSpelling;
    final value = local('value');
    final result = local('vector');
    final element = local('element');
    final pointers = local('pointers');
    final index = local('index');
    s.write('''
/// Copies the pointers of the objects in [$value] into a new
/// `$cppSpelling`, to pass it to C++.
///
/// The objects have to own their pointers, which they keep until
/// [${reclaim.name}] deletes the `std::vector` after the call.
$ptrVoid ${fromDart.name}($dartList $value) {
  // Every object is checked before the `std::vector` takes any, which it
  // would delete if a later check failed.
  final $pointers = <int>{};
  for (final $element in $value) {
    if ($element._activeFinalizer == null) {
      throw StateError($element._ptr == $ffi.nullptr
          ? 'An object in the List has already been disposed.'
          : 'An object in the List does not own its pointer.');
    }
    if (!$pointers.add($element._ptr.address)) {
      throw ArgumentError('The List holds the same object twice.');
    }
  }
  final $result = ${_new.name}($value.length);
  for (final $element in $value) {
    ${_push.name}($result, $element._ptr);
  }
  return $result;
}

/// Deletes the `$cppSpelling` [$result], which [${fromDart.name}] copied
/// [$value] into, after passing it to C++.
///
/// The objects in [$value] whose `std::unique_ptr`s C++ took out of
/// [$result] give their ownership to C++, and are invalidated like by
/// [$className.detachPointer]. The others keep it.
void ${reclaim.name}($ptrVoid $result, $dartList $value) {
  try {
    for (var $index = 0; $index < $value.length; $index++) {
      final $element = $value[$index];
      if (!${_release.name}($result, $index, $element._ptr)) {
        $element.detachPointer();
      }
    }
  } finally {
    ${delete.name}($result);
  }
}

''');
  }

  @override
  String toCppBindingString(Writer w) {
    final ctx = w.context;
    final cppSpelling = vector.cppSpelling;
    final externElement = _element.getExternCType(ctx).trim();

    // A helper running a C++ class's code constructs the glue guard, and, for
    // copying and moving, catches the exceptions, like a method's glue.
    String body(
      String statement, {
      required bool runsClassCode,
      bool returnsValue = false,
      bool catchExceptions = true,
    }) => runsClassCode
        ? cppGlueBody(
            ctx,
            statement,
            returnsValue: returnsValue,
            catchExceptions: catchExceptions,
          )
        : statement;

    // The vector is a temporary that Dart deletes once it has copied every
    // element, so they can be moved from.
    var element = _element.convertNativeTypeToExternCType(
      ctx,
      'std::move((*self)[index])',
    );
    if (vector.elementIsPointerToConst) {
      element = 'const_cast<$externElement>($element)';
    }

    final s = StringBuffer();
    if (vector.isPassedFromDart) {
      final value = _element.convertExternCTypeToNativeType(ctx, 'value');
      final push = 'self->push_back($value);';
      s.write('''
FFIGEN_EXPORT $cppSpelling* ${_nativePrefix}_new(std::size_t capacity) {
  auto* self = new $cppSpelling();
  self->reserve(capacity);
  return self;
}

FFIGEN_EXPORT void ${_nativePrefix}_push($cppSpelling* self, ${_element.getExternCType(ctx, varName: 'value').trim()}) {
  ${body(push, runsClassCode: vector.copyingElementsRunsClassCode)}
}

''');
      if (vector.movesElements) {
        s.write('''
FFIGEN_EXPORT bool ${_nativePrefix}_release($cppSpelling* self, std::size_t index, ${_element.getExternCType(ctx, varName: 'pointer').trim()}) {
  if (index >= self->size() || (*self)[index].get() != pointer) return false;
  (*self)[index].release();
  return true;
}

''');
      }
    }
    // Destructors are noexcept, like in a class's `delete` glue.
    s.write('''
FFIGEN_EXPORT std::size_t ${_nativePrefix}_size(const $cppSpelling* self) {
  return self->size();
}

FFIGEN_EXPORT $externElement ${_nativePrefix}_get($cppSpelling* self, std::size_t index) {
  ${body('return $element;', runsClassCode: vector.copyingElementsRunsClassCode, returnsValue: true)}
}

FFIGEN_EXPORT void ${_nativePrefix}_delete($cppSpelling* self) {
  ${body('delete self;', runsClassCode: vector.destroyingElementsRunsClassCode, catchExceptions: false)}
}

''');
    return s.toString();
  }

  @override
  bool get hasNativeHelperFunctions => true;

  @override
  void visitChildren(Visitor visitor) {
    super.visitChildren(visitor);
    visitor.visit(delete);
    visitor.visit(_size);
    visitor.visit(_get);
    if (vector.isPassedFromDart) {
      visitor.visit(fromDart);
      visitor.visit(_new);
      visitor.visit(_push);
      if (vector.movesElements) {
        visitor.visit(reclaim);
        visitor.visit(_release);
      }
      if (vector.borrowsElements) visitor.visit(_context.cppStdVectorArgument);
    }
    if (_catchesExceptions) visitor.visit(_context.cppExceptionHelpers);
    visitor.visit(ffiImport);
  }
}

/// A `std::vector` argument of a C++ call, whose elements are pointers to the
/// C++ objects of Dart objects, see [CppStdVectorType.borrowsElements].
///
/// It keeps the [List] of those Dart objects from being garbage collected,
/// whose finalizers could delete the C++ objects during the call.
///
/// Generated once per library, if any of its bindings pass such a vector.
class CppStdVectorArgument extends NoLookUpBinding {
  CppStdVectorArgument()
    : super(
        originalName: 'std::vector argument',
        symbol: Symbol('_CppStdVectorArgument', SymbolKind.klass),
        isInternal: true,
      );

  @override
  BindingString toBindingString(Writer w) {
    final ffi = w.context.libs.prefix(ffiImport);
    return BindingString(
      type: BindingStringType.func,
      string:
          '''
/// A `std::vector` passed to C++, which holds pointers to the C++ objects of
/// the Dart objects in [list].
///
/// A local variable holding this keeps [list], and so the Dart objects, from
/// being garbage collected until the end of its scope, since the class is
/// [$ffi.Finalizable]. Otherwise their finalizers could delete the C++
/// objects during the call.
final class $name implements $ffi.Finalizable {
  final $ffi.Pointer<$ffi.Void> pointer;
  final List<Object?> list;

  $name(this.pointer, this.list);
}

''',
    );
  }

  @override
  void visitChildren(Visitor visitor) {
    super.visitChildren(visitor);
    visitor.visit(ffiImport);
  }
}
