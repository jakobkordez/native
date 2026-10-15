// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "cpp_overload_test.h"

namespace lab {

Experiment::Experiment() : Experiment(0, 1.0) {}

Experiment::Experiment(int32_t id) : Experiment(id, 1.0) {}

Experiment::Experiment(int32_t id, double weight)
    : id_(id), weight_(weight), properties_(10), results_{1, 2, 3, 4} {}

// The const overloads return values that differ from the non-const ones, so
// that tests can tell which overload was called.
const Properties* Experiment::properties() const { return &properties_; }

Properties* Experiment::properties() { return &properties_; }

const int32_t* Experiment::results() const { return results_ + 2; }

int32_t* Experiment::results() { return results_; }

std::string Experiment::streams() const { return "const streams"; }

std::string Experiment::streams() { return "streams"; }

int32_t Experiment::getId() const { return id_; }

double Experiment::getWeight() const { return weight_; }

int32_t Experiment::add(int32_t a, int32_t b) const { return a + b; }

double Experiment::add(double a, double b) const { return a + b + 0.5; }

int32_t Experiment::add(int32_t a, int32_t b, int32_t c) const {
  return a + b + c;
}

std::string Experiment::add(const std::string& a, const std::string& b) const {
  return a + b;
}

int32_t Experiment::scale(int32_t value) { return value * 2; }

double Experiment::scale(double value) { return value * 0.5; }

int32_t Experiment::describe() const { return 1; }

int32_t Experiment::describe(int32_t detail) const { return 100 + detail; }

bool Experiment::operator==(const Experiment& other) const {
  return id_ == other.id_;
}

bool Experiment::operator==(int32_t id) const { return id_ == id; }

bool Experiment::operator!=(const Experiment& other) const {
  return !(*this == other);
}

bool Experiment::operator<(const Experiment& other) const {
  return id_ < other.id_;
}

Experiment& Experiment::operator=(const Experiment& other) = default;

int32_t Experiment::operator[](int32_t index) const { return results_[index]; }

int32_t& Experiment::operator[](int32_t index) { return results_[index]; }

int32_t Experiment::operator()(int32_t value) const { return id_ * value; }

int32_t Experiment::operator()(int32_t a, int32_t b) const {
  return id_ * a + b;
}

Experiment& Experiment::operator++() {
  ++id_;
  return *this;
}

Experiment Experiment::operator++(int) {
  Experiment old = *this;
  ++id_;
  return old;
}

Experiment Experiment::operator+(int32_t delta) const {
  return Experiment(id_ + delta, weight_);
}

Experiment Experiment::operator-() const { return Experiment(-id_, weight_); }

Experiment Experiment::operator-(int32_t delta) const {
  return Experiment(id_ - delta, weight_);
}

bool Experiment::operator!() const { return id_ == 0; }

Experiment::operator bool() const { return id_ != 0; }

void* Experiment::operator new(std::size_t size) { return ::operator new(size); }

void Experiment::operator delete(void* ptr) { ::operator delete(ptr); }

Variant::Variant(int32_t id) : Experiment(id) {}

double Variant::add(double a, double b) const { return a * b; }

int32_t Variant::describe(int32_t detail) const { return 200 + detail; }

Refinement::Refinement(int32_t id) : Variant(id) {}

}  // namespace lab
