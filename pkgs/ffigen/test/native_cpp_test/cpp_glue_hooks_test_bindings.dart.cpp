#include <memory>
#include "cpp_glue_hooks_test.h"
#include "cpp_glue_hooks_guard.h"
#include <cstddef>
#include <cstdlib>
#include <cstring>
#include <exception>

#if defined(_WIN32)
#define FFIGEN_EXPORT __declspec(dllexport)
#else
#define FFIGEN_EXPORT
#endif

static thread_local char* ffigen_1qtx5pv_exception_pending = nullptr;
static char ffigen_1qtx5pv_exception_out_of_memory[] =
    "out of memory while copying a C++ exception's message";

static void ffigen_1qtx5pv_exception_set(const char* what) noexcept {
  if (ffigen_1qtx5pv_exception_pending != ffigen_1qtx5pv_exception_out_of_memory) {
    std::free(ffigen_1qtx5pv_exception_pending);
  }
  if (what == nullptr) what = "a std::exception whose what() is null";
  const std::size_t size = std::strlen(what) + 1;
  auto* copy = static_cast<char*>(std::malloc(size));
  if (copy == nullptr) {
    ffigen_1qtx5pv_exception_pending = ffigen_1qtx5pv_exception_out_of_memory;
    return;
  }
  std::memcpy(copy, what, size);
  ffigen_1qtx5pv_exception_pending = copy;
}

static void ffigen_1qtx5pv_exception_catch() noexcept {
  try {
    throw;
  } catch (const std::exception& e) {
    ffigen_1qtx5pv_exception_set(e.what());
  } catch (...) {
    ffigen_1qtx5pv_exception_set("a C++ exception that isn't a std::exception");
  }
}

extern "C" {

FFIGEN_EXPORT char* ffigen_1qtx5pv_exception_take() {
  char* exception = ffigen_1qtx5pv_exception_pending;
  ffigen_1qtx5pv_exception_pending = nullptr;
  return exception;
}

FFIGEN_EXPORT void ffigen_1qtx5pv_exception_free(char* exception) {
  if (exception != ffigen_1qtx5pv_exception_out_of_memory) std::free(exception);
}

}

extern "C" {

FFIGEN_EXPORT std::string* ffigen_1qtx5pv_std_string_new(const char* data, std::size_t size) {
  return new std::string(data, size);
}

FFIGEN_EXPORT const char* ffigen_1qtx5pv_std_string_data(const std::string* value) {
  return value->data();
}

FFIGEN_EXPORT std::size_t ffigen_1qtx5pv_std_string_size(const std::string* value) {
  return value->size();
}

FFIGEN_EXPORT void ffigen_1qtx5pv_std_string_delete(std::string* value) {
  delete value;
}

FFIGEN_EXPORT hooks::Thrower* hooks_Thrower_new(int value) {
  try {
    const ::hooks::CallGuard ffigen_guard{};
    try {
      return new hooks::Thrower(value);
    } catch (...) {
      ffigen_1qtx5pv_exception_catch();
    }
  } catch (...) {
    ffigen_1qtx5pv_exception_catch();
  }
  return {};
}

FFIGEN_EXPORT int hooks_Thrower_value(const hooks::Thrower* self) {
  try {
    const ::hooks::CallGuard ffigen_guard{};
    try {
      return self->value();
    } catch (...) {
      ffigen_1qtx5pv_exception_catch();
    }
  } catch (...) {
    ffigen_1qtx5pv_exception_catch();
  }
  return {};
}

FFIGEN_EXPORT int hooks_Thrower_divide(const hooks::Thrower* self, int divisor) {
  try {
    const ::hooks::CallGuard ffigen_guard{};
    try {
      return self->divide(divisor);
    } catch (...) {
      ffigen_1qtx5pv_exception_catch();
    }
  } catch (...) {
    ffigen_1qtx5pv_exception_catch();
  }
  return {};
}

FFIGEN_EXPORT std::string* hooks_Thrower_describe(const hooks::Thrower* self, bool fail) {
  try {
    const ::hooks::CallGuard ffigen_guard{};
    try {
      return new std::string(self->describe(fail));
    } catch (...) {
      ffigen_1qtx5pv_exception_catch();
    }
  } catch (...) {
    ffigen_1qtx5pv_exception_catch();
  }
  return {};
}

FFIGEN_EXPORT void hooks_Thrower_set(hooks::Thrower* self, int value) {
  try {
    const ::hooks::CallGuard ffigen_guard{};
    try {
      self->set(value);
    } catch (...) {
      ffigen_1qtx5pv_exception_catch();
    }
  } catch (...) {
    ffigen_1qtx5pv_exception_catch();
  }
}

FFIGEN_EXPORT void hooks_Thrower_reset(hooks::Thrower* self, int value) {
  try {
    const ::hooks::CallGuard ffigen_guard{};
    try {
      self->reset(value);
    } catch (...) {
      ffigen_1qtx5pv_exception_catch();
    }
  } catch (...) {
    ffigen_1qtx5pv_exception_catch();
  }
}

FFIGEN_EXPORT void hooks_Thrower_throwInt(const hooks::Thrower* self) {
  try {
    const ::hooks::CallGuard ffigen_guard{};
    try {
      self->throwInt();
    } catch (...) {
      ffigen_1qtx5pv_exception_catch();
    }
  } catch (...) {
    ffigen_1qtx5pv_exception_catch();
  }
}

FFIGEN_EXPORT void hooks_Thrower_throwNullWhat(const hooks::Thrower* self) {
  try {
    const ::hooks::CallGuard ffigen_guard{};
    try {
      self->throwNullWhat();
    } catch (...) {
      ffigen_1qtx5pv_exception_catch();
    }
  } catch (...) {
    ffigen_1qtx5pv_exception_catch();
  }
}

FFIGEN_EXPORT hooks::Thrower* hooks_Thrower_self(hooks::Thrower* self, bool fail) {
  try {
    const ::hooks::CallGuard ffigen_guard{};
    try {
      return self->self(fail);
    } catch (...) {
      ffigen_1qtx5pv_exception_catch();
    }
  } catch (...) {
    ffigen_1qtx5pv_exception_catch();
  }
  return {};
}

FFIGEN_EXPORT int hooks_Thrower_answer(bool fail) {
  try {
    const ::hooks::CallGuard ffigen_guard{};
    try {
      return hooks::Thrower::answer(fail);
    } catch (...) {
      ffigen_1qtx5pv_exception_catch();
    }
  } catch (...) {
    ffigen_1qtx5pv_exception_catch();
  }
  return {};
}

FFIGEN_EXPORT int hooks_Thrower_guardDepth() {
  try {
    const ::hooks::CallGuard ffigen_guard{};
    try {
      return hooks::Thrower::guardDepth();
    } catch (...) {
      ffigen_1qtx5pv_exception_catch();
    }
  } catch (...) {
    ffigen_1qtx5pv_exception_catch();
  }
  return {};
}

FFIGEN_EXPORT int hooks_Thrower_guardCount() {
  try {
    const ::hooks::CallGuard ffigen_guard{};
    try {
      return hooks::Thrower::guardCount();
    } catch (...) {
      ffigen_1qtx5pv_exception_catch();
    }
  } catch (...) {
    ffigen_1qtx5pv_exception_catch();
  }
  return {};
}

FFIGEN_EXPORT void hooks_Thrower_failNextGuard() {
  try {
    const ::hooks::CallGuard ffigen_guard{};
    try {
      hooks::Thrower::failNextGuard();
    } catch (...) {
      ffigen_1qtx5pv_exception_catch();
    }
  } catch (...) {
    ffigen_1qtx5pv_exception_catch();
  }
}

FFIGEN_EXPORT void hooks_Thrower_delete(hooks::Thrower* self) {
  const ::hooks::CallGuard ffigen_guard{};
  delete self;
}

}
