// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "cpp_enum_as_int_test.h"

namespace eai {

Gauge::Gauge(int raw) : raw_(raw) {}

Level Gauge::level() const { return static_cast<Level>(raw_); }

void Gauge::setLevel(Level level) { raw_ = static_cast<int>(level); }

}  // namespace eai
