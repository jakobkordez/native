// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "rename_deps_dep.h"

// None of the types below are declared in this header, so none of them are
// parsed as a top level binding. They only exist because these functions refer
// to them.
void use_struct(struct dep_struct *s);
void use_union(union dep_union *u);
void use_enum(enum dep_enum e);
void use_typedef(dep_typedef t);
