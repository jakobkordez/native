// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../test_utils.dart';
import 'cpp_borrowed_ref_test_bindings.dart';

void main() {
  group('C++ borrowed references', () {
    tearDown(() {
      expect(borrow$Core.liveCount(), 0);
      expect(borrow$StatusFlag.liveCount(), 0);
      expect(borrow$Property.liveCount(), 0);
    });

    test('returned reference', () {
      final core = borrow$Core(7);
      final device = core.device();
      expect(device.id(), 7);

      // The core owns the device.
      expect(device.dispose, throwsStateError);
      expect(device.retainOwnership, throwsStateError);
      expect(device.releaseOwnership, throwsStateError);

      core.dispose();
    });

    test('returned reference to const', () {
      final core = borrow$Core(1);
      final device = core.device();

      device.status().setCode(3);
      expect(device.statusConst().code(), 3);
      expect(device.statusConst().dispose, throwsStateError);

      core.dispose();
    });

    test('returned pointer', () {
      final core = borrow$Core(1);
      final device = core.device();
      final property = device.property(2);
      expect(property.value(), 20);

      // The pointer is borrowed, so changes show up in the device.
      property.setValue(25);
      expect(device.property(2).value(), 25);
      expect(device.properties().atConst(1).value(), 25);
      expect(property.dispose, throwsStateError);

      core.dispose();
    });

    test('chain of borrowed objects', () {
      final core = borrow$Core(1);
      final properties = core.device().properties();
      expect(properties.size(), 3);
      expect(properties.at(2).id(), 3);
      expect(properties.front().id(), 1);

      core.dispose();
    });

    test('unusable once the owner is disposed', () {
      final core = borrow$Core(1);
      final device = core.device();
      final status = device.status();
      final property = device.properties().at(0);

      core.dispose();
      expect(device.id, throwsStateError);
      expect(status.code, throwsStateError);
      expect(property.value, throwsStateError);
      expect(device.properties, throwsStateError);
      expect(property.retainOwnership, throwsStateError);
    });

    test('argument whose owner is disposed', () {
      final core = borrow$Core(1);
      final other = borrow$Core(2);
      final status = core.device().status();

      core.dispose();
      expect(() => other.device().setStatus(status), throwsStateError);
      expect(() => borrow$StatusFlag.new$1(status), throwsStateError);

      other.dispose();
    });

    test('disposed argument', () {
      final core = borrow$Core(1);
      final status = borrow$StatusFlag(4)..dispose();

      expect(() => core.device().setStatus(status), throwsStateError);

      core.dispose();
    });

    test('taking ownership of a returned pointer ends the borrow', () {
      final core = borrow$Core(1);
      final property = core.device().properties().release(0)..retainOwnership();
      expect(core.device().properties().size(), 2);

      // The property no longer depends on the core.
      core.dispose();
      expect(property.id(), 1);
      expect(borrow$Property.liveCount(), 1);

      property.dispose();
    });

    test('static method returning a reference', () {
      final registry = borrow$Registry.instance();
      expect(registry.size(), 7);
      expect(registry.dispose, throwsStateError);
      expect(registry.retainOwnership, throwsStateError);
    });

    test('reference parameters', () {
      final core = borrow$Core(1);
      final device = core.device();
      final status = borrow$StatusFlag(5);

      // Passed by const reference, and copied.
      device.setStatus(status);
      expect(device.statusConst().code(), 5);
      expect(status.equals(device.statusConst()), isTrue);
      status.setCode(6);
      expect(status.equals(device.statusConst()), isFalse);

      // The copy constructor.
      final copy = borrow$StatusFlag.new$1(status);
      expect(copy.code(), 6);
      expect(borrow$StatusFlag.liveCount(), 3);

      status.dispose();
      copy.dispose();
      core.dispose();
    });

    test('returning a reference to the receiver', () {
      final status = borrow$StatusFlag(1);
      final other = borrow$StatusFlag(2);

      final assigned = status.operatorAssign(other);
      expect(assigned.code(), 2);
      expect(status.code(), 2);
      expect(assigned.dispose, throwsStateError);

      status.dispose();
      expect(assigned.code, throwsStateError);
      other.dispose();
    });

    // Wrapped in functions that aren't inlined, so the objects created in them
    // are unreachable after they return.
    @pragma('vm:never-inline')
    borrow$Property borrowProperty() =>
        borrow$Core(1).device().properties().at(1);

    @pragma('vm:never-inline')
    void useBorrowedProperty() {
      final property = borrowProperty();
      doGC();
      // The property keeps the core, which owns it, alive.
      expect(borrow$Core.liveCount(), 1);
      expect(property.value(), 20);
    }

    test('borrowed object keeps its owner alive', () {
      useBorrowedProperty();
      doGC();
      expect(borrow$Core.liveCount(), 0);
    }, skip: !canDoGC);

    @pragma('vm:never-inline')
    void dropBorrowedDevice() {
      final _ = borrow$Core(1).device();
    }

    test('GC deletes the owner of an unreachable borrowed object', () {
      dropBorrowedDevice();
      doGC();
      expect(borrow$Core.liveCount(), 0);
    }, skip: !canDoGC);
  });
}
