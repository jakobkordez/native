// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// An enum generated with EnumStyle.dartEnumPassedAsInt: a Dart enum, whose
// values the bindings pass as ints, so that a value the enum doesn't have
// reaches Dart rather than throwing in `fromValue`.

namespace eai {

enum class Level { kLow = 1, kHigh = 2 };

class Gauge {
 public:
  explicit Gauge(int raw);

  // Can return a value that Level doesn't have.
  Level level() const;
  void setLevel(Level level);

 private:
  int raw_;
};

}  // namespace eai
