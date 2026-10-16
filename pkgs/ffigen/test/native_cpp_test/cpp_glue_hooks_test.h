// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <string>
#include <vector>

// The glue hooks of `Cpp`: every glue function constructs the configured guard
// (`hooks::CallGuard`, declared in cpp_glue_hooks_guard.h, which only the glue
// includes) around its call, and catches the C++ exceptions it throws, which
// the Dart bindings rethrow as a `CppException`.

namespace hooks {

using Nothing = void;

// A class whose copy constructor and destructor run in the glue of the
// `std::vector` helpers, which copy elements to and from Dart, and delete
// vectors.
class Copyable {
 public:
  explicit Copyable(int value);

  // Throws std::runtime_error when copying a negative value. A vector's
  // elements are copied out of it with this too, since there's no move
  // constructor.
  Copyable(const Copyable& other);
  ~Copyable();

  int value() const;

  // How many guards were alive during the last copy, and the last
  // destruction.
  static int copyGuardDepth();
  static int destroyGuardDepth();

 private:
  int value_;
};

class Thrower {
 public:
  // Throws std::invalid_argument for a negative value.
  explicit Thrower(int value);

  // Never throws.
  int value() const;

  // Throws std::domain_error when divisor is 0.
  int divide(int divisor) const;

  // A `std::string` return: throws std::runtime_error when fail is true.
  std::string describe(bool fail) const;

  // A void method: throws std::out_of_range for a negative value, leaving the
  // value unchanged.
  void set(int value);

  // A void method through a typedef: throws std::out_of_range for a negative
  // value, leaving the value unchanged.
  Nothing reset(int value);

  // Throws an int, which isn't a std::exception.
  void throwInt() const;

  // Throws a std::exception whose what() returns null.
  void throwNullWhat() const;

  // A borrowed pointer return: throws std::logic_error when fail is true.
  Thrower* self(bool fail);

  // A static method: throws std::runtime_error when fail is true.
  static int answer(bool fail);

  // Vectors of a class whose copy constructor can throw, which the glue of
  // the `std::vector` helpers calls. Never throw themselves.
  static std::vector<Copyable> copies(int value, int count);
  static int sumCopies(const std::vector<Copyable>& values);

  // How many guards are alive during this call: 1 when its glue constructed
  // one, and more if an earlier call leaked one.
  static int guardDepth();

  // How many guards have been constructed, including the one of this call.
  static int guardCount();

  // Makes the constructor of the guard of the next glue call throw
  // std::runtime_error.
  static void failNextGuard();

 private:
  int value_;
};

}  // namespace hooks
