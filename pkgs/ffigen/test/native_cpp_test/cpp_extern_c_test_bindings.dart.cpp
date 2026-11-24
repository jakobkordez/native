#include <memory>
#include "cpp_extern_c_test.h"

#if defined(_WIN32)
#define FFIGEN_EXPORT __declspec(dllexport)
#else
#define FFIGEN_EXPORT
#endif

extern "C" {

FFIGEN_EXPORT Gauge* Gauge_new(int level) {
  return new Gauge(level);
}

FFIGEN_EXPORT int Gauge_level(const Gauge* self) {
  return self->level();
}

FFIGEN_EXPORT void Gauge_setLevel(Gauge* self, int level) {
  self->setLevel(level);
}

FFIGEN_EXPORT void Gauge_delete(Gauge* self) {
  delete self;
}

FFIGEN_EXPORT decltype(&aliasedGauge) ffigen_aliasedGauge() {
  return &aliasedGauge;
}

FFIGEN_EXPORT int ffigen_applyTwice(int (*fn)(int), int x) {
  return applyTwice(fn, x);
}

FFIGEN_EXPORT decltype(&cGauge) ffigen_cGauge() {
  return &cGauge;
}

FFIGEN_EXPORT decltype(&constGauge) ffigen_constGauge() {
  return &constGauge;
}

FFIGEN_EXPORT decltype(&gauge) ffigen_gauge() {
  return &gauge;
}

FFIGEN_EXPORT int ffigen_gaugeLevel() {
  return gaugeLevel();
}

FFIGEN_EXPORT int ffigen_nestedCpp(int x) {
  return nestedCpp(x);
}

FFIGEN_EXPORT int ffigen_outside(double d) {
  return outside(d);
}

FFIGEN_EXPORT decltype(&outsideCounter) ffigen_outsideCounter() {
  return &outsideCounter;
}

}
