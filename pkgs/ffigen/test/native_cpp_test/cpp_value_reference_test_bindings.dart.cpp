#include <memory>
#include "cpp_value_reference_test.h"

#if defined(_WIN32)
#define FFIGEN_EXPORT __declspec(dllexport)
#else
#define FFIGEN_EXPORT
#endif

extern "C" {

FFIGEN_EXPORT Box* Box_new(geo::Extent extent) {
  return new Box(extent);
}

FFIGEN_EXPORT geo::Extent Box_extent(const Box* self) {
  return self->extent();
}

FFIGEN_EXPORT geo::Extent* Box_mutableExtent(Box* self) {
  return std::addressof(self->mutableExtent());
}

FFIGEN_EXPORT void Box_grow(Box* self, int by) {
  self->grow(by);
}

FFIGEN_EXPORT void Box_readInto(const Box* self, geo::Extent* out) {
  self->readInto(*out);
}

FFIGEN_EXPORT long* Box_areaInto(const Box* self, long* area) {
  return std::addressof(self->areaInto(*area));
}

FFIGEN_EXPORT geo::Unit Box_unit(const Box* self) {
  return self->unit();
}

FFIGEN_EXPORT void Box_setUnit(Box* self, geo::Unit unit) {
  self->setUnit(unit);
}

FFIGEN_EXPORT geo::Unit* Box_unitRef(Box* self) {
  return std::addressof(self->unitRef());
}

FFIGEN_EXPORT void Box_delete(Box* self) {
  delete self;
}

}
