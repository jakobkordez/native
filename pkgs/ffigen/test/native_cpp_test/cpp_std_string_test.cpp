// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "cpp_std_string_test.h"

#include <utility>

StringBox::StringBox(const std::string& value) : value_(value) {}

std::string StringBox::get() const { return value_; }

const std::string& StringBox::ref() const { return value_; }

void StringBox::set(std::string value) { value_ = std::move(value); }

void StringBox::append(const std::string& suffix) { value_ += suffix; }

void StringBox::prepend(std::string&& prefix) {
  value_ = std::move(prefix) + value_;
}

StringAlias StringBox::alias() const { return value_; }

std::string StringBox::repeat(const std::string& value, int times) {
  std::string result;
  for (int i = 0; i < times; ++i) result += value;
  return result;
}

int StringBox::size() const { return static_cast<int>(value_.size()); }

void StringBox::moveInto(std::string& out) { out = std::move(value_); }

void StringBox::setFrom(const std::string* value) { value_ = *value; }

std::string describe(const std::string& value) { return "<" + value + ">"; }
