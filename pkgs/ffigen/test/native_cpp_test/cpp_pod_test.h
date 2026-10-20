// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Whether a record is bound as a plain C struct or as a C++ class is decided
// by whether it is POD (plain old data), or a plain aggregate, not by the
// `class`/`struct` keyword: the two keywords differ only in default member
// access.

#include <memory>
#include <string>

// A POD record declared with the `class` keyword. It is bound as a plain C
// struct with its fields modelled.
class PodPoint {
 public:
  int x;
  int y;
};

// A POD record declared with the `struct` keyword, for parity.
struct PodPair {
  int a;
  int b;
};

// A record declared with the `struct` keyword that is not POD: the
// user-declared constructor and the private field both disqualify it, so it
// gets the C++ class treatment instead.
struct NonPodCounter {
  NonPodCounter(int start);
  int next();

 private:
  int value_;
};

// A record that isn't POD only because its default member initializers make
// its default constructor non-trivial. It's a plain aggregate, with the layout
// and the copy semantics of a C struct, so it's bound as one, and a C function
// can take and return it by value. Its method isn't bound.
struct AggregateRange {
  int lo = -1;
  int hi = -1;

  bool isEmpty() const { return hi < lo; }
};

// A plain aggregate can hold plain aggregates and POD records.
struct AggregateSpan {
  AggregateRange range;
  PodPair pairs[2];
  double weight = 1.0;
};

// Like AggregateRange, but with a user-declared constructor, which makes it
// not an aggregate, so it gets the C++ class treatment.
struct NonAggregateRange {
  NonAggregateRange();

  int lo = -1;
  int hi = -1;
};

// A field of a class template's instantiation, here std::string, keeps a
// record from being a plain aggregate, though libclang doesn't expose the
// instantiation's members.
struct NamedRange {
  std::string name;
  int lo = -1;
};

// Returning a record that isn't POD from a C function warns, and ffigen stops
// on warnings.
#if defined(__clang__)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wreturn-type-c-linkage"
#elif defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable : 4190)
#endif

#if defined(_WIN32)
#define POD_EXPORT __declspec(dllexport)
#else
#define POD_EXPORT
#endif

extern "C" {

POD_EXPORT AggregateRange widenRange(AggregateRange range, int by);

// A C++ class is bound as a pointer to the object, so a C function can't take
// or return one by value, nor can a function pointer: all of these are
// skipped.
int counterNext(NonPodCounter counter);
NonPodCounter makeCounter(int start);
int adoptCounter(std::unique_ptr<NonPodCounter> counter);
typedef int (*CounterCallback)(NonPodCounter counter);
int callWithCounter(CounterCallback callback);
extern NonPodCounter sharedCounter;

// The members of a union holding a C++ class by value are removed.
union CounterOrInt {
  int i;
  NonPodCounter counter;
};

}  // extern "C"

#if defined(__clang__)
#pragma clang diagnostic pop
#elif defined(_MSC_VER)
#pragma warning(pop)
#endif
