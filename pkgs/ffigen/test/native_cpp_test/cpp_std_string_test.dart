// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:test/test.dart';

import 'cpp_std_string_test_bindings.dart';

void main() {
  group('CppStdString', () {
    late StringBox box;

    setUp(() => box = StringBox('hello'));
    tearDown(() => box.dispose());

    test('constructor parameter by const reference', () {
      final other = StringBox('abc');
      expect(other.size(), 3);
      other.dispose();
    });

    test('return by value', () {
      expect(box.get(), 'hello');
    });

    test('return by const reference', () {
      expect(box.ref(), 'hello');
    });

    test('parameter by value', () {
      box.set('world');
      expect(box.get(), 'world');
    });

    test('parameter by const reference', () {
      box.append(', world');
      expect(box.get(), 'hello, world');
    });

    test('parameter by rvalue reference', () {
      box.prepend('oh, ');
      expect(box.get(), 'oh, hello');
    });

    test('std::string through an alias', () {
      expect(box.alias(), 'hello');
    });

    test('static method with other parameters', () {
      expect(StringBox.repeat('ab', 3), 'ababab');
      expect(StringBox.repeat('ab', 0), '');
    });

    test('empty string', () {
      box.set('');
      expect(box.get(), '');
      expect(box.size(), 0);
    });

    test('strings are encoded as UTF-8', () {
      const value = 'héllo wörld 🎯';
      box.set(value);
      expect(box.get(), value);
      expect(box.size(), utf8.encode(value).length);
    });

    test('strings may contain NUL characters', () {
      const value = 'a\u0000b';
      box.set(value);
      expect(box.get(), value);
      expect(box.size(), 3);
    });

    test('the Dart String is a copy of the std::string', () {
      final before = box.ref();
      box.set('changed');
      expect(before, 'hello');
    });
  });
}
