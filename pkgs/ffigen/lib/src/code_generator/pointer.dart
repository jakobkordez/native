// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../code_generator.dart';
import '../context.dart';
import '../visitor/ast.dart';
import 'local_variables.dart';

/// Represents a pointer.
class PointerType extends Type {
  final Type child;

  PointerType._(this.child);

  factory PointerType(Type child) {
    if (child == objCObjectType) {
      return ObjCObjectPointer();
    } else if (child == objCBlockType) {
      return ObjCBlockPointer();
    } else if (child is CppClass) {
      return CppClassPointerType(child);
    }
    return PointerType._(child);
  }

  @override
  Type get baseType => child.baseType;

  @override
  String getCType(Context context) =>
      '${context.libs.prefix(ffiImport)}.Pointer<${child.getCType(context)}>';

  @override
  String getNativeType(Context context, {String varName = ''}) =>
      '${child.getNativeType(context)}* $varName';

  // Both the C type and the FFI Dart type are 'Pointer<$cType>'.
  @override
  bool get sameFfiDartAndCType => true;

  @override
  String toString() => '$child*';

  @override
  String cacheKey() => '${child.cacheKey()}*';

  @override
  void visitChildren(Visitor visitor) {
    super.visitChildren(visitor);
    visitor.visit(child);
    visitor.visit(ffiImport);
  }

  @override
  void visit(Visitation visitation) => visitation.visitPointerType(this);

  @override
  bool isSupertypeOf(Type other) {
    other = other.typealiasType;
    if (other is PointerType) {
      return child.isSupertypeOf(other.child);
    }
    return false;
  }
}

/// Represents a constant array, which has a fixed size.
class ConstantArray extends PointerType {
  final int length;
  final bool useArrayType;

  ConstantArray(this.length, Type child, {required this.useArrayType})
    : super._(child);

  @override
  Type get baseArrayType => child.baseArrayType;

  @override
  bool get isIncompleteCompound => baseArrayType.isIncompleteCompound;

  @override
  String getNativeType(Context context, {String varName = ''}) =>
      '${child.getNativeType(context)} $varName[$length]';

  @override
  String toString() => '$child[$length]';

  @override
  String cacheKey() => '${child.cacheKey()}[$length]';

  @override
  String getCType(Context context) {
    if (useArrayType) {
      final lib = context.libs.prefix(ffiImport);
      return '$lib.Array<${child.getCType(context)}>';
    }

    return super.getCType(context);
  }
}

/// Represents an incomplete array, which has an unknown size.
class IncompleteArray extends PointerType {
  IncompleteArray(super.child) : super._();

  @override
  Type get baseArrayType => child.baseArrayType;

  @override
  String getNativeType(Context context, {String varName = ''}) =>
      '${child.getNativeType(context)}* $varName';

  @override
  String toString() => '$child[]';

  @override
  String cacheKey() => '${child.cacheKey()}[]';
}

/// A pointer to an Objective C object.
class ObjCObjectPointer extends PointerType {
  factory ObjCObjectPointer() => _inst;

  static final _inst = ObjCObjectPointer._();
  ObjCObjectPointer.__(super.child) : super._();
  ObjCObjectPointer._() : super._(objCObjectType);

  @override
  String getDartType(Context context) =>
      '${context.libs.prefix(objcPkgImport)}.ObjCObject';

  @override
  String getNativeType(Context context, {String varName = ''}) => 'id $varName';

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
  }) => ObjCInterface.generateGetId(
    context,
    value,
    objCRetain,
    objCAutorelease,
    localVariables,
  );

  @override
  String convertFfiDartTypeToDartType(
    Context context,
    String value, {
    required bool objCRetain,
    String? objCEnclosingClass,
  }) => '${getDartType(context)}($value, retain: $objCRetain, release: true)';

  @override
  String? generateRetain(String value) =>
      '(__bridge id)(__bridge_retained void*)($value)';

  @override
  bool isSupertypeOf(Type other) {
    other = other.typealiasType;
    // id/Object* is a supertype of all ObjC objects and blocks.
    return other is ObjCObjectPointer ||
        other is ObjCInterface ||
        other is ObjCBlock;
  }

  @override
  void visitChildren(Visitor visitor) {
    super.visitChildren(visitor);
    visitor.visit(objcPkgImport);
  }
}

/// A pointer to an Objective C block.
class ObjCBlockPointer extends ObjCObjectPointer {
  factory ObjCBlockPointer() => _inst;

  static final _inst = ObjCBlockPointer._();
  ObjCBlockPointer._() : super.__(objCBlockType);

  @override
  String getDartType(Context context) =>
      '${context.libs.prefix(objcPkgImport)}.ObjCBlockBase';

  @override
  String? generateRetain(String value) => 'objc_retainBlock($value)';

  @override
  bool isSupertypeOf(Type other) {
    other = other.typealiasType;
    return other is ObjCBlockPointer || other is ObjCBlock;
  }
}

/// A pointer to an Objective C object with protocols.
class ObjCObjectPointerWithProtocols extends ObjCObjectPointer {
  List<ObjCProtocol> protocols;

  ObjCObjectPointerWithProtocols(this.protocols)
    : assert(protocols.isNotEmpty),
      super._();

  @override
  String getDartType(Context context) => protocols.first.getDartType(context);

  @override
  bool isSupertypeOf(Type other) {
    other = other.typealiasType;
    if (other is ObjCObjectPointerWithProtocols) {
      // The "correct" logic would be to return true if each of our protocols
      // was a supertype of one of the other's protocols. But this method is
      // designed to reflect the subtyping rules of the *Dart bindings*, not the
      // ObjC types. So since the codegen just uses the first protocol, we do
      // the same here.
      return protocols.first.isSupertypeOf(other.protocols.first);
    }
    return false;
  }

  @override
  String toString() => 'id<${protocols.join(', ')}>';

  @override
  String cacheKey() => 'id<${protocols.map((p) => p.cacheKey()).join(', ')}>';

  @override
  String convertFfiDartTypeToDartType(
    Context context,
    String value, {
    required bool objCRetain,
    String? objCEnclosingClass,
  }) => protocols.first.convertFfiDartTypeToDartType(
    context,
    value,
    objCRetain: objCRetain,
    objCEnclosingClass: objCEnclosingClass,
  );

  @override
  void visitChildren(Visitor visitor) {
    super.visitChildren(visitor);
    visitor.visitAll(protocols);
  }
}

/// A pointer to a C++ class wrapper object.
///
/// Returned pointers are unowned by default. The developer must call
/// `retainOwnership()` explicitly  if ownership has been transferred.
///
/// A pointer returned by an instance method is borrowed from the object the
/// method was called on. See [convertReturnedToDartType].
///
/// A C++ method or a field getter returns it as a [CppNullablePointerType],
/// since it can be null.
class CppClassPointerType extends PointerType {
  final CppClass cppClass;

  CppClassPointerType(this.cppClass) : super._(cppClass);

  @override
  String getDartType(Context context) => cppClass.name;

  @override
  String getCType(Context context) {
    final ffi = context.libs.prefix(ffiImport);
    return '$ffi.Pointer<$ffi.Void>';
  }

  @override
  String getFfiDartType(Context context) => getCType(context);

  @override
  String getNativeType(Context context, {String varName = ''}) =>
      '${cppClass.originalName}* $varName';

  @override
  bool get sameDartAndCType => false;

  @override
  bool get sameDartAndFfiDartType => false;

  // Throws if the object, or the object it's borrowed from, has been disposed,
  // rather than passing a null or dangling pointer.
  @override
  String convertDartTypeToFfiDartType(
    Context context,
    String value, {
    required bool objCRetain,
    required bool objCAutorelease,
    required LocalVariables localVariables,
  }) => '$value._alivePtr';

  @override
  String convertFfiDartTypeToDartType(
    Context context,
    String value, {
    required bool objCRetain,
    String? objCEnclosingClass,
  }) => '${cppClass.name}.fromPointer($value)';

  /// The returned object borrows the pointer from the object that
  /// [isOwnerAlive] belongs to, if any: it keeps that object from being
  /// garbage collected, and becomes unusable once that object is disposed. It
  /// can still take ownership of the pointer, which ends the borrow.
  @override
  String convertReturnedToDartType(
    Context context,
    String value, {
    required String? isOwnerAlive,
  }) => isOwnerAlive == null
      ? convertFfiDartTypeToDartType(context, value, objCRetain: false)
      : '${cppClass.name}._borrowed($value, $isOwnerAlive)';

  /// Like [convertReturnedToDartType], but a null pointer becomes null.
  String convertReturnedToNullableDartType(
    Context context,
    String value, {
    required String? isOwnerAlive,
  }) => '${cppClass.name}._borrowedOrNull($value, $isOwnerAlive)';

  @override
  String toString() => '${cppClass.name}*';

  @override
  String cacheKey() => '${cppClass.cacheKey()}*';

  @override
  void visitChildren(Visitor visitor) {
    super.visitChildren(visitor);
    visitor.visit(cppClass);
    visitor.visit(ffiImport);
  }
}

/// A type representing `std::unique_ptr<T>` ownership transfer.
class CppUniquePtrType extends CppClassPointerType {
  CppUniquePtrType(super.cppClass);

  @override
  String convertDartTypeToFfiDartType(
    Context context,
    String value, {
    required bool objCRetain,
    required bool objCAutorelease,
    required LocalVariables localVariables,
  }) => '$value.detachPointer()';

  @override
  String convertFfiDartTypeToDartType(
    Context context,
    String value, {
    required bool objCRetain,
    String? objCEnclosingClass,
  }) => '${cppClass.name}.fromPointer($value, takeOwnership: true)';

  // The caller owns a returned unique_ptr, so it isn't borrowed.
  @override
  String convertReturnedToDartType(
    Context context,
    String value, {
    required String? isOwnerAlive,
  }) => convertFfiDartTypeToDartType(context, value, objCRetain: false);

  @override
  String convertReturnedToNullableDartType(
    Context context,
    String value, {
    required String? isOwnerAlive,
  }) => '${cppClass.name}._ownedOrNull($value)';

  @override
  bool get sameNativeAndExternCType => false;

  @override
  String convertExternCTypeToNativeType(Context context, String value) =>
      'std::unique_ptr<${cppClass.originalName}>($value)';

  @override
  String convertNativeTypeToExternCType(Context context, String value) =>
      '$value.release()';

  @override
  String toString() => 'unique_ptr<${cppClass.name}>';

  @override
  String cacheKey() => 'unique_ptr<${cppClass.cacheKey()}>';
}

/// An lvalue reference to a C++ class, like `T&` or `const T&`.
///
/// Only C++ methods and constructors can take or return one, because their
/// glue passes it as a pointer.
///
/// A returned reference is borrowed, like a returned [CppClassPointerType],
/// but the Dart object can never take ownership of it.
class CppClassReferenceType extends CppClassPointerType {
  /// Whether this is a reference to const, like `const T&`.
  final bool isConst;

  CppClassReferenceType(super.cppClass, {required this.isConst});

  @override
  String getNativeType(Context context, {String varName = ''}) =>
      '${isConst ? 'const ' : ''}${cppClass.originalName}& $varName';

  @override
  String getExternCType(Context context, {String varName = ''}) =>
      '${cppClass.originalName}* $varName';

  @override
  bool get sameNativeAndExternCType => false;

  @override
  String convertExternCTypeToNativeType(Context context, String value) =>
      '*$value';

  // std::addressof, because the class could overload the unary operator&.
  @override
  String convertNativeTypeToExternCType(Context context, String value) =>
      'std::addressof($value)';

  @override
  String convertFfiDartTypeToDartType(
    Context context,
    String value, {
    required bool objCRetain,
    String? objCEnclosingClass,
  }) => convertReturnedToDartType(context, value, isOwnerAlive: null);

  @override
  String convertReturnedToDartType(
    Context context,
    String value, {
    required String? isOwnerAlive,
  }) => '${cppClass.name}._borrowed($value, $isOwnerAlive, isReference: true)';

  @override
  String toString() => '${isConst ? 'const ' : ''}${cppClass.name}&';

  @override
  String cacheKey() => '${isConst ? 'const ' : ''}${cppClass.cacheKey()}&';
}

/// A pointer to a C++ class that a C++ method or a field getter returns, like
/// `T*` or `std::unique_ptr<T>`, which can be null.
///
/// Its Dart type is the nullable Dart type of [child], and a null pointer
/// becomes null. A reference can't be null, so it isn't wrapped in one.
///
/// It's only a return type, so it doesn't convert Dart values to pass them to
/// C++.
class CppNullablePointerType extends Type {
  /// The pointer type, whose [typealiasType] is a [CppClassPointerType], but
  /// not a [CppClassReferenceType].
  final Type child;

  CppNullablePointerType(this.child)
    : assert(
        child.typealiasType is CppClassPointerType &&
            child.typealiasType is! CppClassReferenceType,
        'Only a pointer to a C++ class can be null, not $child',
      );

  CppClassPointerType get _pointer =>
      child.typealiasType as CppClassPointerType;

  @override
  Type get baseType => child.baseType;

  @override
  String getCType(Context context) => child.getCType(context);

  @override
  String getFfiDartType(Context context) => child.getFfiDartType(context);

  @override
  String getDartType(Context context) => '${child.getDartType(context)}?';

  @override
  String getNativeType(Context context, {String varName = ''}) =>
      child.getNativeType(context, varName: varName);

  @override
  String getExternCType(Context context, {String varName = ''}) =>
      child.getExternCType(context, varName: varName);

  @override
  bool get sameNativeAndExternCType => child.sameNativeAndExternCType;

  @override
  String convertExternCTypeToNativeType(Context context, String value) =>
      child.convertExternCTypeToNativeType(context, value);

  @override
  String convertNativeTypeToExternCType(Context context, String value) =>
      child.convertNativeTypeToExternCType(context, value);

  @override
  bool get sameFfiDartAndCType => child.sameFfiDartAndCType;

  @override
  bool get sameDartAndCType => false;

  @override
  bool get sameDartAndFfiDartType => false;

  @override
  String convertFfiDartTypeToDartType(
    Context context,
    String value, {
    required bool objCRetain,
    String? objCEnclosingClass,
  }) => convertReturnedToDartType(context, value, isOwnerAlive: null);

  @override
  String convertReturnedToDartType(
    Context context,
    String value, {
    required String? isOwnerAlive,
  }) => _pointer.convertReturnedToNullableDartType(
    context,
    value,
    isOwnerAlive: isOwnerAlive,
  );

  @override
  String toString() => '$child?';

  @override
  String cacheKey() => '${child.cacheKey()}?';

  @override
  void visitChildren(Visitor visitor) {
    super.visitChildren(visitor);
    visitor.visit(child);
  }
}
