// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test header for borrowed references: objects that a method returns by
// pointer or by reference, which the object it was called on owns.

#include <cstdint>

namespace borrow {

class StatusFlag {
 public:
  explicit StatusFlag(int32_t code);
  StatusFlag(const StatusFlag& other);
  ~StatusFlag();

  int32_t code() const;
  void setCode(int32_t code);
  bool equals(const StatusFlag& other) const;
  StatusFlag& operator=(const StatusFlag& other);

  static int32_t liveCount();

 private:
  int32_t code_;
};

class Property {
 public:
  Property(int32_t id, int32_t value);
  ~Property();

  int32_t id() const;
  int32_t value() const;
  void setValue(int32_t value);

  static int32_t liveCount();

 private:
  int32_t id_;
  int32_t value_;
};

// A list that owns its properties. Only a Device can create or delete one.
class PropertyList {
 public:
  int32_t size() const;
  Property* at(int32_t index);
  const Property* at(int32_t index) const;
  Property& front();

  // Removes the property at index, and returns it. The caller owns it.
  Property* release(int32_t index);

 private:
  friend class Device;
  PropertyList();
  ~PropertyList();

  static constexpr int32_t kCapacity = 3;
  Property* properties_[kCapacity];
  int32_t size_;
};

// A device that only a Core can create or delete.
class Device {
 public:
  int32_t id() const;
  const StatusFlag& status() const;
  StatusFlag& status();
  void setStatus(const StatusFlag& status);
  PropertyList& properties();
  Property* property(int32_t id);

  // The address of this device, which the wrappers' `pointer` returns.
  std::intptr_t address() const;

  // Named like members that every wrapper has, including those of Dart's
  // `Object`, so the bindings rename them.
  int32_t dispose() const;
  int32_t pointer() const;
  int32_t hashCode() const;
  int32_t toString() const;

 private:
  friend class Core;
  explicit Device(int32_t id);
  ~Device();

  int32_t id_;
  StatusFlag status_;
  PropertyList properties_;
};

class Core {
 public:
  explicit Core(int32_t deviceId);
  ~Core();

  Device& device();

  static int32_t liveCount();

 private:
  Device device_;
};

// A singleton, which the bindings can't delete.
class Registry {
 public:
  static Registry& instance();
  int32_t size() const;

 private:
  Registry();
  ~Registry();
};

}  // namespace borrow
