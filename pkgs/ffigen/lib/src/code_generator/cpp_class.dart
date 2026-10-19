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

  /// The type that this method returns.
  ///
  /// A pointer to a C++ class, or a `std::unique_ptr` to one, is a
  /// [CppNullablePointerType], since it can be null.
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

  /// Whether this method returns `void`, possibly through a typedef.
  bool get returnsVoid => returnType.typealiasType == voidType;

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

/// A public non-static data member of a C++ class, which the Dart class
/// exposes as a getter, and a setter if the field can be assigned.
class CppField extends AstNode with HasLocalScope {
  /// The Dart name of the getter and the setter.
  ///
  /// A field copied from the class's first base class shares that field's
  /// [Symbol], so both get the same name. See `NameCppMethodsVisitation`.
  Symbol name;

  /// The glue function that reads the field.
  final Symbol getterSymbol;

  /// The glue function that assigns the field, or null if it can't be
  /// assigned.
  final Symbol? setterSymbol;

  final String originalName;
  final String? dartDoc;

  /// The type of the field, which the setter takes.
  final Type type;

  /// The type that the getter returns.
  ///
  /// That's [type], except for a C++ class, which the getter returns by
  /// reference, and a `std::unique_ptr`, whose getter returns the pointer it
  /// holds. Either is borrowed from the object that the field belongs to.
  ///
  /// A pointer to a C++ class, including that of a `std::unique_ptr`, is a
  /// [CppNullablePointerType], since it can be null.
  final Type getterType;

  /// Whether [getterType] is a pointer or reference to const, see
  /// [CppMethod.returnsPointerToConst].
  final bool getterReturnsPointerToConst;

  /// The base class that declares this field, if it was copied from a base.
  final CppClass? originatingClass;

  bool isIncluded = true;

  CppField({
    required this.name,
    required this.getterSymbol,
    required this.setterSymbol,
    required this.originalName,
    this.dartDoc,
    required this.type,
    required this.getterType,
    this.getterReturnsPointerToConst = false,
    this.originatingClass,
  });

  CppField cloneForClass(CppClass targetClass, CppClass baseClass) {
    Symbol glueSymbol(String accessor) => Symbol(
      '${targetClass.cSymbolPrefix}_${accessor}_$originalName',
      SymbolKind.method,
    );
    return CppField(
      name: name.clone(),
      getterSymbol: glueSymbol('get'),
      setterSymbol: setterSymbol == null ? null : glueSymbol('set'),
      originalName: originalName,
      dartDoc: dartDoc,
      type: type,
      getterType: getterType,
      getterReturnsPointerToConst: getterReturnsPointerToConst,
      originatingClass: originatingClass ?? baseClass,
    );
  }

  @override
  void visit(Visitation visitation) => visitation.visitCppField(this);

  @override
  void visitChildren(Visitor visitor) {
    super.visitChildren(visitor);
    visitor.visit(name);
    visitor.visit(getterSymbol);
    visitor.visit(setterSymbol);
    visitor.visit(type);
    visitor.visit(getterType);
    visitor.visit(originatingClass);
  }
}

/// A binding for a C++ class.
class CppClass extends BindingType with HasLocalScope {
  final Context context;
  final List<CppMethod> methods;

  /// The public non-static data members of this class, including those copied
  /// from its public base classes.
  final List<CppField> fields;
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

  /// Whether the glue can copy an object of this class, which needs a public
  /// copy constructor that isn't deleted.
  ///
  /// The glue copies an object to pass it by value, or to put it in a
  /// `std::vector`.
  final bool isCopyable;

  /// The C glue function that the `NativeFinalizer` calls to hand an object
  /// to the `Cpp.finalizerHook`, see [finalizesThroughHook].
  ///
  /// It's in the root C++ scope, like the methods' glue functions, so a method
  /// named `finalize` doesn't clash with it.
  late final Symbol finalizeSymbol = Symbol(
    '${cSymbolPrefix}_finalize',
    SymbolKind.method,
  );

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
    this.isCopyable = true,
  });

  /// The names of the members that every class wrapper has, including those
  /// of [Object], which its C++ methods can't be named, see
  /// `CreateScopesVisitation`.
  static const wrapperMemberNames = {
    'hashCode',
    'runtimeType',
    'noSuchMethod',
    'toString',
    'fromPointer',
    'retainOwnership',
    'releaseOwnership',
    'detachPointer',
    'pointer',
    'dispose',
    '_ptr',
    '_defaultFinalizer',
    '_activeFinalizer',
    '_activeFinalizerFn',
    '_isOwnerAlive',
    '_isReference',
    '_borrowed',
    '_borrowedOrNull',
    '_ownedOrNull',
    '_isAlive',
    '_alivePtr',
  };

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

  void copyField(CppField field, CppClass originatingBase) {
    fields.add(field.cloneForClass(this, originatingBase));
  }

  void filterFields(bool Function(CppField field) predicate) {
    fields.retainWhere(predicate);
  }

  /// Whether the glue catches C++ exceptions, see `Cpp.catchExceptions`.
  bool get _catchesExceptions => context.config.cpp?.catchExceptions ?? false;

  /// Whether the default `NativeFinalizer` hands an object to the
  /// `Cpp.finalizerHook` through the [finalizeSymbol] glue, rather than
  /// deleting it.
  bool get finalizesThroughHook =>
      isDeletable && context.config.cpp?.finalizerHook != null;

  @override
  BindingString toBindingString(Writer w) {
    final s = StringBuffer();
    final ctx = w.context;
    final ffiPrefix = ctx.libs.prefix(ffiImport);

    final ptrVoid = '$ffiPrefix.Pointer<$ffiPrefix.Void>';

    // A glue call returning a value, checked for a caught C++ exception.
    String checkedCall(String call) => _catchesExceptions
        ? '${ctx.cppExceptionHelpers.checked.name}($call)'
        : call;

    // Helper to build a comma-separated Dart parameter list.
    String dartParamList(Iterable<Parameter> params) =>
        params.map((p) => '${p.type.getDartType(ctx)} ${p.name}').join(', ');

    final classMethods = methods.where((m) => m.kind == .method).toList();
    final constructors = methods.where((m) => m.kind == .constructor).toList();

    final deleteSymbol = '${name}_delete';
    final deleteGlue = '_$deleteSymbol';
    // What the default finalizer calls: the hook's glue, or the delete glue.
    // [dispose] calls the delete glue either way.
    final finalizerGlue = finalizesThroughHook
        ? '_${finalizeSymbol.name}'
        : deleteGlue;

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
    $ffiPrefix.Native.addressOf<$ffiPrefix.NativeFunction<$ffiPrefix.Void Function($ptrVoid)>>($finalizerGlue),
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

  /// Wraps [ptr], a pointer that C++ returned, without taking ownership of
  /// it, or returns null if [ptr] is null.
  ///
  /// See [$name._borrowed] for [isOwnerAlive].
  static $name? _borrowedOrNull($ptrVoid ptr, bool Function()? isOwnerAlive) =>
      ptr == $ffiPrefix.nullptr ? null : $name._borrowed(ptr, isOwnerAlive);

''');
    if (isDeletable) {
      s.write('''
  /// Wraps [ptr], the pointer of a `std::unique_ptr` that C++ returned, and
  /// takes ownership of it, or returns null if [ptr] is null.
  static $name? _ownedOrNull($ptrVoid ptr) => ptr == $ffiPrefix.nullptr
      ? null
      : $name.fromPointer(ptr, takeOwnership: true);

''');
    }
    s.write('''
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

  /// The address of the C++ object, for passing to native code that these
  /// bindings don't cover.
  ///
  /// This object keeps its ownership: the address stays valid only while
  /// this object, and the object it's borrowed from, if any, are alive. A
  /// local variable holding this object keeps it alive until the end of its
  /// scope, since the class is [$ffiPrefix.Finalizable].
  ///
  /// Throws a [StateError] if this object, or the object it's borrowed from,
  /// has been disposed.
  $ptrVoid get pointer => _alivePtr;

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

      final call = checkedCall('$privateName($callArgs)');
      final body = localVars.wrapWithCleanups(
        isDeletable
            ? 'return $name.fromPointer($call, takeOwnership: true);'
            : 'return $name.fromPointer($call);',
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

    for (final field in fields) {
      // A returned pointer or reference is borrowed from this object.
      final getterCall = checkedCall('_${field.getterSymbol.name}(_alivePtr)');
      final getterExpr = field.getterType.convertReturnedToDartType(
        ctx,
        getterCall,
        isOwnerAlive: '_isAlive',
      );
      s.write(makeDartDoc(field.dartDoc));
      s.write('''
  ${field.getterType.getDartType(ctx)} get ${field.name} {
    return $getterExpr;
  }
''');

      final setterSymbol = field.setterSymbol;
      if (setterSymbol == null) continue;
      final localVars = LocalVariables(field.localScope);
      final value = field.type.convertDartTypeToFfiDartType(
        ctx,
        'value',
        objCRetain: false,
        objCAutorelease: false,
        localVariables: localVars,
      );
      final setterCall = '_${setterSymbol.name}(_alivePtr, $value);';
      final setterBody = localVars.wrapWithCleanups(
        _catchesExceptions
            ? '$setterCall\n    ${ctx.cppExceptionHelpers.check.name}();'
            : setterCall,
      );
      s.write('''
  set ${field.name}(${field.type.getDartType(ctx)} value) {
    ${localVars.generateDeclarations()}
    $setterBody
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

      final hasReturn = !method.returnsVoid;
      final call = hasReturn
          ? checkedCall('$glue($callArgs)')
          : '$glue($callArgs)';
      // A returned pointer or reference is borrowed from this object.
      final returnExpr = method.returnType.convertReturnedToDartType(
        ctx,
        call,
        isOwnerAlive: method.isStatic ? null : '_isAlive',
      );

      final callLine = localVars.wrapWithCleanups(
        hasReturn
            ? 'return $returnExpr;'
            : _catchesExceptions
            ? '$returnExpr;\n    ${ctx.cppExceptionHelpers.check.name}();'
            : '$returnExpr;',
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
    for (final field in fields) {
      final getterSymbol = field.getterSymbol.name;
      writeNativeDecl(
        symbol: getterSymbol,
        glue: '_$getterSymbol',
        cType: '${field.getterType.getCType(ctx)} Function($ptrVoid)',
        ffiReturn: field.getterType.getFfiDartType(ctx),
        ffiParams: '$ptrVoid self',
      );
      if (field.setterSymbol?.name case final setterSymbol?) {
        writeNativeDecl(
          symbol: setterSymbol,
          glue: '_$setterSymbol',
          cType:
              '$ffiPrefix.Void Function($ptrVoid, '
              '${field.type.getCType(ctx)})',
          ffiReturn: 'void',
          ffiParams: '$ptrVoid self, ${field.type.getFfiDartType(ctx)} value',
        );
      }
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
    if (finalizesThroughHook) {
      writeNativeDecl(
        symbol: finalizeSymbol.name,
        glue: finalizerGlue,
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
    //
    // `delete` doesn't catch exceptions: the NativeFinalizer calls it during
    // garbage collection, where no Dart caller could rethrow the exception.
    final deleteName = Namer.cSafeName('${name}_delete');
    final deleteWrapper =
        '''
FFIGEN_EXPORT void $deleteName($originalName* self) {
  ${cppGlueBody(context, 'delete self;', returnsValue: false, catchExceptions: false)}
}''';

    // The NativeFinalizer's glue with a `Cpp.finalizerHook`: it neither
    // constructs the guard nor deletes, it hands the object to the hook with a
    // function that deletes it through the delete glue above.
    final finalizeWrapper = switch (context.config.cpp?.finalizerHook) {
      final hook? when finalizesThroughHook =>
        '''
FFIGEN_EXPORT void ${Namer.cSafeName(finalizeSymbol.name)}($originalName* self) {
  $hook(self, [](void* object) { $deleteName(static_cast<$originalName*>(object)); });
}''',
      _ => null,
    };

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

            if (method.returnsVoid) {
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
  ${cppGlueBody(context, body, returnsValue: method.isConstructor || !method.returnsVoid)}
}''';
        })
        .join('\n\n');

    final fieldBindings = fields.map((field) => _fieldGlue(context, field));

    return [
      methodBindings,
      ...fieldBindings,
      if (isDeletable) deleteWrapper,
      ?finalizeWrapper,
    ].map((binding) => '$binding\n\n').join();
  }

  /// The glue functions that read and assign [field].
  String _fieldGlue(Context context, CppField field) {
    // A field of the same name declared in this class would hide a field
    // copied from a base class, so access the copied field through a pointer
    // to the base.
    final receiver = switch (field.originatingClass) {
      final base? => 'static_cast<${base.originalName}*>(self)',
      null => 'self',
    };
    final access = '$receiver->${field.originalName}';

    final returnType = field.getterType.getExternCType(context).trim();
    final fieldValue = field.type.typealiasType is CppUniquePtrType
        ? '$access.get()'
        : access;
    final result = field.getterType.convertNativeTypeToExternCType(
      context,
      fieldValue,
    );
    final getterBody = field.getterReturnsPointerToConst
        ? 'return const_cast<$returnType>($result);'
        : 'return $result;';
    final getter =
        '''
FFIGEN_EXPORT $returnType ${Namer.cSafeName(field.getterSymbol.name)}($originalName* self) {
  ${cppGlueBody(context, getterBody, returnsValue: true)}
}''';

    final setterSymbol = field.setterSymbol;
    if (setterSymbol == null) return getter;
    final valueParam = field.type
        .getExternCType(context, varName: 'value')
        .trim();
    final value = field.type.convertExternCTypeToNativeType(context, 'value');
    return '''
$getter

FFIGEN_EXPORT void ${Namer.cSafeName(setterSymbol.name)}($originalName* self, $valueParam) {
  ${cppGlueBody(context, '$access = $value;', returnsValue: false)}
}''';
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
    if (_catchesExceptions) visitor.visit(context.cppExceptionHelpers);
  }
}

/// The body of a glue function whose statement [body] calls into C++.
///
/// It constructs the `Cpp.glueGuard`, if any, first. With
/// `Cpp.catchExceptions`, it also catches the exceptions of [body], unless
/// [catchExceptions] is false, and returns a value-initialized result if
/// [returnsValue].
String cppGlueBody(
  Context context,
  String body, {
  required bool returnsValue,
  bool catchExceptions = true,
}) {
  final cpp = context.config.cpp;
  final guard = switch (cpp?.glueGuard) {
    final type? => 'const $type ffigen_guard{};',
    null => null,
  };
  if (catchExceptions && (cpp?.catchExceptions ?? false)) {
    return context.cppExceptionHelpers.wrapGlueBody(
      body,
      returnsValue: returnsValue,
      guard: guard,
    );
  }
  return guard == null ? body : '$guard\n  $body';
}
