// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A class that declares no constructor has an implicit default constructor,
// unless a base or a field can't be default constructed.

#include <string>
#include <vector>

// Declares no constructor, so it gets a Dart constructor, which runs the
// default member initializers.
struct Settings {
  std::string name;
  int retries = 3;
  std::vector<int> ports;
};

class Labelled {
 public:
  Labelled();
  std::string label;
};

// Its base and its field can be default constructed.
struct LabelledSettings : public Labelled {
  Settings settings;
};

// A constructor whose parameters all have default arguments is a default
// constructor.
struct DefaultArg {
  explicit DefaultArg(int value = 7);
  int value;
};

struct HoldsDefaultArg {
  DefaultArg inner;
};

// None of the following get a Dart constructor.

struct NeedsArg {
  explicit NeedsArg(int value);
  int value;
};

// Its field can't be default constructed.
struct HoldsNeedsArg {
  NeedsArg inner;
};

// A const field counts as one that can't be default constructed, even with a
// default member initializer, since libclang doesn't expose it.
struct HoldsConst {
  const int fixed = 1;
  std::string name;
};

class HiddenDefault {
 public:
  std::string name;

 private:
  HiddenDefault();
};

// Its base's default constructor isn't accessible.
struct DerivesHidden : public HiddenDefault {
  std::string other;
};

// An abstract class can't be constructed.
class AbstractNamed {
 public:
  virtual ~AbstractNamed();
  virtual int id() const = 0;
  std::string name;
};
