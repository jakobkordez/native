#include <memory>
#include "cpp_pod_test.h"

#if defined(_WIN32)
#define FFIGEN_EXPORT __declspec(dllexport)
#else
#define FFIGEN_EXPORT
#endif

extern "C" {

FFIGEN_EXPORT NamedRange* NamedRange_new() {
  return new NamedRange();
}

FFIGEN_EXPORT std::string* NamedRange_get_name(NamedRange* self) {
  return new std::string(self->name);
}

FFIGEN_EXPORT void NamedRange_set_name(NamedRange* self, std::string* value) {
  self->name = std::move(*value);
}

FFIGEN_EXPORT int NamedRange_get_lo(NamedRange* self) {
  return self->lo;
}

FFIGEN_EXPORT void NamedRange_set_lo(NamedRange* self, int value) {
  self->lo = value;
}

FFIGEN_EXPORT void NamedRange_delete(NamedRange* self) {
  delete self;
}

FFIGEN_EXPORT NonAggregateRange* NonAggregateRange_new() {
  return new NonAggregateRange();
}

FFIGEN_EXPORT int NonAggregateRange_get_lo(NonAggregateRange* self) {
  return self->lo;
}

FFIGEN_EXPORT void NonAggregateRange_set_lo(NonAggregateRange* self, int value) {
  self->lo = value;
}

FFIGEN_EXPORT int NonAggregateRange_get_hi(NonAggregateRange* self) {
  return self->hi;
}

FFIGEN_EXPORT void NonAggregateRange_set_hi(NonAggregateRange* self, int value) {
  self->hi = value;
}

FFIGEN_EXPORT void NonAggregateRange_delete(NonAggregateRange* self) {
  delete self;
}

FFIGEN_EXPORT NonPodCounter* NonPodCounter_new(int start) {
  return new NonPodCounter(start);
}

FFIGEN_EXPORT int NonPodCounter_next(NonPodCounter* self) {
  return self->next();
}

FFIGEN_EXPORT void NonPodCounter_delete(NonPodCounter* self) {
  delete self;
}

FFIGEN_EXPORT std::string* ffigen_rg5f62_std_string_new(const char* data, std::size_t size) {
  return new std::string(data, size);
}

FFIGEN_EXPORT const char* ffigen_rg5f62_std_string_data(const std::string* value) {
  return value->data();
}

FFIGEN_EXPORT std::size_t ffigen_rg5f62_std_string_size(const std::string* value) {
  return value->size();
}

FFIGEN_EXPORT void ffigen_rg5f62_std_string_delete(std::string* value) {
  delete value;
}

}
