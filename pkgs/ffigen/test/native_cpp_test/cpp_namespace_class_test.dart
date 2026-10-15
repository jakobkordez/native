// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:test/test.dart';

import 'cpp_namespace_class_test_bindings.dart';

void main() {
  group('C++ classes in namespaces', () {
    test('classes sharing a leaf name do not collide', () {
      final global = Creature();
      final zooCreature = zoo$Creature(5);
      final fish = zoo$aquarium$Creature(2.5);
      final cow = farm$Creature(3, 4);

      expect(zooCreature.getAge(), 5);
      expect(fish.getDepth(), 2.5);
      expect(cow.getAge(), 3);
      expect(cow.getLegs(), 4);
      expect(global.compare(zooCreature, fish), 3);

      global.dispose();
      zooCreature.dispose();
      fish.dispose();
      cow.dispose();
    });

    test('static methods', () {
      expect(zoo$Creature.sum(3, 4), 7);

      final created = zoo$Creature.create(8);
      expect(created.getAge(), 8);
      created.retainOwnership();
      created.dispose();
    });

    test('pass and return by value', () {
      final animal = zoo$Creature(10);
      final older = animal.olderBy(5);
      expect(older.getAge(), 15);
      expect(animal.getAge(), 10);

      final position = Struct.create<zoo$Position>()
        ..x = 3
        ..y = -2;
      animal.moveTo(position);
      final moved = animal.getPosition();
      expect(moved.x, 3);
      expect(moved.y, -2);

      older.dispose();
      animal.dispose();
    });

    test('inheritance within and across namespaces', () {
      final dog = zoo$Dog(2);
      expect(dog, isA<zoo$Creature>());
      expect(dog.bark(), 20);
      dog.setAge(4);
      expect(dog.getAge(), 4);

      final cow = farm$Creature(6, 4);
      expect(cow, isA<zoo$Creature>());

      final keeper = zoo$Keeper(1);
      expect(keeper.feed(dog), 4 + 7);
      expect(keeper.feed(cow), 6 + 7);

      keeper.dispose();
      cow.dispose();
      dog.dispose();
    });

    test('class nested in a namespaced class', () {
      final badge = zoo$Keeper$Badge(42);
      expect(badge.getNumber(), 42);
      badge.dispose();

      final keeper = zoo$Keeper(9);
      // The badge is owned by the keeper, so the wrapper must not own it.
      final keeperBadge = keeper.getBadge();
      expect(keeperBadge.getNumber(), 9);
      expect(keeperBadge.dispose, throwsStateError);
      keeper.dispose();
    });
  });
}
