// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "cpp_std_vector_test.h"

namespace vec {

namespace {
int liveItems = 0;
}  // namespace

Point::Point(int x, int y) : x_(x), y_(y) {}
int Point::x() const { return x_; }
int Point::y() const { return y_; }

MoveOnly::MoveOnly(int value) : value_(value) {}
MoveOnly::MoveOnly(MoveOnly&& other) noexcept : value_(other.value_) {}
MoveOnly& MoveOnly::operator=(MoveOnly&& other) noexcept {
  value_ = other.value_;
  return *this;
}
int MoveOnly::value() const { return value_; }

Item::Item(const std::string& name) : name_(name) { ++liveItems; }
Item::~Item() { --liveItems; }
std::string Item::name() const { return name_; }
int Item::liveCount() { return liveItems; }

Registry::Registry(const std::vector<std::string>& itemNames) {
  for (const auto& name : itemNames) {
    items_.push_back(std::make_unique<Item>(name));
  }
}

std::vector<int> Registry::ints() const { return ints_; }

void Registry::setInts(const std::vector<int>& values) { ints_ = values; }

int Registry::sum(std::vector<int> values) const {
  int total = 0;
  for (int v : values) total += v;
  return total;
}

void Registry::appendInts(std::vector<int>&& values) {
  ints_.insert(ints_.end(), values.begin(), values.end());
  values.clear();
}

const std::vector<int>& Registry::intsRef() const { return ints_; }

Ints Registry::alias() const { return ints_; }

std::vector<std::size_t> Registry::sizes() const {
  std::vector<std::size_t> result;
  for (const auto& item : items_) result.push_back(item->name().size());
  return result;
}

std::vector<Id> Registry::ids(Id first, int count) const {
  std::vector<Id> result;
  for (int i = 0; i < count; ++i) result.push_back(first + i);
  return result;
}

std::vector<handle_t> Registry::handles() const { return {7, 8}; }

std::vector<Registry::Secret> Registry::secrets() const { return {9}; }

PtrVec<Item> Registry::itemPtrs() { return items(); }

UniqueVec<Item> Registry::makeUniqueItems(
    const std::vector<std::string>& names) {
  return makeItems(names);
}

std::vector<double> Registry::halves(const std::vector<int>& values) const {
  std::vector<double> result;
  for (int v : values) result.push_back(v / 2.0);
  return result;
}

std::vector<bool> Registry::parities(const std::vector<int>& values) const {
  std::vector<bool> result;
  for (int v : values) result.push_back(v % 2 == 0);
  return result;
}

std::vector<Color> Registry::colors() const {
  return {Color::red, Color::green, Color::blue, Color::red};
}

int Registry::countRed(const std::vector<Color>& colors) const {
  int count = 0;
  for (Color c : colors) count += c == Color::red ? 1 : 0;
  return count;
}

std::vector<std::string> Registry::names() const {
  std::vector<std::string> result;
  for (const auto& item : items_) result.push_back(item->name());
  return result;
}

std::string Registry::join(const std::vector<std::string>& parts,
                           const std::string& separator) {
  std::string result;
  for (std::size_t i = 0; i < parts.size(); ++i) {
    if (i > 0) result += separator;
    result += parts[i];
  }
  return result;
}

std::vector<Item*> Registry::items() {
  std::vector<Item*> result;
  for (auto& item : items_) result.push_back(item.get());
  return result;
}

std::vector<const Item*> Registry::constItems() const {
  std::vector<const Item*> result;
  for (const auto& item : items_) result.push_back(item.get());
  return result;
}

int Registry::indexOf(const std::vector<const Item*>& items,
                      const std::string& name) const {
  for (std::size_t i = 0; i < items.size(); ++i) {
    if (items[i]->name() == name) return static_cast<int>(i);
  }
  return -1;
}

std::vector<Point> Registry::points(int count) const {
  std::vector<Point> result;
  for (int i = 0; i < count; ++i) result.emplace_back(i, i * 10);
  return result;
}

int Registry::sumX(const std::vector<Point>& points) const {
  int total = 0;
  for (const auto& p : points) total += p.x();
  return total;
}

std::vector<Pair> Registry::pairs(int count) const {
  std::vector<Pair> result;
  for (int i = 0; i < count; ++i) result.push_back(Pair{i, -i});
  return result;
}

int Registry::sumPairs(const std::vector<Pair>& pairs) const {
  int total = 0;
  for (const auto& p : pairs) total += p.first * 100 + p.second;
  return total;
}

std::vector<std::unique_ptr<Item>> Registry::makeItems(
    const std::vector<std::string>& names) {
  std::vector<std::unique_ptr<Item>> result;
  for (const auto& name : names) result.push_back(std::make_unique<Item>(name));
  return result;
}

void Registry::adopt(std::vector<std::unique_ptr<Item>> items) {
  for (auto& item : items) items_.push_back(std::move(item));
}

int Registry::totalLength(const std::vector<std::unique_ptr<Item>>& items) {
  int total = 0;
  for (const auto& item : items) {
    total += static_cast<int>(item->name().size());
  }
  return total;
}

void Registry::adoptFirst(std::vector<std::unique_ptr<Item>>&& items) {
  if (!items.empty()) items_.push_back(std::move(items.front()));
}

std::vector<std::unique_ptr<const Item>> Registry::makeConstItems(
    const std::vector<std::string>& names) {
  std::vector<std::unique_ptr<const Item>> result;
  for (const auto& name : names) result.push_back(std::make_unique<Item>(name));
  return result;
}

std::vector<MoveOnly> Registry::moveOnlies(int count) const {
  std::vector<MoveOnly> result;
  for (int i = 0; i < count; ++i) result.emplace_back(i);
  return result;
}

int Registry::sumMoveOnlies(const std::vector<MoveOnly>& values) const {
  int total = 0;
  for (const auto& value : values) total += value.value();
  return total;
}

std::vector<std::vector<int>> Registry::grid(int rows, int columns) const {
  std::vector<std::vector<int>> result(rows);
  for (int r = 0; r < rows; ++r) {
    for (int c = 0; c < columns; ++c) result[r].push_back(r * columns + c);
  }
  return result;
}

int Registry::gridSum(const std::vector<std::vector<int>>& grid) {
  int total = 0;
  for (const auto& row : grid) {
    for (int v : row) total += v;
  }
  return total;
}

std::vector<std::vector<Item*>> Registry::itemsByLength() {
  std::vector<std::vector<Item*>> result;
  for (auto& item : items_) {
    const std::size_t length = item->name().size();
    if (result.size() <= length) result.resize(length + 1);
    result[length].push_back(item.get());
  }
  return result;
}

std::vector<int> Registry::range(int count) {
  std::vector<int> result;
  for (int i = 0; i < count; ++i) result.push_back(i);
  return result;
}

void Registry::fill(std::vector<int>& out) const { out = ints_; }

void Registry::fillPointer(std::vector<int>* out) const { *out = ints_; }

const std::vector<std::unique_ptr<Item>>& Registry::ownedItems() const {
  return items_;
}

}  // namespace vec

std::vector<int> freeInts() { return {1, 2, 3}; }
