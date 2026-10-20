#include <memory>
#include "cpp_enum_as_int_test.h"

#if defined(_WIN32)
#define FFIGEN_EXPORT __declspec(dllexport)
#else
#define FFIGEN_EXPORT
#endif

extern "C" {

FFIGEN_EXPORT eai::Gauge* eai_Gauge_new(int raw) {
  return new eai::Gauge(raw);
}

FFIGEN_EXPORT eai::Level eai_Gauge_level(const eai::Gauge* self) {
  return self->level();
}

FFIGEN_EXPORT void eai_Gauge_setLevel(eai::Gauge* self, eai::Level level) {
  self->setLevel(level);
}

FFIGEN_EXPORT void eai_Gauge_delete(eai::Gauge* self) {
  delete self;
}

}
