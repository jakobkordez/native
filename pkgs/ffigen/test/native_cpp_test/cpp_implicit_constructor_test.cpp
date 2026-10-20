// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "cpp_implicit_constructor_test.h"

Labelled::Labelled() : label("unnamed") {}

NeedsArg::NeedsArg(int value) : value(value) {}

HiddenDefault::HiddenDefault() = default;

AbstractNamed::~AbstractNamed() = default;
