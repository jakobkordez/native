// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "cpp_glue_hooks_test.h"

#include <stdexcept>

#include "cpp_glue_hooks_guard.h"

namespace hooks {

namespace {
int guardDepth_ = 0;
int guardCount_ = 0;
bool failNextGuard_ = false;
int copyGuardDepth_ = 0;
int destroyGuardDepth_ = 0;

class NullWhatError : public std::exception {
 public:
  const char* what() const noexcept override { return nullptr; }
};
}  // namespace

CallGuard::CallGuard() {
  if (failNextGuard_) {
    failNextGuard_ = false;
    throw std::runtime_error("guard failed");
  }
  ++guardDepth_;
  ++guardCount_;
}

CallGuard::~CallGuard() { --guardDepth_; }

int CallGuard::depth() { return guardDepth_; }

int CallGuard::count() { return guardCount_; }

void CallGuard::failNext() { failNextGuard_ = true; }

Copyable::Copyable(int value) : value_(value) {}

Copyable::Copyable(const Copyable& other) : value_(other.value_) {
  copyGuardDepth_ = CallGuard::depth();
  if (value_ < 0) throw std::runtime_error("copy failed");
}

Copyable::~Copyable() { destroyGuardDepth_ = CallGuard::depth(); }

int Copyable::value() const { return value_; }

int Copyable::copyGuardDepth() { return copyGuardDepth_; }

int Copyable::destroyGuardDepth() { return destroyGuardDepth_; }

Thrower::Thrower(int value) : value_(value) {
  if (value < 0) throw std::invalid_argument("negative value");
}

int Thrower::value() const { return value_; }

int Thrower::divide(int divisor) const {
  if (divisor == 0) throw std::domain_error("division by zero");
  return value_ / divisor;
}

std::string Thrower::describe(bool fail) const {
  if (fail) throw std::runtime_error("cannot describe");
  return "Thrower(" + std::to_string(value_) + ")";
}

void Thrower::set(int value) {
  if (value < 0) throw std::out_of_range("negative value");
  value_ = value;
}

Nothing Thrower::reset(int value) {
  if (value < 0) throw std::out_of_range("negative value");
  value_ = value;
}

void Thrower::throwInt() const { throw 42; }

void Thrower::throwNullWhat() const { throw NullWhatError(); }

Thrower* Thrower::self(bool fail) {
  if (fail) throw std::logic_error("no self");
  return this;
}

int Thrower::answer(bool fail) {
  if (fail) throw std::runtime_error("no answer");
  return 42;
}

std::vector<Copyable> Thrower::copies(int value, int count) {
  std::vector<Copyable> result;
  // Reserved, so that growing the vector doesn't copy the elements.
  result.reserve(count);
  for (int i = 0; i < count; ++i) result.emplace_back(value);
  return result;
}

int Thrower::sumCopies(const std::vector<Copyable>& values) {
  int total = 0;
  for (const auto& value : values) total += value.value();
  return total;
}

int Thrower::guardDepth() { return CallGuard::depth(); }

int Thrower::guardCount() { return CallGuard::count(); }

void Thrower::failNextGuard() { CallGuard::failNext(); }

}  // namespace hooks
