// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "cpp_value_reference_test.h"

Box::Box(const geo::Extent& extent) : extent_(extent) {}

const geo::Extent& Box::extent() const { return extent_; }

geo::Extent& Box::mutableExtent() { return extent_; }

void Box::grow(const int& by) {
  extent_.width += by;
  extent_.height += by;
}

void Box::readInto(geo::Extent& out) const { out = extent_; }

long& Box::areaInto(long& area) const {
  area = static_cast<long>(extent_.width) * extent_.height;
  return area;
}

const geo::Unit& Box::unit() const { return unit_; }

void Box::setUnit(const geo::Unit& unit) { unit_ = unit; }

geo::Unit& Box::unitRef() { return unit_; }
