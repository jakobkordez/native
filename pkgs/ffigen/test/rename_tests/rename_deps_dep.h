// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This header is not an entry point, and is excluded by the config's header
// filter. Its declarations are only reachable as dependencies of the functions
// declared in `rename_deps.h`.

struct dep_struct
{
    int x;
};

union dep_union
{
    int i;
    float f;
};

enum dep_enum
{
    dep_a = 0,
    dep_b = 1
};

typedef struct dep_typedef_struct
{
    int y;
} dep_typedef;
