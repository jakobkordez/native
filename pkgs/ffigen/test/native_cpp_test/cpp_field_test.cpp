// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "cpp_field_test.h"

namespace fld {

namespace {
int32_t tagLiveCount = 0;
}  // namespace

Tag::Tag(int32_t id) : id(id) { ++tagLiveCount; }

Tag::Tag(const Tag& other) : id(other.id) { ++tagLiveCount; }

Tag::~Tag() { --tagLiveCount; }

int32_t Tag::liveCount() { return tagLiveCount; }

Frozen::Frozen(int32_t value) : value(value) {}

Sealed::Sealed(int32_t value) : value(value) {}

Settings::Settings() : flags(0) {}

View::View(Tag& tag) : tag(tag), constTag(tag) {}

int32_t Skipped::instances = 0;

Skipped::Skipped() : hidden{0}, anonymous{0}, values{}, callback(nullptr) {}

Base::Base() {}

Derived::Derived() {}

}  // namespace fld
