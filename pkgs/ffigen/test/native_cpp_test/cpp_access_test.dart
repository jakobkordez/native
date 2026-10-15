// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:test/test.dart';

import 'cpp_access_test_bindings.dart';

void main() {
  group('C++ access', () {
    test('public members', () {
      final gate = access$Gate.new$1(7);
      expect(gate.code(), 7);
      expect(gate.isOpen(), isFalse);
      gate.open();
      expect(gate.isOpen(), isTrue);

      gate.dispose();
      expect(access$Gate.liveCount(), 0);
    });

    test('abstract class with a virtual destructor', () {
      final shape = access$Shape.makeSquare(3);
      expect(shape.area(), 9);
      expect(shape.sides(), 4);
      expect(access$Shape.liveCount(), 1);

      // The destructor is virtual, so the Square can be deleted through a
      // pointer to Shape.
      shape.retainOwnership();
      shape.dispose();
      expect(access$Shape.liveCount(), 0);
    });

    test('unique_ptr of an abstract class', () {
      final shape = access$Shape.makeOwnedSquare(2);
      expect(shape.area(), 4);

      shape.dispose();
      expect(access$Shape.liveCount(), 0);
    });

    test('concrete subclass of an abstract class', () {
      final square = access$Square(5);
      expect(square.area(), 25);
      expect(square.sides(), 4);

      square.dispose();
      expect(access$Shape.liveCount(), 0);
    });

    test('interface with a protected destructor', () {
      final recorder = access$Recorder();
      final listener = recorder.asListener();
      expect(listener.notify(5), 10);
      expect(recorder.last(), 5);

      expect(listener.retainOwnership, throwsArgumentError);
      expect(listener.dispose, throwsStateError);

      recorder.dispose();
    });

    test('class with a protected destructor', () {
      final counted = access$Counted();
      expect(access$Counted.liveCount(), 1);
      counted.retain();
      expect(counted.count(), 2);

      // The class deletes itself once the count drops to zero.
      counted.release();
      counted.release();
      expect(access$Counted.liveCount(), 0);
    });

    test('custom finalizer for a class with a protected destructor', () {
      final release = access$Counted
          .releaseFunction()
          .cast<NativeFunction<Void Function(Pointer<Void>)>>();
      final counted = access$Counted();
      expect(counted.retainOwnership, throwsArgumentError);

      counted.retainOwnership(NativeFinalizer(release), release);
      counted.dispose();
      expect(access$Counted.liveCount(), 0);
    });

    test('polymorphic class with a non-virtual destructor', () {
      final widget = access$Widget();
      expect(widget.draw(), 2);
      expect(access$Widget.drawCopy(widget), 2);
      expect(access$Widget.liveCount(), 1);
      expect(widget.retainOwnership, throwsArgumentError);

      access$Widget.destroy(widget);
      expect(access$Widget.liveCount(), 0);
    });

    test('class with a private destructor', () {
      expect(access$Registry.instance().size(), 3);
    });
  });
}
