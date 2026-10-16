// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'cpp_std_vector_test_bindings.dart';

void main() {
  group('CppStdVector', () {
    late vec$Registry registry;
    late bool isDisposed;

    void disposeRegistry() {
      registry.dispose();
      isDisposed = true;
    }

    setUp(() {
      registry = vec$Registry(['a', 'bb', 'ccc']);
      isDisposed = false;
    });
    tearDown(() {
      if (!isDisposed) registry.dispose();
    });

    group('numbers', () {
      test('parameter by const reference, return by value', () {
        registry.setInts([1, 2, 3]);
        expect(registry.ints(), [1, 2, 3]);
      });

      test('parameter by value', () {
        expect(registry.sum([1, 2, 3, 4]), 10);
      });

      test('parameter by rvalue reference', () {
        registry.setInts([1]);
        registry.appendInts([2, 3]);
        expect(registry.ints(), [1, 2, 3]);
      });

      test('return by const reference', () {
        registry.setInts([4, 5]);
        expect(registry.intsRef(), [4, 5]);
      });

      test('a vector spelled through an alias', () {
        registry.setInts([6]);
        expect(registry.alias(), [6]);
      });

      test('static method', () {
        expect(vec$Registry.range(4), [0, 1, 2, 3]);
      });

      test('empty vectors', () {
        registry.setInts([]);
        expect(registry.ints(), isEmpty);
        expect(registry.sum([]), 0);
        expect(vec$Registry.range(0), isEmpty);
      });

      test('elements spelled through typedefs', () {
        expect(registry.sizes(), [1, 2, 3]);
        expect(registry.ids(5, 3), [5, 6, 7]);
      });

      test("elements spelled through typedefs the glue can't name", () {
        expect(registry.handles(), [7, 8]);
        expect(registry.secrets(), [9]);
      });

      test('floating point elements', () {
        expect(registry.halves([1, 2, 3]), [0.5, 1.0, 1.5]);
      });

      test('std::vector<bool>', () {
        expect(registry.parities([1, 2, 3, 4]), [false, true, false, true]);
      });

      test('the List is a copy of the std::vector', () {
        registry.setInts([1, 2]);
        final before = registry.ints();
        registry.setInts([3]);
        expect(before, [1, 2]);

        before.add(9);
        expect(registry.ints(), [3]);
      });

      test('a large vector', () {
        final values = List.generate(10000, (i) => i);
        registry.setInts(values);
        expect(registry.ints(), values);
      });
    });

    test('enums', () {
      expect(registry.colors(), [
        vec$Color.red,
        vec$Color.green,
        vec$Color.blue,
        vec$Color.red,
      ]);
      expect(registry.countRed([vec$Color.red, vec$Color.blue]), 1);
    });

    test('strings', () {
      expect(registry.names(), ['a', 'bb', 'ccc']);
      expect(vec$Registry.join(['x', 'héllo', '🎯', ''], ','), 'x,héllo,🎯,');
    });

    test('a vector parameter of a constructor', () {
      final other = vec$Registry([]);
      expect(other.names(), isEmpty);
      other.dispose();
    });

    group('pointers to classes', () {
      test('are borrowed from the object whose method returned them', () {
        final items = registry.items();
        expect(items.map((i) => i.name()), ['a', 'bb', 'ccc']);
        expect(registry.constItems().map((i) => i.name()), ['a', 'bb', 'ccc']);

        disposeRegistry();
        expect(items.first.name, throwsStateError);
      });

      test('can be passed back', () {
        final items = registry.constItems();
        expect(registry.indexOf(items, 'bb'), 1);
        expect(registry.indexOf(items.reversed.toList(), 'bb'), 1);
        expect(registry.indexOf([], 'bb'), -1);
      });

      test('can point to objects that Dart owns', () {
        expect(registry.indexOf([vec$Item('x'), vec$Item('y')], 'y'), 1);
      });

      test('in a vector spelled through an alias template', () {
        expect(registry.itemPtrs().map((i) => i.name()), ['a', 'bb', 'ccc']);
      });

      test('in nested vectors are borrowed too', () {
        final byLength = registry.itemsByLength();
        expect(byLength.map((items) => items.length), [0, 1, 1, 1]);
        expect(byLength[2].single.name(), 'bb');

        disposeRegistry();
        expect(byLength[2].single.name, throwsStateError);
      });
    });

    group('classes by value', () {
      test('are copies that the Dart objects own', () {
        final points = registry.points(3);
        disposeRegistry();
        expect(points.map((p) => (p.x(), p.y())), [(0, 0), (1, 10), (2, 20)]);
        for (final p in points) {
          p.dispose();
        }
      });

      test('are copied into a vector parameter', () {
        final points = registry.points(4);
        expect(registry.sumX(points), 6);
        // The C++ vector held copies, so the Dart objects are still usable.
        expect(points.last.x(), 3);
      });

      test("a disposed object can't be passed", () {
        final points = registry.points(2);
        points.first.dispose();
        expect(() => registry.sumX(points), throwsStateError);
      });

      test('of a class that can only be moved can be returned', () {
        final values = registry.moveOnlies(3);
        expect(values.map((v) => v.value()), [0, 1, 2]);
        for (final v in values) {
          v.dispose();
        }
      });
    });

    test('POD structs', () {
      final pairs = registry.pairs(3);
      expect(pairs.map((p) => (p.first, p.second)), [(0, 0), (1, -1), (2, -2)]);
      expect(registry.sumPairs(pairs), 297);
    });

    group('std::unique_ptr', () {
      test('returned elements are owned by the Dart objects', () {
        final before = vec$Item.liveCount();
        final items = vec$Registry.makeItems(['x', 'y']);
        expect(items.map((i) => i.name()), ['x', 'y']);
        expect(vec$Item.liveCount(), before + 2);

        for (final item in items) {
          item.dispose();
        }
        expect(vec$Item.liveCount(), before);
      });

      test('elements passed in move their ownership to C++', () {
        final before = vec$Item.liveCount();
        final items = vec$Registry.makeItems(['x', 'y']);
        registry.adopt(items);
        expect(items.first.name, throwsStateError);
        expect(registry.names(), ['a', 'bb', 'ccc', 'x', 'y']);
        expect(vec$Item.liveCount(), before + 2);

        disposeRegistry();
        expect(vec$Item.liveCount(), before - 3);
      });

      test('elements that C++ only looks at keep their ownership', () {
        final before = vec$Item.liveCount();
        final items = vec$Registry.makeItems(['x', 'yy']);
        expect(vec$Registry.totalLength(items), 3);
        expect(items.map((i) => i.name()), ['x', 'yy']);
        expect(vec$Item.liveCount(), before + 2);

        for (final item in items) {
          item.dispose();
        }
        expect(vec$Item.liveCount(), before);
      });

      test('only the elements that C++ takes move their ownership', () {
        final before = vec$Item.liveCount();
        final items = vec$Registry.makeItems(['x', 'y']);
        registry.adoptFirst(items);
        expect(items.first.name, throwsStateError);
        expect(items.last.name(), 'y');
        expect(registry.names(), ['a', 'bb', 'ccc', 'x']);
        expect(vec$Item.liveCount(), before + 2);

        items.last.dispose();
        expect(vec$Item.liveCount(), before + 1);
      });

      group('a failed call leaves the ownership with Dart', () {
        late List<vec$Item> items;
        late int before;

        setUp(() {
          before = vec$Item.liveCount();
          items = vec$Registry.makeItems(['x', 'y']);
        });
        tearDown(() {
          for (final item in items) {
            item.dispose();
          }
          expect(vec$Item.liveCount(), before);
        });

        void expectOwned() {
          expect(items.map((i) => i.name()), ['x', 'y']);
          expect(vec$Item.liveCount(), before + 2);
        }

        test('if the object the method is called on is disposed', () {
          disposeRegistry();
          before -= 3;
          expect(() => registry.adopt(items), throwsStateError);
          expectOwned();
        });

        test("if an element doesn't own its pointer", () {
          final borrowed = registry.items().first;
          expect(() => registry.adopt([...items, borrowed]), throwsStateError);
          expectOwned();
        });

        test('if an element is passed twice', () {
          expect(
            () => registry.adopt([...items, items.first]),
            throwsArgumentError,
          );
          expectOwned();
        });
      });

      test('in a vector spelled through an alias template', () {
        final items = vec$Registry.makeUniqueItems(['p']);
        expect(items.single.name(), 'p');
        items.single.dispose();
      });

      test('to const are owned too', () {
        final before = vec$Item.liveCount();
        final items = vec$Registry.makeConstItems(['c']);
        expect(items.single.name(), 'c');
        expect(vec$Item.liveCount(), before + 1);
        items.single.dispose();
        expect(vec$Item.liveCount(), before);
      });
    });

    test('nested vectors', () {
      final grid = registry.grid(2, 3);
      expect(grid, [
        [0, 1, 2],
        [3, 4, 5],
      ]);
      expect(vec$Registry.gridSum(grid), 15);
      expect(
        vec$Registry.gridSum([
          [1],
          [],
          [2, 3],
        ]),
        6,
      );
    });
  });
}
