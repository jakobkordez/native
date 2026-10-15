// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <string>

// C++ methods and constructors can take and return `std::string`, which Dart
// code sees as a `String`.

using StringAlias = std::string;

class StringBox {
 public:
  // Const reference parameter of a constructor.
  explicit StringBox(const std::string& value);

  // Return by value.
  std::string get() const;

  // Return by const reference.
  const std::string& ref() const;

  // Parameter by value.
  void set(std::string value);

  // Const reference parameter.
  void append(const std::string& suffix);

  // Rvalue reference parameter.
  void prepend(std::string&& prefix);

  // A `std::string` spelled through an alias.
  StringAlias alias() const;

  // A `std::string` next to other parameters, in a static method.
  static std::string repeat(const std::string& value, int times);

  // The number of bytes in the string.
  int size() const;

  // Not bound: a callee could modify the string through a mutable reference,
  // which would not be reflected in the Dart `String`.
  void moveInto(std::string& out);

  // Not bound: only `std::string` itself is converted, not pointers to it.
  void setFrom(const std::string* value);

 private:
  std::string value_;
};

// Not bound: free functions are called without generated glue, so they can't
// convert a `std::string`.
std::string describe(const std::string& value);
