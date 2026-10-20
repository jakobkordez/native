// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// References to things other than C++ classes: a reference to const is passed
// by value, as a copy, and a mutable one as a pointer.

namespace geo {

// A plain aggregate, so it's bound as a struct.
struct Extent {
  int width = 0;
  int height = 0;
};

enum class Unit { millimeter = 1, centimeter = 10 };

}  // namespace geo

class Box {
 public:
  explicit Box(const geo::Extent& extent);

  // Returns a copy of the extent.
  const geo::Extent& extent() const;

  // Returns a pointer to the extent, which the box keeps.
  geo::Extent& mutableExtent();

  void grow(const int& by);

  // Copies the extent into `out`.
  void readInto(geo::Extent& out) const;

  // Writes the area into `area`, and returns `area`.
  long& areaInto(long& area) const;

  const geo::Unit& unit() const;
  void setUnit(const geo::Unit& unit);
  geo::Unit& unitRef();

 private:
  geo::Extent extent_;
  geo::Unit unit_ = geo::Unit::millimeter;
};
