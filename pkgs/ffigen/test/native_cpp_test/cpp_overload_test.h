// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test header for overloaded C++ methods, const/non-const method pairs and
// operators.

#include <cstddef>
#include <cstdint>
#include <string>

namespace lab {

class Properties {
 public:
  explicit Properties(int32_t limit) : limit_(limit) {}
  int32_t getLimit() const { return limit_; }
  void setLimit(int32_t limit) { limit_ = limit; }

 private:
  int32_t limit_;
};

class Experiment {
 public:
  // Overloaded constructors.
  Experiment();
  explicit Experiment(int32_t id);
  Experiment(int32_t id, double weight);
  virtual ~Experiment() = default;

  // Const/non-const pairs. Each pair has the same parameter list.
  const Properties* properties() const;
  Properties* properties();

  const int32_t* results() const;
  int32_t* results();

  std::string streams() const;
  std::string streams();

  int32_t getId() const;
  double getWeight() const;

  // Overloads that differ in their parameter types or count.
  int32_t add(int32_t a, int32_t b) const;
  double add(double a, double b) const;
  int32_t add(int32_t a, int32_t b, int32_t c) const;
  std::string add(const std::string& a, const std::string& b) const;

  // Static overloads.
  static int32_t scale(int32_t value);
  static double scale(double value);

  // A virtual overload set, partially overridden by the subclass below.
  virtual int32_t describe() const;
  virtual int32_t describe(int32_t detail) const;

  // Operators. The ones taking or returning a reference to a class are
  // skipped, since references to classes aren't supported.
  bool operator==(const Experiment& other) const;
  bool operator==(int32_t id) const;
  bool operator!=(const Experiment& other) const;
  bool operator<(const Experiment& other) const;
  Experiment& operator=(const Experiment& other);
  int32_t operator[](int32_t index) const;
  int32_t& operator[](int32_t index);
  int32_t operator()(int32_t value) const;
  int32_t operator()(int32_t a, int32_t b) const;
  Experiment& operator++();
  Experiment operator++(int);
  Experiment operator+(int32_t delta) const;
  Experiment operator-() const;
  Experiment operator-(int32_t delta) const;
  bool operator!() const;
  explicit operator bool() const;
  static void* operator new(std::size_t size);
  static void operator delete(void* ptr);

 private:
  int32_t id_;
  double weight_;
  Properties properties_;
  int32_t results_[4];
};

class Variant : public Experiment {
 public:
  explicit Variant(int32_t id);

  // Hides every Experiment::add overload from name lookup on a Variant.
  double add(double a, double b) const;

  // Overrides one overload of Experiment::describe and hides the other.
  int32_t describe(int32_t detail) const override;
};

// Inherits the overloads hidden by Variant.
class Refinement : public Variant {
 public:
  explicit Refinement(int32_t id);
};

}  // namespace lab
