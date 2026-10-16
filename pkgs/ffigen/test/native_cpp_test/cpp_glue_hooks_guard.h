// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef CPP_GLUE_HOOKS_GUARD_H_
#define CPP_GLUE_HOOKS_GUARD_H_

namespace hooks {

// The `Cpp.glueGuard` of cpp_glue_hooks_config.dart. It counts how many guards
// are alive and how many were ever constructed, so the tests can see that each
// glue call constructs exactly one, and releases it even when the call throws.
class CallGuard {
 public:
  // Throws std::runtime_error, without counting the guard, after failNext.
  CallGuard();
  ~CallGuard();

  CallGuard(const CallGuard&) = delete;
  CallGuard& operator=(const CallGuard&) = delete;

  static int depth();
  static int count();

  // Makes the constructor of the next guard throw.
  static void failNext();
};

}  // namespace hooks

#endif  // CPP_GLUE_HOOKS_GUARD_H_
