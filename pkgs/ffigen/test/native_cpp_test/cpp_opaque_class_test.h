// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A forward-declared class with no definition anywhere in the translation
// unit. Pointers to it should be generated as pointers to an opaque type,
// exactly like pointers to a definition-less struct.
class MyHandle;

// A forward-declared struct, for parity with the class above.
struct OtherHandle;

// A class WITH a definition in this translation unit, used only through
// pointers. Its members cannot be modelled (and its layout would be wrong if
// they were: it is polymorphic), but a pointer to it is no less opaque than a
// pointer to the forward-declared class above, so the functions below must
// still be generated.
class DefinedHandle {
 public:
  virtual ~DefinedHandle() = default;
  virtual int value() const = 0;

 private:
  int state_;
};

extern "C" {
MyHandle* my_handle_create(void);
void my_handle_destroy(MyHandle* h);
MyHandle* my_handle_clone(const MyHandle* h);

OtherHandle* other_handle_create(void);

DefinedHandle* defined_handle_create(void);
void defined_handle_destroy(DefinedHandle* h);
}
