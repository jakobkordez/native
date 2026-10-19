#include <memory>
#include "cpp_field_test.h"

#if defined(_WIN32)
#define FFIGEN_EXPORT __declspec(dllexport)
#else
#define FFIGEN_EXPORT
#endif

extern "C" {

FFIGEN_EXPORT std::string* ffigen_dk8kux_std_string_new(const char* data, std::size_t size) {
  return new std::string(data, size);
}

FFIGEN_EXPORT const char* ffigen_dk8kux_std_string_data(const std::string* value) {
  return value->data();
}

FFIGEN_EXPORT std::size_t ffigen_dk8kux_std_string_size(const std::string* value) {
  return value->size();
}

FFIGEN_EXPORT void ffigen_dk8kux_std_string_delete(std::string* value) {
  delete value;
}

FFIGEN_EXPORT std::vector<int32_t>* ffigen_dk8kux_std_vector_1v1oco8_new(std::size_t capacity) {
  auto* self = new std::vector<int32_t>();
  self->reserve(capacity);
  return self;
}

FFIGEN_EXPORT void ffigen_dk8kux_std_vector_1v1oco8_push(std::vector<int32_t>* self, int32_t value) {
  self->push_back(value);
}

FFIGEN_EXPORT std::size_t ffigen_dk8kux_std_vector_1v1oco8_size(const std::vector<int32_t>* self) {
  return self->size();
}

FFIGEN_EXPORT int32_t ffigen_dk8kux_std_vector_1v1oco8_get(std::vector<int32_t>* self, std::size_t index) {
  return std::move((*self)[index]);
}

FFIGEN_EXPORT void ffigen_dk8kux_std_vector_1v1oco8_delete(std::vector<int32_t>* self) {
  delete self;
}

FFIGEN_EXPORT std::vector<std::string>* ffigen_dk8kux_std_vector_ymkc9d_new(std::size_t capacity) {
  auto* self = new std::vector<std::string>();
  self->reserve(capacity);
  return self;
}

FFIGEN_EXPORT void ffigen_dk8kux_std_vector_ymkc9d_push(std::vector<std::string>* self, std::string* value) {
  self->push_back(std::move(*value));
}

FFIGEN_EXPORT std::size_t ffigen_dk8kux_std_vector_ymkc9d_size(const std::vector<std::string>* self) {
  return self->size();
}

FFIGEN_EXPORT std::string* ffigen_dk8kux_std_vector_ymkc9d_get(std::vector<std::string>* self, std::size_t index) {
  return new std::string(std::move((*self)[index]));
}

FFIGEN_EXPORT void ffigen_dk8kux_std_vector_ymkc9d_delete(std::vector<std::string>* self) {
  delete self;
}

FFIGEN_EXPORT fld::Base* fld_Base_new() {
  return new fld::Base();
}

FFIGEN_EXPORT int32_t fld_Base_get_baseValue(fld::Base* self) {
  return self->baseValue;
}

FFIGEN_EXPORT void fld_Base_set_baseValue(fld::Base* self, int32_t value) {
  self->baseValue = value;
}

FFIGEN_EXPORT int32_t fld_Base_get_shadowed(fld::Base* self) {
  return self->shadowed;
}

FFIGEN_EXPORT void fld_Base_set_shadowed(fld::Base* self, int32_t value) {
  self->shadowed = value;
}

FFIGEN_EXPORT void fld_Base_delete(fld::Base* self) {
  delete self;
}

FFIGEN_EXPORT fld::Derived* fld_Derived_new() {
  return new fld::Derived();
}

FFIGEN_EXPORT int32_t fld_Derived_get_derivedValue(fld::Derived* self) {
  return self->derivedValue;
}

FFIGEN_EXPORT void fld_Derived_set_derivedValue(fld::Derived* self, int32_t value) {
  self->derivedValue = value;
}

FFIGEN_EXPORT int32_t fld_Derived_get_shadowed(fld::Derived* self) {
  return self->shadowed;
}

FFIGEN_EXPORT void fld_Derived_set_shadowed(fld::Derived* self, int32_t value) {
  self->shadowed = value;
}

FFIGEN_EXPORT int32_t fld_Derived_get_baseValue(fld::Derived* self) {
  return static_cast<fld::Base*>(self)->baseValue;
}

FFIGEN_EXPORT void fld_Derived_set_baseValue(fld::Derived* self, int32_t value) {
  static_cast<fld::Base*>(self)->baseValue = value;
}

FFIGEN_EXPORT int32_t fld_Derived_get_shadowed_1(fld::Derived* self) {
  return static_cast<fld::Base*>(self)->shadowed;
}

FFIGEN_EXPORT void fld_Derived_set_shadowed_1(fld::Derived* self, int32_t value) {
  static_cast<fld::Base*>(self)->shadowed = value;
}

FFIGEN_EXPORT void fld_Derived_delete(fld::Derived* self) {
  delete self;
}

FFIGEN_EXPORT fld::Frozen* fld_Frozen_new(int32_t value) {
  return new fld::Frozen(value);
}

FFIGEN_EXPORT int32_t fld_Frozen_get_value(fld::Frozen* self) {
  return self->value;
}

FFIGEN_EXPORT void fld_Frozen_delete(fld::Frozen* self) {
  delete self;
}

FFIGEN_EXPORT fld::Sealed* fld_Sealed_new(int32_t value) {
  return new fld::Sealed(value);
}

FFIGEN_EXPORT fld::Sealed* fld_Sealed_new_1(fld::Sealed* other) {
  return new fld::Sealed(*other);
}

FFIGEN_EXPORT int32_t fld_Sealed_get_value(fld::Sealed* self) {
  return self->value;
}

FFIGEN_EXPORT void fld_Sealed_set_value(fld::Sealed* self, int32_t value) {
  self->value = value;
}

FFIGEN_EXPORT void fld_Sealed_delete(fld::Sealed* self) {
  delete self;
}

FFIGEN_EXPORT fld::Settings* fld_Settings_new() {
  return new fld::Settings();
}

FFIGEN_EXPORT int32_t fld_Settings_get_retries(fld::Settings* self) {
  return self->retries;
}

FFIGEN_EXPORT void fld_Settings_set_retries(fld::Settings* self, int32_t value) {
  self->retries = value;
}

FFIGEN_EXPORT double fld_Settings_get_ratio(fld::Settings* self) {
  return self->ratio;
}

FFIGEN_EXPORT void fld_Settings_set_ratio(fld::Settings* self, double value) {
  self->ratio = value;
}

FFIGEN_EXPORT bool fld_Settings_get_verbose(fld::Settings* self) {
  return self->verbose;
}

FFIGEN_EXPORT void fld_Settings_set_verbose(fld::Settings* self, bool value) {
  self->verbose = value;
}

FFIGEN_EXPORT fld::Mode fld_Settings_get_mode(fld::Settings* self) {
  return self->mode;
}

FFIGEN_EXPORT void fld_Settings_set_mode(fld::Settings* self, fld::Mode value) {
  self->mode = value;
}

FFIGEN_EXPORT uint8_t fld_Settings_get_flags(fld::Settings* self) {
  return self->flags;
}

FFIGEN_EXPORT void fld_Settings_set_flags(fld::Settings* self, uint8_t value) {
  self->flags = value;
}

FFIGEN_EXPORT std::string* fld_Settings_get_name(fld::Settings* self) {
  return new std::string(self->name);
}

FFIGEN_EXPORT void fld_Settings_set_name(fld::Settings* self, std::string* value) {
  self->name = std::move(*value);
}

FFIGEN_EXPORT std::vector<int32_t>* fld_Settings_get_levels(fld::Settings* self) {
  return new std::vector<int32_t>(self->levels);
}

FFIGEN_EXPORT void fld_Settings_set_levels(fld::Settings* self, std::vector<int32_t>* value) {
  self->levels = std::move(*value);
}

FFIGEN_EXPORT std::vector<std::string>* fld_Settings_get_aliases(fld::Settings* self) {
  return new std::vector<std::string>(self->aliases);
}

FFIGEN_EXPORT void fld_Settings_set_aliases(fld::Settings* self, std::vector<std::string>* value) {
  self->aliases = std::move(*value);
}

FFIGEN_EXPORT fld::Vec2 fld_Settings_get_origin(fld::Settings* self) {
  return self->origin;
}

FFIGEN_EXPORT void fld_Settings_set_origin(fld::Settings* self, fld::Vec2 value) {
  self->origin = value;
}

FFIGEN_EXPORT fld::Tag* fld_Settings_get_tag(fld::Settings* self) {
  return std::addressof(self->tag);
}

FFIGEN_EXPORT void fld_Settings_set_tag(fld::Settings* self, fld::Tag* value) {
  self->tag = *value;
}

FFIGEN_EXPORT fld::Frozen* fld_Settings_get_frozen(fld::Settings* self) {
  return std::addressof(self->frozen);
}

FFIGEN_EXPORT fld::Sealed* fld_Settings_get_sealed(fld::Settings* self) {
  return std::addressof(self->sealed);
}

FFIGEN_EXPORT int32_t fld_Settings_get_version(fld::Settings* self) {
  return self->version;
}

FFIGEN_EXPORT fld::Tag* fld_Settings_get_link(fld::Settings* self) {
  return self->link;
}

FFIGEN_EXPORT void fld_Settings_set_link(fld::Settings* self, fld::Tag* value) {
  self->link = value;
}

FFIGEN_EXPORT char * fld_Settings_get_label(fld::Settings* self) {
  return const_cast<char *>(self->label);
}

FFIGEN_EXPORT void fld_Settings_set_label(fld::Settings* self, char * value) {
  self->label = value;
}

FFIGEN_EXPORT fld::Tag* fld_Settings_get_owned(fld::Settings* self) {
  return self->owned.get();
}

FFIGEN_EXPORT void fld_Settings_set_owned(fld::Settings* self, fld::Tag* value) {
  self->owned = std::unique_ptr<fld::Tag>(value);
}

FFIGEN_EXPORT fld::Tag* fld_Settings_get_ownedConst(fld::Settings* self) {
  return const_cast<fld::Tag*>(self->ownedConst.get());
}

FFIGEN_EXPORT void fld_Settings_set_ownedConst(fld::Settings* self, fld::Tag* value) {
  self->ownedConst = std::unique_ptr<fld::Tag>(value);
}

FFIGEN_EXPORT int32_t fld_Settings_get_pointer(fld::Settings* self) {
  return self->pointer;
}

FFIGEN_EXPORT void fld_Settings_set_pointer(fld::Settings* self, int32_t value) {
  self->pointer = value;
}

FFIGEN_EXPORT int32_t fld_Settings_get_renamed(fld::Settings* self) {
  return self->renamed;
}

FFIGEN_EXPORT void fld_Settings_set_renamed(fld::Settings* self, int32_t value) {
  self->renamed = value;
}

FFIGEN_EXPORT void fld_Settings_delete(fld::Settings* self) {
  delete self;
}

FFIGEN_EXPORT fld::Skipped* fld_Skipped_new() {
  return new fld::Skipped();
}

FFIGEN_EXPORT int32_t fld_Skipped_get_visible(fld::Skipped* self) {
  return self->visible;
}

FFIGEN_EXPORT void fld_Skipped_set_visible(fld::Skipped* self, int32_t value) {
  self->visible = value;
}

FFIGEN_EXPORT void fld_Skipped_delete(fld::Skipped* self) {
  delete self;
}

FFIGEN_EXPORT fld::Tag* fld_Tag_new(int32_t id) {
  return new fld::Tag(id);
}

FFIGEN_EXPORT fld::Tag* fld_Tag_new_1(fld::Tag* other) {
  return new fld::Tag(*other);
}

FFIGEN_EXPORT int32_t fld_Tag_liveCount() {
  return fld::Tag::liveCount();
}

FFIGEN_EXPORT int32_t fld_Tag_get_id(fld::Tag* self) {
  return self->id;
}

FFIGEN_EXPORT void fld_Tag_set_id(fld::Tag* self, int32_t value) {
  self->id = value;
}

FFIGEN_EXPORT void fld_Tag_delete(fld::Tag* self) {
  delete self;
}

FFIGEN_EXPORT fld::View* fld_View_new(fld::Tag* tag) {
  return new fld::View(*tag);
}

FFIGEN_EXPORT fld::Tag* fld_View_get_tag(fld::View* self) {
  return std::addressof(self->tag);
}

FFIGEN_EXPORT fld::Tag* fld_View_get_constTag(fld::View* self) {
  return const_cast<fld::Tag*>(std::addressof(self->constTag));
}

FFIGEN_EXPORT void fld_View_delete(fld::View* self) {
  delete self;
}

}
