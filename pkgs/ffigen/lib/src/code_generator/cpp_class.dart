// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../code_generator.dart';
import '../config_provider/public_ast.dart' as public_ast;
import '../context.dart';
import '../visitor/ast.dart';

import 'binding_string.dart';
import 'local_variables.dart';
import 'scope.dart';
import 'utils.dart';
import 'writer.dart';

enum CppMethodKind { constructor, method }

/// A method or constructor belonging to a C++ class.
class CppMethod extends AstNode with HasLocalScope {
  /// The Dart name of this method.
  ///
  /// For a constructor, this is the name of the Dart constructor, and an empty
  /// name means the unnamed constructor.
  ///
  /// A method that overrides, or was copied from, a method of the class's
  /// first base class shares that method's [Symbol], so both get the same
  /// name. See `NameCppMethodsVisitation`.
  Symbol name;
  final Symbol cBindingSymbol;
  final String originalName;

  final Type returnType;
  final List<Parameter> parameters;
  final bool isConstant;
  final bool isStatic;
  final CppMethodKind kind;

  /// The base class that declares this method, if it was copied from a base.
  final CppClass? originatingClass;

  /// Whether the C++ return type is a pointer to const, like `const T*`, or a
  /// reference to const, like `const T&`, which the glue returns as a pointer.
  ///
  /// The glue function returns a pointer to non-const, because Dart has no
  /// notion of const, so it has to cast the const away.
  final bool returnsPointerToConst;

  bool isIncluded = true;

  CppMethod({
    required this.name,
    required this.cBindingSymbol,
    required this.originalName,
    required this.returnType,
    required this.parameters,
    required this.isConstant,
    this.isStatic = false,
    this.kind = CppMethodKind.method,
    this.originatingClass,
    this.returnsPointerToConst = false,
  });

  bool get isConstructor => kind == .constructor;

  bool get isUnnamedConstructor => isConstructor && name.oldName.isEmpty;

  CppMethod cloneForClass(CppClass targetClass, CppClass baseClass) {
    return CppMethod(
      name: name.clone(),
      cBindingSymbol: Symbol(
        '${targetClass.cSymbolPrefix}_${name.oldName}',
        SymbolKind.method,
      ),
      originalName: originalName,
      returnType: returnType,
      parameters: parameters.map((p) => p.clone()).toList(),
      isConstant: isConstant,
      isStatic: isStatic,
      kind: kind,
      originatingClass: originatingClass ?? baseClass,
      returnsPointerToConst: returnsPointerToConst,
    );
  }

  String _overloadKey() {
    final paramTypes = parameters.map((p) => p.type.cacheKey()).join(',');
    return '$originalName($paramTypes)';
  }

  String signatureKey() => '${_overloadKey()}${isConstant ? ' const' : ''}';

  /// Whether this is the const overload of [other], which is otherwise the
  /// same method.
  bool isConstTwinOf(CppMethod other) =>
      isConstant &&
      !other.isConstant &&
      !isStatic &&
      !other.isStatic &&
      _overloadKey() == other._overloadKey();

  @override
  void visit(Visitation visitation) => visitation.visitCppMethod(this);

  @override
  void visitChildren(Visitor visitor) {
    super.visitChildren(visitor);
    visitor.visit(name);
    visitor.visit(cBindingSymbol);
    visitor.visit(returnType);
    visitor.visitAll(parameters);
    visitor.visit(originatingClass);
  }
}

class CppMember extends CompoundMember {
  /// Whether this field is declared `const` in the C++ source.
  ///
  /// A const field can only have a getter generated; mutable fields get both
  /// a getter and a setter.
  final bool isConst;

  CppMember({
    super.originalName,
    required super.name,
    required super.type,
    super.dartDoc,
    required this.isConst,
  });
}

/// A binding for a C++ class.
class CppClass extends BindingType with HasLocalScope {
  final Context context;
  final List<CppMethod> methods;
  final List<CppMember> fields;
  bool isIncluded = false;

  /// The public C++ base classes for this class, in declaration order.
  ///
  /// Only public inheritance is represented here. Protected and private bases
  /// are silently ignored by the parser.
  final List<CppClass> bases;

  /// Whether the class has pure virtual methods that it doesn't override, so
  /// it can't be instantiated, and gets no constructors.
  final bool isAbstract;

  /// Whether the destructor can be called from outside of the class, that is,
  /// it's public and not deleted.
  final bool hasPublicDestructor;

  /// Whether the bindings can `delete` an object through a pointer to this
  /// class.
  ///
  /// This needs a public destructor, which also has to be virtual if the class
  /// has virtual methods, since the object could then be of a subclass.
  ///
  /// Otherwise there's no `delete` glue function, so a Dart object can only
  /// own its pointer through a custom finalizer, and its constructors return
  /// objects that don't own their pointers.
  final bool isDeletable;

  CppClass({
    super.usr,
    super.originalName,
    required super.name,
    super.dartDoc,
    required this.context,
    required this.methods,
    required this.fields,
    this.bases = const [],
    this.isAbstract = false,
    this.hasPublicDestructor = true,
    this.isDeletable = true,
  });

  /// The prefix of the C glue functions generated for this class's methods.
  ///
  /// [originalName] is the qualified C++ name, so for a class declared inside
  /// a namespace or a record the scope separators are replaced to form a C
  /// identifier, e.g. `outer::Animal` becomes `outer_Animal`.
  String get cSymbolPrefix => originalName.replaceAll('::', '_');

  @override
  public_ast.AstNode? toPublicAstNode() => public_ast.CppClass(this);

  @override
  void visit(Visitation visitation) => visitation.visitCppClass(this);

  @override
  String convertDartTypeToFfiDartType(
    Context context,
    String value, {
    required bool objCRetain,
    required bool objCAutorelease,
    required LocalVariables localVariables,
  }) => '$value._alivePtr';

  void copyMethod(CppMethod method, CppClass originatingBase) {
    final cloned = method.cloneForClass(this, originatingBase);
    methods.add(cloned);
  }

  void filterMethods(bool Function(CppMethod method) predicate) {
    methods.retainWhere(predicate);
  }

  @override
  BindingString toBindingString(Writer w) {
    final s = StringBuffer();
    final ctx = w.context;
    final ffiPrefix = ctx.libs.prefix(ffiImport);

    final ptrVoid = '$ffiPrefix.Pointer<$ffiPrefix.Void>';

    // Helper to build a comma-separated Dart parameter list.
    String dartParamList(Iterable<Parameter> params) =>
        params.map((p) => '${p.type.getDartType(ctx)} ${p.name}').join(', ');

    final classMethods = methods.where((m) => m.kind == .method).toList();
    final constructors = methods.where((m) => m.kind == .constructor).toList();

    final deleteSymbol = '${name}_delete';
    final deleteGlue = '_$deleteSymbol';

    s.write(makeDartDoc(dartDoc));
    // Build the implements clause: ffi.Finalizable + public base classes.
    final implementsClause = [
      '$ffiPrefix.Finalizable',
      ...bases.map((b) => b.name),
    ].join(', ');
    s.write('''
class $name implements $implementsClause {
  $ptrVoid _ptr;
''');

    if (isDeletable) {
      s.write('''
  static final _defaultFinalizer = $ffiPrefix.NativeFinalizer(
    $ffiPrefix.Native.addressOf<$ffiPrefix.NativeFunction<$ffiPrefix.Void Function($ptrVoid)>>($deleteGlue),
  );

''');
    }
    s.write('''
  /// The finalizer currently attached for this instance, or [null] if this
  /// object does not own its pointer.
  $ffiPrefix.NativeFinalizer? _activeFinalizer;

  /// The native function pointer used by [_activeFinalizer], stored so that
  /// [dispose] can call the correct destructor directly.
  $ffiPrefix.Pointer<
    $ffiPrefix.NativeFunction<$ffiPrefix.Void Function($ptrVoid)>
  >? _activeFinalizerFn;

  /// Whether the object that this one is borrowed from is still alive, or
  /// null if this object isn't borrowed from another object.
  ///
  /// This is a tear-off of that object's [_isAlive], so it also keeps that
  /// object, which owns the C++ object, from being garbage collected while
  /// this one is reachable.
  bool Function()? _isOwnerAlive;

  /// Whether this object wraps a C++ reference, which it can't take
  /// ownership of.
  final bool _isReference;

''');
    if (isDeletable) {
      s.write('''
  $name.fromPointer(this._ptr, {bool takeOwnership = false})
    : _isReference = false {
    if (takeOwnership) {
      _defaultFinalizer.attach(this, _ptr.cast(), detach: this);
      _activeFinalizer = _defaultFinalizer;
      _activeFinalizerFn = $ffiPrefix.Native.addressOf<
        $ffiPrefix.NativeFunction<$ffiPrefix.Void Function($ptrVoid)>
      >($deleteGlue);
    }
  }

  /// Attaches a finalizer so this object takes ownership of the underlying
  /// C++ pointer. If [customFinalizer] is provided it is used instead of the
  /// default `delete` finalizer, which is useful when the object was not
  /// allocated with `new` (e.g. `malloc` or a custom allocator).
  ///
  /// Both [customFinalizer] and [customFinalizerFn] must be provided together.
  ///
  /// If this object is borrowed from another object, it no longer depends on
  /// that object afterwards.
  ///
  /// Throws a [StateError] if the object, or the object it's borrowed from,
  /// has already been disposed, if this object already owns the pointer, or
  /// if it wraps a C++ reference.
  void retainOwnership([
    $ffiPrefix.NativeFinalizer? customFinalizer,
    $ffiPrefix.Pointer<
      $ffiPrefix.NativeFunction<$ffiPrefix.Void Function($ptrVoid)>
    >? customFinalizerFn,
  ]) {
    final ptr = _alivePtr;
    if (_activeFinalizer != null) {
      throw StateError('This object already owns its pointer.');
    }
    if (_isReference) {
      throw StateError(
          "This object wraps a C++ reference, so it can't own its pointer.");
    }
    if ((customFinalizer == null) != (customFinalizerFn == null)) {
      throw ArgumentError(
          'Both customFinalizer and customFinalizerFn must be provided together.');
    }
    final fin = customFinalizer ?? _defaultFinalizer;
    final fnPtr = customFinalizerFn ??
        $ffiPrefix.Native.addressOf<
          $ffiPrefix.NativeFunction<$ffiPrefix.Void Function($ptrVoid)>
        >($deleteGlue);
    fin.attach(this, ptr.cast(), detach: this);
    _activeFinalizer = fin;
    _activeFinalizerFn = fnPtr;
    _isOwnerAlive = null;
  }

''');
    } else {
      final reason = hasPublicDestructor
          ? "its destructor isn't virtual, although it has virtual methods"
          : "its destructor isn't public";
      s.write('''
  /// Wraps [_ptr], without taking ownership of it. To take ownership, call
  /// [retainOwnership] with a custom finalizer.
  ///
  /// The bindings can't delete a pointer to `$originalName`, since
  /// $reason.
  $name.fromPointer(this._ptr) : _isReference = false;

  /// Attaches [customFinalizer] so this object takes ownership of the
  /// underlying C++ pointer. [customFinalizerFn] is the native function that
  /// [customFinalizer] calls, which [dispose] calls directly.
  ///
  /// Both are required, since the bindings can't delete this object.
  ///
  /// If this object is borrowed from another object, it no longer depends on
  /// that object afterwards.
  ///
  /// Throws an [ArgumentError] if either is missing. Throws a [StateError] if
  /// the object, or the object it's borrowed from, has already been disposed,
  /// if this object already owns the pointer, or if it wraps a C++ reference.
  void retainOwnership([
    $ffiPrefix.NativeFinalizer? customFinalizer,
    $ffiPrefix.Pointer<
      $ffiPrefix.NativeFunction<$ffiPrefix.Void Function($ptrVoid)>
    >? customFinalizerFn,
  ]) {
    final ptr = _alivePtr;
    if (_activeFinalizer != null) {
      throw StateError('This object already owns its pointer.');
    }
    if (_isReference) {
      throw StateError(
          "This object wraps a C++ reference, so it can't own its pointer.");
    }
    if (customFinalizer == null || customFinalizerFn == null) {
      throw ArgumentError(
          'The bindings cannot delete this object, so both customFinalizer '
          'and customFinalizerFn must be provided.');
    }
    customFinalizer.attach(this, ptr.cast(), detach: this);
    _activeFinalizer = customFinalizer;
    _activeFinalizerFn = customFinalizerFn;
    _isOwnerAlive = null;
  }

''');
    }
    s.write('''
  /// Wraps [_ptr], which another object owns, without taking ownership of it.
  ///
  /// [_isOwnerAlive] is a tear-off of the [_isAlive] method of the object
  /// that this one is borrowed from, or null if it isn't borrowed from an
  /// object. [isReference] is whether [_ptr] comes from a C++ reference.
  $name._borrowed(
    this._ptr,
    this._isOwnerAlive, {
    bool isReference = false,
  }) : _isReference = isReference;

  /// Whether neither this object, nor the object it's borrowed from, if any,
  /// has been disposed.
  bool _isAlive() =>
      _ptr != $ffiPrefix.nullptr && (_isOwnerAlive?.call() ?? true);

  /// [_ptr], for passing to C++.
  ///
  /// Throws a [StateError] if this object, or the object it's borrowed from,
  /// has been disposed, rather than letting C++ use a dangling pointer.
  $ptrVoid get _alivePtr {
    if (_ptr == $ffiPrefix.nullptr) {
      throw StateError('This object has already been disposed.');
    }
    if (_isOwnerAlive?.call() == false) {
      throw StateError(
          'The object that this object is borrowed from has been disposed.');
    }
    return _ptr;
  }

  /// Detaches the finalizer so this object releases ownership of the
  /// underlying C++ pointer. The caller becomes responsible for freeing
  /// the memory.
  ///
  /// Throws a [StateError] if the object has already been disposed, or if
  /// this object does not own the pointer.
  void releaseOwnership() {
    if (_ptr == $ffiPrefix.nullptr) {
      throw StateError('This object has already been disposed.');
    }
    if (_activeFinalizer == null) {
      throw StateError('This object does not own its pointer.');
    }
    _activeFinalizer!.detach(this);
    _activeFinalizer = null;
    _activeFinalizerFn = null;
  }

  /// Detaches the finalizer and invalidates this object, returning the
  /// underlying C++ pointer.
  ///
  /// Throws a [StateError] if the object has already been disposed, or if
  /// this object does not own the pointer.
  $ptrVoid detachPointer() {
    final rawPtr = _ptr;
    releaseOwnership();
    _ptr = $ffiPrefix.nullptr;
    return rawPtr;
  }
''');

    for (final ctor in constructors) {
      final glueName = ctor.cBindingSymbol.name;
      final privateName = '_$glueName';
      final ctorName = ctor.isUnnamedConstructor ? name : '$name.${ctor.name}';

      final dartParams = dartParamList(ctor.parameters);
      final localVars = LocalVariables(ctor.localScope);

      final callArgs = ctor.parameters
          .map(
            (p) => p.type.convertDartTypeToFfiDartType(
              ctx,
              p.name,
              objCRetain: false,
              objCAutorelease: false,
              localVariables: localVars,
            ),
          )
          .join(', ');

      final body = localVars.wrapWithCleanups(
        isDeletable
            ? 'return $name.fromPointer($privateName($callArgs), '
                  'takeOwnership: true);'
            : 'return $name.fromPointer($privateName($callArgs));',
      );
      if (!isDeletable) {
        s.write('''

  /// The returned object doesn't own its pointer, since the bindings can't
  /// delete it. See [retainOwnership].
''');
      }
      s.write('''
  factory $ctorName($dartParams) {
    ${localVars.generateDeclarations()}
    $body
  }
''');
    }

    for (final method in classMethods) {
      final glue = '_${method.cBindingSymbol.name}';
      final dartReturn = method.returnType.getDartType(ctx);
      final dartParams = dartParamList(method.parameters);
      final localVars = LocalVariables(method.localScope);

      final callArgs = [
        if (!method.isStatic) '_alivePtr',
        ...method.parameters.map(
          (p) => p.type.convertDartTypeToFfiDartType(
            ctx,
            p.name,
            objCRetain: false,
            objCAutorelease: false,
            localVariables: localVars,
          ),
        ),
      ].join(', ');
      final decls = localVars.generateDeclarations();

      final call = '$glue($callArgs)';
      final returnExpr = switch (method.returnType.typealiasType) {
        // A returned pointer or reference is borrowed from this object.
        final CppClassPointerType type => type.convertReturnedToDartType(
          ctx,
          call,
          isOwnerAlive: method.isStatic ? null : '_isAlive',
        ),
        _ => method.returnType.convertFfiDartTypeToDartType(
          ctx,
          call,
          objCRetain: false,
        ),
      };

      final hasReturn = method.returnType != voidType;
      final callLine = localVars.wrapWithCleanups(
        hasReturn ? 'return $returnExpr;' : '$returnExpr;',
      );

      s.write('''\
  ${method.isStatic ? 'static ' : ''}$dartReturn ${method.name}($dartParams) {
    $decls
    $callLine
  }
''');
    }
    s.write('''
  ${bases.isNotEmpty ? '@override\n  ' : ''}void dispose() {
    if (_ptr == $ffiPrefix.nullptr) {
      throw StateError('This object has already been disposed.');
    }
    if (_activeFinalizer == null) {
      throw StateError('Cannot dispose a non-owning wrapper. '
          'Call retainOwnership() first to take ownership.');
    }
    _activeFinalizer!.detach(this);
    _activeFinalizer = null;
    _activeFinalizerFn?.asFunction<void Function($ptrVoid)>()(_ptr);
    _activeFinalizerFn = null;
    _ptr = $ffiPrefix.nullptr;
  }
''');

    s.write('}\n');

    // Writes a @Native annotation + external declaration for a glue function.
    void writeNativeDecl({
      required String symbol,
      required String glue,
      required String cType,
      required String ffiReturn,
      required String ffiParams,
    }) {
      s.write(
        makeNativeAnnotation(
          w,
          nativeType: cType,
          dartName: glue,
          nativeSymbolName: Namer.cSafeName(symbol),
        ),
      );
      s.write('\nexternal $ffiReturn $glue($ffiParams);\n\n');
    }

    for (final method in methods) {
      final symbol = method.cBindingSymbol.name;
      final glue = '_$symbol';

      final cReturn = method.isConstructor
          ? ptrVoid
          : method.returnType.getCType(ctx);
      final ffiReturn = method.isConstructor
          ? ptrVoid
          : method.returnType.getFfiDartType(ctx);

      final needsSelf = !method.isConstructor && !method.isStatic;
      final cParams = [
        if (needsSelf) ptrVoid,
        ...method.parameters.map((p) => p.type.getCType(ctx)),
      ].join(', ');
      final ffiParams = [
        if (needsSelf) '$ptrVoid self',
        ...method.parameters.map(
          (p) => '${p.type.getFfiDartType(ctx)} ${p.name}',
        ),
      ].join(', ');

      writeNativeDecl(
        symbol: symbol,
        glue: glue,
        cType: '$cReturn Function($cParams)',
        ffiReturn: ffiReturn,
        ffiParams: ffiParams,
      );
    }
    if (isDeletable) {
      writeNativeDecl(
        symbol: deleteSymbol,
        glue: deleteGlue,
        cType: '$ffiPrefix.Void Function($ptrVoid)',
        ffiReturn: 'void',
        ffiParams: '$ptrVoid self',
      );
    }

    return BindingString(
      type: BindingStringType.cppClass,
      string: s.toString(),
    );
  }

  @override
  String? toCppBindingString(Writer w) {
    final context = w.context;
    String paramDecl(Parameter p) =>
        p.type.getExternCType(context, varName: p.name).trim();

    // The Dart side looks these functions up by their C-safe names, so define
    // them under the same names.
    final deleteWrapper =
        '''
FFIGEN_EXPORT void ${Namer.cSafeName('${name}_delete')}($originalName* self) {
  delete self;
}''';

    final methodBindings = methods
        .map((method) {
          final symbol = Namer.cSafeName(method.cBindingSymbol.name);

          final returnTypeString = method.isConstructor
              ? '$originalName*'
              : method.returnType.getExternCType(context).trim();
          final String params;
          final String body;

          final callArgs = method.parameters
              .map(
                (p) => p.type.convertExternCTypeToNativeType(context, p.name),
              )
              .join(', ');

          if (method.isConstructor) {
            params = method.parameters.map(paramDecl).join(', ');
            body = 'return new $originalName($callArgs);';
          } else {
            final otherParams = method.parameters.map(paramDecl);

            final String callExpr;
            if (method.isStatic) {
              final targetType =
                  method.originatingClass?.originalName ?? originalName;
              params = otherParams.join(', ');
              callExpr = '$targetType::${method.originalName}($callArgs)';
            } else {
              final constPrefix = method.isConstant ? 'const ' : '';
              final selfType = '$constPrefix$originalName';
              params = ['$selfType* self', ...otherParams].join(', ');
              // A method of the same name declared in this class would hide
              // a method copied from a base class, so call the copied method
              // through a pointer to the base.
              final receiver = switch (method.originatingClass) {
                final base? =>
                  'static_cast<$constPrefix${base.originalName}*>(self)',
                null => 'self',
              };
              final methodName = method.originalName;
              callExpr = '$receiver->$methodName($callArgs)';
            }

            if (method.returnType == voidType) {
              body = '$callExpr;';
            } else {
              final result = method.returnType.convertNativeTypeToExternCType(
                context,
                callExpr,
              );
              final returnExpr = method.returnsPointerToConst
                  ? 'const_cast<$returnTypeString>($result)'
                  : result;
              body = 'return $returnExpr;';
            }
          }

          return '''
FFIGEN_EXPORT $returnTypeString $symbol($params) {
  $body
}''';
        })
        .join('\n\n');

    return isDeletable
        ? '$methodBindings\n\n$deleteWrapper\n\n'
        : '$methodBindings\n\n';
  }

  @override
  String getDartType(Context context) => name;

  @override
  String getCType(Context context) {
    final ffi = context.libs.prefix(ffiImport);
    return '$ffi.Pointer<$ffi.Void>';
  }

  @override
  String getFfiDartType(Context context) => getCType(context);

  @override
  String convertFfiDartTypeToDartType(
    Context context,
    String value, {
    required bool objCRetain,
    String? objCEnclosingClass,
  }) => '$name.fromPointer($value, takeOwnership: true)';

  @override
  String getNativeType(Context context, {String varName = ''}) =>
      varName.isEmpty ? originalName : '$originalName $varName';

  @override
  String getExternCType(Context context, {String varName = ''}) =>
      '$originalName* $varName';

  @override
  bool get sameNativeAndExternCType => false;

  @override
  String convertExternCTypeToNativeType(Context context, String value) =>
      '*$value';

  @override
  String convertNativeTypeToExternCType(Context context, String value) =>
      'new $originalName($value)';

  @override
  bool get sameFfiDartAndCType => true;
  @override
  bool get sameDartAndCType => false;

  @override
  bool get sameDartAndFfiDartType => false;

  @override
  bool get hasNativeHelperFunctions => true;

  @override
  void visitChildren(Visitor visitor) {
    super.visitChildren(visitor);
    visitor.visitAll(methods);
    visitor.visitAll(fields);
    visitor.visitAll(bases);
    visitor.visit(ffiImport);
  }
}
