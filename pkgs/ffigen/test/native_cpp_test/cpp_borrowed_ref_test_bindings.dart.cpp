#include <memory>
#include "cpp_borrowed_ref_test.h"

#if defined(_WIN32)
#define FFIGEN_EXPORT __declspec(dllexport)
#else
#define FFIGEN_EXPORT
#endif

extern "C" {

FFIGEN_EXPORT borrow::Core* borrow_Core_new(int32_t deviceId) {
  return new borrow::Core(deviceId);
}

FFIGEN_EXPORT borrow::Device* borrow_Core_device(borrow::Core* self) {
  return std::addressof(self->device());
}

FFIGEN_EXPORT int32_t borrow_Core_liveCount() {
  return borrow::Core::liveCount();
}

FFIGEN_EXPORT void borrow_Core_delete(borrow::Core* self) {
  delete self;
}

FFIGEN_EXPORT int32_t borrow_Device_id(const borrow::Device* self) {
  return self->id();
}

FFIGEN_EXPORT borrow::StatusFlag* borrow_Device_statusConst(const borrow::Device* self) {
  return const_cast<borrow::StatusFlag*>(std::addressof(self->status()));
}

FFIGEN_EXPORT borrow::StatusFlag* borrow_Device_status(borrow::Device* self) {
  return std::addressof(self->status());
}

FFIGEN_EXPORT void borrow_Device_setStatus(borrow::Device* self, borrow::StatusFlag* status) {
  self->setStatus(*status);
}

FFIGEN_EXPORT borrow::PropertyList* borrow_Device_properties(borrow::Device* self) {
  return std::addressof(self->properties());
}

FFIGEN_EXPORT borrow::Property* borrow_Device_property(borrow::Device* self, int32_t id) {
  return self->property(id);
}

FFIGEN_EXPORT borrow::Property* borrow_Property_new(int32_t id, int32_t value) {
  return new borrow::Property(id, value);
}

FFIGEN_EXPORT int32_t borrow_Property_id(const borrow::Property* self) {
  return self->id();
}

FFIGEN_EXPORT int32_t borrow_Property_value(const borrow::Property* self) {
  return self->value();
}

FFIGEN_EXPORT void borrow_Property_setValue(borrow::Property* self, int32_t value) {
  self->setValue(value);
}

FFIGEN_EXPORT int32_t borrow_Property_liveCount() {
  return borrow::Property::liveCount();
}

FFIGEN_EXPORT void borrow_Property_delete(borrow::Property* self) {
  delete self;
}

FFIGEN_EXPORT int32_t borrow_PropertyList_size(const borrow::PropertyList* self) {
  return self->size();
}

FFIGEN_EXPORT borrow::Property* borrow_PropertyList_at(borrow::PropertyList* self, int32_t index) {
  return self->at(index);
}

FFIGEN_EXPORT borrow::Property* borrow_PropertyList_atConst(const borrow::PropertyList* self, int32_t index) {
  return const_cast<borrow::Property*>(self->at(index));
}

FFIGEN_EXPORT borrow::Property* borrow_PropertyList_front(borrow::PropertyList* self) {
  return std::addressof(self->front());
}

FFIGEN_EXPORT borrow::Property* borrow_PropertyList_release(borrow::PropertyList* self, int32_t index) {
  return self->release(index);
}

FFIGEN_EXPORT borrow::Registry* borrow_Registry_instance() {
  return std::addressof(borrow::Registry::instance());
}

FFIGEN_EXPORT int32_t borrow_Registry_size(const borrow::Registry* self) {
  return self->size();
}

FFIGEN_EXPORT borrow::StatusFlag* borrow_StatusFlag_new(int32_t code) {
  return new borrow::StatusFlag(code);
}

FFIGEN_EXPORT borrow::StatusFlag* borrow_StatusFlag_new_1(borrow::StatusFlag* other) {
  return new borrow::StatusFlag(*other);
}

FFIGEN_EXPORT int32_t borrow_StatusFlag_code(const borrow::StatusFlag* self) {
  return self->code();
}

FFIGEN_EXPORT void borrow_StatusFlag_setCode(borrow::StatusFlag* self, int32_t code) {
  self->setCode(code);
}

FFIGEN_EXPORT bool borrow_StatusFlag_equals(const borrow::StatusFlag* self, borrow::StatusFlag* other) {
  return self->equals(*other);
}

FFIGEN_EXPORT borrow::StatusFlag* borrow_StatusFlag_operatorAssign(borrow::StatusFlag* self, borrow::StatusFlag* other) {
  return std::addressof(self->operator=(*other));
}

FFIGEN_EXPORT int32_t borrow_StatusFlag_liveCount() {
  return borrow::StatusFlag::liveCount();
}

FFIGEN_EXPORT void borrow_StatusFlag_delete(borrow::StatusFlag* self) {
  delete self;
}

}
