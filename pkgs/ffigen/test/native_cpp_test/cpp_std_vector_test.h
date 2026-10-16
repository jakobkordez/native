// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

// C++ methods and constructors can take and return `std::vector`, which Dart
// code sees as a `List`.

namespace lib {
typedef int handle_t;
}  // namespace lib

namespace vec {

enum class Color { red, green, blue };

using Id = std::uint32_t;

using Ints = std::vector<int>;

// A typedef named through a using-declaration, which the glue can't name
// outside of this namespace.
using lib::handle_t;

// Alias templates, whose template arguments aren't the vector's.
template <class T>
using PtrVec = std::vector<T*>;
template <class T>
using UniqueVec = std::vector<std::unique_ptr<T>>;

// A POD struct, bound as a Dart struct, which the vectors hold by value.
struct Pair {
  int first;
  int second;
};

// A class that the vectors hold by value, as copies that the Dart objects
// own.
class Point {
 public:
  Point(int x, int y);

  int x() const;
  int y() const;

 private:
  int x_;
  int y_;
};

// A class that can only be moved, so a vector of it can be returned, but not
// copied from a Dart `List`.
class MoveOnly {
 public:
  explicit MoveOnly(int value);
  MoveOnly(MoveOnly&& other) noexcept;
  MoveOnly(const MoveOnly&) = delete;
  MoveOnly& operator=(MoveOnly&& other) noexcept;
  MoveOnly& operator=(const MoveOnly&) = delete;

  int value() const;

 private:
  int value_;
};

// A class that the vectors hold pointers to.
class Item {
 public:
  explicit Item(const std::string& name);
  virtual ~Item();

  std::string name() const;

  // The number of Items alive, to check that the bindings delete them.
  static int liveCount();

 private:
  std::string name_;
};

// Owns Items, and returns vectors of every supported element type.
class Registry {
  // A private typedef, which the glue can't name.
  using Secret = int;

 public:
  // A vector parameter of a constructor.
  explicit Registry(const std::vector<std::string>& itemNames);

  // Numbers: return by value, and parameters by const reference, by value
  // and by rvalue reference.
  std::vector<int> ints() const;
  void setInts(const std::vector<int>& values);
  int sum(std::vector<int> values) const;
  void appendInts(std::vector<int>&& values);

  // Return by const reference.
  const std::vector<int>& intsRef() const;

  // A vector spelled through an alias.
  Ints alias() const;

  // Elements spelled through typedefs, which the glue keeps, since
  // `std::size_t` isn't the same type on every platform.
  std::vector<std::size_t> sizes() const;
  std::vector<Id> ids(Id first, int count) const;

  // Elements spelled through typedefs that the glue can't name, so it spells
  // the types they stand for.
  std::vector<handle_t> handles() const;
  std::vector<Secret> secrets() const;

  // Vectors spelled through alias templates.
  PtrVec<Item> itemPtrs();
  static UniqueVec<Item> makeUniqueItems(const std::vector<std::string>& names);

  std::vector<double> halves(const std::vector<int>& values) const;

  // The `std::vector<bool>` specialization, which has no contiguous storage.
  std::vector<bool> parities(const std::vector<int>& values) const;

  // Enums.
  std::vector<Color> colors() const;
  int countRed(const std::vector<Color>& colors) const;

  // Strings.
  std::vector<std::string> names() const;
  static std::string join(const std::vector<std::string>& parts,
                          const std::string& separator);

  // Pointers to classes, which the Dart objects borrow from the Registry.
  std::vector<Item*> items();
  std::vector<const Item*> constItems() const;
  int indexOf(const std::vector<const Item*>& items,
              const std::string& name) const;

  // Classes by value.
  std::vector<Point> points(int count) const;
  int sumX(const std::vector<Point>& points) const;

  // POD structs.
  std::vector<Pair> pairs(int count) const;
  int sumPairs(const std::vector<Pair>& pairs) const;

  // `std::unique_ptr`s, which the Dart objects own.
  static std::vector<std::unique_ptr<Item>> makeItems(
      const std::vector<std::string>& names);
  void adopt(std::vector<std::unique_ptr<Item>> items);

  // `std::unique_ptr`s that C++ only looks at, or only takes some of, so the
  // Dart objects keep the ownership of the others.
  static int totalLength(const std::vector<std::unique_ptr<Item>>& items);
  void adoptFirst(std::vector<std::unique_ptr<Item>>&& items);

  // `std::unique_ptr`s to const, which the Dart objects own like the others.
  static std::vector<std::unique_ptr<const Item>> makeConstItems(
      const std::vector<std::string>& names);

  // A class that can only be moved.
  std::vector<MoveOnly> moveOnlies(int count) const;

  // Not bound: passing the vector would copy its elements.
  int sumMoveOnlies(const std::vector<MoveOnly>& values) const;

  // Nested vectors.
  std::vector<std::vector<int>> grid(int rows, int columns) const;
  static int gridSum(const std::vector<std::vector<int>>& grid);
  std::vector<std::vector<Item*>> itemsByLength();

  // A static method.
  static std::vector<int> range(int count);

  // Not bound: a callee could modify the vector through a mutable reference,
  // which would not be reflected in the Dart `List`.
  void fill(std::vector<int>& out) const;

  // Not bound: only `std::vector` itself is converted, not pointers to it.
  void fillPointer(std::vector<int>* out) const;

  // Not bound: a `std::vector` of `std::unique_ptr`s can't be copied, which
  // returning it by reference would need.
  const std::vector<std::unique_ptr<Item>>& ownedItems() const;

 private:
  std::vector<int> ints_;
  std::vector<std::unique_ptr<Item>> items_;
};

}  // namespace vec

// Not bound: free functions are called without generated glue, so they can't
// convert a `std::vector`.
std::vector<int> freeInts();
