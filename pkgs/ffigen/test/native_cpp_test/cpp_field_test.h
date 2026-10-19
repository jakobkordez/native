// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test header for the public fields of C++ classes, which the bindings expose
// as getters and setters.

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace fld {

enum class Mode : int32_t { kOff = 0, kOn = 1, kAuto = 2 };

// A POD struct, bound as a plain struct, which a field holds by value.
struct Vec2 {
  double x;
  double y;
};

// A class that counts its live instances, so tests can check ownership. Its
// copy assignment operator is implicit.
class Tag {
 public:
  explicit Tag(int32_t id);
  Tag(const Tag& other);
  ~Tag();

  static int32_t liveCount();

  int32_t id;
};

// A class whose implicit copy assignment operator is deleted, because of its
// const field.
class Frozen {
 public:
  explicit Frozen(int32_t value);

  const int32_t value;
};

// A class whose copy assignment operator is explicitly deleted.
class Sealed {
 public:
  explicit Sealed(int32_t value);
  Sealed(const Sealed& other) = default;
  Sealed& operator=(const Sealed& other) = delete;

  int32_t value;
};

// A struct that isn't POD, because of its default member initializers and its
// std::string field, so it gets the C++ class treatment. All of its fields
// are public.
struct Settings {
  Settings();

  int32_t retries = 3;
  double ratio = 0.5;
  bool verbose = false;
  Mode mode = Mode::kAuto;
  std::uint8_t flags : 4;
  std::string name = "default";
  std::vector<int32_t> levels;
  std::vector<std::string> aliases;
  Vec2 origin{1.5, -2.5};

  // C++ classes by value. The getters return references, and the setters copy
  // assign, if the class can be copy assigned.
  Tag tag{1};
  Frozen frozen{7};
  Sealed sealed{8};

  // Read only.
  const int32_t version = 2;

  // Pointers. The getter of a pointer to const casts the const away.
  Tag* link = nullptr;
  const char* label = "label";

  // The getters return the pointers they hold. The setters take ownership.
  std::unique_ptr<Tag> owned;
  std::unique_ptr<const Tag> ownedConst;

  // Named like members that every wrapper has, so the bindings rename it.
  int32_t pointer = 5;

  // The config renames this field.
  int32_t renamed = 6;

  // The config excludes this field.
  int32_t excluded = 7;
};

// A class with reference fields, which only get getters, since a reference
// can't be rebound.
class View {
 public:
  explicit View(Tag& tag);

  Tag& tag;
  const Tag& constTag;
};

// A class whose fields, except `visible`, the bindings skip.
class Skipped {
  struct Hidden {
    int32_t h;
  };

 public:
  Skipped();

  int32_t visible = 1;

  // Its type isn't public.
  Hidden hidden;

  // Its type is anonymous.
  struct {
    int32_t a;
  } anonymous;

  // Arrays and function pointers aren't supported.
  int32_t values[3];
  void (*callback)(int32_t);

  // A vector of unique_ptrs can't be copied, which the getter does.
  std::vector<std::unique_ptr<Tag>> tags;

  // Static data members aren't fields.
  static int32_t instances;

 private:
  int32_t secret_ = 42;
};

struct Base {
  Base();

  int32_t baseValue = 10;
  int32_t shadowed = 1;
};

struct Derived : Base {
  Derived();

  int32_t derivedValue = 20;

  // Hides Base::shadowed, which the bindings still expose under its name, so
  // that Derived implements Base. This one gets a suffix.
  int32_t shadowed = 2;
};

}  // namespace fld
