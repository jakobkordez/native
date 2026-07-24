// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A forward-declared class with no definition anywhere in the translation
// unit. Pointers to it should be generated as pointers to an opaque type,
// exactly like pointers to a definition-less struct.
class MyHandle;

// A forward-declared struct, for parity with the class above.
struct OtherHandle;

extern "C" {
MyHandle* my_handle_create(void);
void my_handle_destroy(MyHandle* h);
MyHandle* my_handle_clone(const MyHandle* h);

OtherHandle* other_handle_create(void);
}
