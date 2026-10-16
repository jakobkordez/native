// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A union that is declared but never defined.
union Blob;
typedef Blob BlobAlias;

// A class that is declared but never defined. Unlike the union above it goes
// through the C++ class parser and becomes an (empty) CppClass, not an
// incomplete compound.
class Incomplete;

class Widget {
 public:
  Widget();

  // A copy constructor takes a reference to a class, which is bindable.
  Widget(const Widget& other);

  // Bindable: these must survive.
  int good() const;
  Widget* self();
  Blob* blobPtr();
  void goodParams(int x, Widget* w, Blob* b);
  const Widget& constRef() const;
  void constRefParam(const Widget& w);

  // Only references to classes are supported.
  int& badRef();

  // An incomplete compound returned by value, directly and via a typedef.
  Blob badUnionByValue();
  BlobAlias badAliasByValue();

  // A C++ class returned by value: only pointers to a class can cross FFI,
  // whether the class is forward-declared or fully defined.
  Incomplete badClassByValue();
  Widget badSelfByValue();

  // The same shapes as unsupported parameter types instead of return types.
  void badRefParam(int& x);
  void badUnionParam(Blob b);
  void badAliasParam(BlobAlias b);
  void badClassParam(Incomplete i);
  void badSelfParam(Widget w);
};
