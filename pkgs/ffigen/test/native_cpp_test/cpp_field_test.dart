// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

import 'cpp_field_test_bindings.dart';

void main() {
  group('C++ fields', () {
    tearDown(() => expect(fld$Tag.liveCount(), 0));

    test('numbers, bools, enums and bit-fields', () {
      final settings = fld$Settings();
      expect(settings.retries, 3);
      expect(settings.ratio, 0.5);
      expect(settings.verbose, isFalse);
      expect(settings.mode, fld$Mode.kAuto);
      expect(settings.flags, 0);

      settings.retries = -4;
      settings.ratio = 1.25;
      settings.verbose = true;
      settings.mode = fld$Mode.kOn;
      settings.flags = 9;
      expect(settings.retries, -4);
      expect(settings.ratio, 1.25);
      expect(settings.verbose, isTrue);
      expect(settings.mode, fld$Mode.kOn);
      expect(settings.flags, 9);

      // The bit-field is 4 bits wide.
      settings.flags = 0x1f;
      expect(settings.flags, 0xf);

      settings.dispose();
    });

    test('std::string and std::vector', () {
      final settings = fld$Settings();
      expect(settings.name, 'default');
      expect(settings.levels, isEmpty);
      expect(settings.aliases, isEmpty);

      settings.name = 'héllo wörld';
      settings.levels = [3, 1, 2];
      settings.aliases = ['a', 'bc'];
      expect(settings.name, 'héllo wörld');
      expect(settings.levels, [3, 1, 2]);
      expect(settings.aliases, ['a', 'bc']);

      // The getters return copies.
      final levels = settings.levels..add(4);
      expect(levels, [3, 1, 2, 4]);
      expect(settings.levels, [3, 1, 2]);

      settings.dispose();
    });

    test('POD struct', () {
      final settings = fld$Settings();
      final origin = settings.origin;
      expect(origin.x, 1.5);
      expect(origin.y, -2.5);

      // The getter returns a copy.
      origin.x = 3;
      expect(settings.origin.x, 1.5);

      settings.origin = origin;
      expect(settings.origin.x, 3);
      expect(settings.origin.y, -2.5);

      settings.dispose();
    });

    test('C++ class by value', () {
      final settings = fld$Settings();
      expect(fld$Tag.liveCount(), 1);

      // The getter returns a reference, so changes show up in the field.
      final tag = settings.tag;
      expect(tag.id, 1);
      tag.id = 2;
      expect(settings.tag.id, 2);
      expect(tag.dispose, throwsStateError);
      expect(tag.retainOwnership, throwsStateError);

      // The setter copies the object into the field.
      final other = fld$Tag(5);
      settings.tag = other;
      expect(settings.tag.id, 5);
      expect(tag.id, 5);
      other.id = 6;
      expect(settings.tag.id, 5);
      expect(fld$Tag.liveCount(), 2);
      other.dispose();

      // The reference is unusable once its owner is disposed.
      settings.dispose();
      expect(() => tag.id, throwsStateError);
    });

    test('C++ class that cannot be assigned', () {
      final settings = fld$Settings();
      expect(settings.frozen.value, 7);
      expect(settings.sealed.value, 8);
      settings.sealed.value = 9;
      expect(settings.sealed.value, 9);
      settings.dispose();
    });

    test('const field', () {
      final settings = fld$Settings();
      expect(settings.version, 2);
      settings.dispose();
    });

    test('pointer to a C++ class', () {
      final settings = fld$Settings();
      expect(() => settings.link.pointer, throwsStateError);

      final tag = fld$Tag(3);
      settings.link = tag;
      final link = settings.link;
      expect(link.id, 3);
      expect(link.pointer, tag.pointer);
      expect(link.dispose, throwsStateError);

      settings.dispose();
      expect(() => link.id, throwsStateError);
      tag.dispose();
    });

    test('pointer to const', () {
      final settings = fld$Settings();
      expect(settings.label.cast<Utf8>().toDartString(), 'label');

      final label = 'other'.toNativeUtf8();
      settings.label = label.cast();
      expect(settings.label, label.cast<Char>());
      expect(settings.label.cast<Utf8>().toDartString(), 'other');
      calloc.free(label);

      settings.dispose();
    });

    test('std::unique_ptr', () {
      final settings = fld$Settings();
      expect(() => settings.owned.pointer, throwsStateError);

      // The setter takes ownership.
      final tag = fld$Tag(4);
      settings.owned = tag;
      expect(() => tag.id, throwsStateError);
      expect(fld$Tag.liveCount(), 2);

      // The getter borrows the pointer.
      final owned = settings.owned;
      expect(owned.id, 4);
      expect(owned.dispose, throwsStateError);

      // Assigning deletes the previous object.
      settings.owned = fld$Tag(5);
      expect(settings.owned.id, 5);
      expect(fld$Tag.liveCount(), 2);

      settings.ownedConst = fld$Tag(6);
      expect(settings.ownedConst.id, 6);
      expect(fld$Tag.liveCount(), 3);

      // A wrapper that doesn't own its pointer can't give it away.
      expect(() => settings.owned = settings.tag, throwsStateError);
      expect(settings.owned.id, 5);

      settings.dispose();
      expect(() => owned.id, throwsStateError);
    });

    test('renamed fields', () {
      final settings = fld$Settings();
      // Named like a member of every wrapper.
      expect(settings.pointer$1, 5);
      settings.pointer$1 = 50;
      expect(settings.pointer$1, 50);

      // Renamed by the config.
      expect(settings.wasRenamed, 6);
      settings.wasRenamed = 60;
      expect(settings.wasRenamed, 60);
      settings.dispose();
    });

    test('reference fields', () {
      final tag = fld$Tag(1);
      final view = fld$View(tag);
      expect(view.tag.id, 1);
      expect(view.constTag.id, 1);

      view.tag.id = 2;
      expect(tag.id, 2);
      expect(view.constTag.id, 2);
      expect(view.tag.retainOwnership, throwsStateError);

      view.dispose();
      tag.dispose();
    });

    test('skipped fields', () {
      final skipped = fld$Skipped();
      expect(skipped.visible, 1);
      skipped.visible = 2;
      expect(skipped.visible, 2);
      skipped.dispose();
    });

    test('inherited fields', () {
      final derived = fld$Derived();
      expect(derived.baseValue, 10);
      expect(derived.derivedValue, 20);

      // The field that Derived::shadowed hides keeps its name, and
      // Derived::shadowed gets a suffix.
      expect(derived.shadowed, 1);
      expect(derived.shadowed$1, 2);
      derived.shadowed = 3;
      derived.shadowed$1 = 4;
      expect(derived.shadowed, 3);
      expect(derived.shadowed$1, 4);

      // Seen as a Base, it's the same field.
      final fld$Base base = derived;
      expect(base.shadowed, 3);
      base.baseValue = 11;
      expect(derived.baseValue, 11);

      derived.dispose();
    });
  });
}
