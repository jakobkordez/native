// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "cpp_borrowed_ref_test.h"

namespace borrow {

namespace {
int32_t statusFlagCount = 0;
int32_t propertyCount = 0;
int32_t coreCount = 0;
}  // namespace

StatusFlag::StatusFlag(int32_t code) : code_(code) { ++statusFlagCount; }

StatusFlag::StatusFlag(const StatusFlag& other) : code_(other.code_) {
  ++statusFlagCount;
}

StatusFlag::~StatusFlag() { --statusFlagCount; }

int32_t StatusFlag::code() const { return code_; }

void StatusFlag::setCode(int32_t code) { code_ = code; }

bool StatusFlag::equals(const StatusFlag& other) const {
  return code_ == other.code_;
}

StatusFlag& StatusFlag::operator=(const StatusFlag& other) {
  code_ = other.code_;
  return *this;
}

int32_t StatusFlag::liveCount() { return statusFlagCount; }

Property::Property(int32_t id, int32_t value) : id_(id), value_(value) {
  ++propertyCount;
}

Property::~Property() { --propertyCount; }

int32_t Property::id() const { return id_; }

int32_t Property::value() const { return value_; }

void Property::setValue(int32_t value) { value_ = value; }

int32_t Property::liveCount() { return propertyCount; }

PropertyList::PropertyList() : size_(kCapacity) {
  for (int32_t i = 0; i < kCapacity; ++i) {
    properties_[i] = new Property(i + 1, (i + 1) * 10);
  }
}

PropertyList::~PropertyList() {
  for (int32_t i = 0; i < size_; ++i) {
    delete properties_[i];
  }
}

int32_t PropertyList::size() const { return size_; }

Property* PropertyList::at(int32_t index) { return properties_[index]; }

const Property* PropertyList::at(int32_t index) const {
  return properties_[index];
}

Property& PropertyList::front() { return *properties_[0]; }

Property* PropertyList::release(int32_t index) {
  Property* property = properties_[index];
  for (int32_t i = index; i < size_ - 1; ++i) {
    properties_[i] = properties_[i + 1];
  }
  --size_;
  return property;
}

Device::Device(int32_t id) : id_(id), status_(0) {}

Device::~Device() {}

int32_t Device::id() const { return id_; }

const StatusFlag& Device::status() const { return status_; }

StatusFlag& Device::status() { return status_; }

void Device::setStatus(const StatusFlag& status) { status_ = status; }

PropertyList& Device::properties() { return properties_; }

Property* Device::property(int32_t id) {
  for (int32_t i = 0; i < properties_.size(); ++i) {
    if (properties_.at(i)->id() == id) return properties_.at(i);
  }
  return nullptr;
}

Core::Core(int32_t deviceId) : device_(deviceId) { ++coreCount; }

Core::~Core() { --coreCount; }

Device& Core::device() { return device_; }

int32_t Core::liveCount() { return coreCount; }

Registry::Registry() {}

Registry::~Registry() {}

Registry& Registry::instance() {
  static Registry registry;
  return registry;
}

int32_t Registry::size() const { return 7; }

}  // namespace borrow
