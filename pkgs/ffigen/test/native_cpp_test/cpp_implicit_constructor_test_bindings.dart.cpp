#include <memory>
#include "cpp_implicit_constructor_test.h"

#if defined(_WIN32)
#define FFIGEN_EXPORT __declspec(dllexport)
#else
#define FFIGEN_EXPORT
#endif

extern "C" {

FFIGEN_EXPORT int AbstractNamed_id(const AbstractNamed* self) {
  return self->id();
}

FFIGEN_EXPORT std::string* AbstractNamed_get_name(AbstractNamed* self) {
  return new std::string(self->name);
}

FFIGEN_EXPORT void AbstractNamed_set_name(AbstractNamed* self, std::string* value) {
  self->name = std::move(*value);
}

FFIGEN_EXPORT void AbstractNamed_delete(AbstractNamed* self) {
  delete self;
}



FFIGEN_EXPORT std::string* DerivesHidden_get_other(DerivesHidden* self) {
  return new std::string(self->other);
}

FFIGEN_EXPORT void DerivesHidden_set_other(DerivesHidden* self, std::string* value) {
  self->other = std::move(*value);
}

FFIGEN_EXPORT std::string* DerivesHidden_get_name(DerivesHidden* self) {
  return new std::string(static_cast<HiddenDefault*>(self)->name);
}

FFIGEN_EXPORT void DerivesHidden_set_name(DerivesHidden* self, std::string* value) {
  static_cast<HiddenDefault*>(self)->name = std::move(*value);
}

FFIGEN_EXPORT void DerivesHidden_delete(DerivesHidden* self) {
  delete self;
}



FFIGEN_EXPORT std::string* HiddenDefault_get_name(HiddenDefault* self) {
  return new std::string(self->name);
}

FFIGEN_EXPORT void HiddenDefault_set_name(HiddenDefault* self, std::string* value) {
  self->name = std::move(*value);
}

FFIGEN_EXPORT void HiddenDefault_delete(HiddenDefault* self) {
  delete self;
}



FFIGEN_EXPORT int HoldsConst_get_fixed(HoldsConst* self) {
  return self->fixed;
}

FFIGEN_EXPORT std::string* HoldsConst_get_name(HoldsConst* self) {
  return new std::string(self->name);
}

FFIGEN_EXPORT void HoldsConst_set_name(HoldsConst* self, std::string* value) {
  self->name = std::move(*value);
}

FFIGEN_EXPORT void HoldsConst_delete(HoldsConst* self) {
  delete self;
}



FFIGEN_EXPORT NeedsArg* HoldsNeedsArg_get_inner(HoldsNeedsArg* self) {
  return std::addressof(self->inner);
}

FFIGEN_EXPORT void HoldsNeedsArg_set_inner(HoldsNeedsArg* self, NeedsArg* value) {
  self->inner = *value;
}

FFIGEN_EXPORT void HoldsNeedsArg_delete(HoldsNeedsArg* self) {
  delete self;
}

FFIGEN_EXPORT Labelled* Labelled_new() {
  return new Labelled();
}

FFIGEN_EXPORT std::string* Labelled_get_label(Labelled* self) {
  return new std::string(self->label);
}

FFIGEN_EXPORT void Labelled_set_label(Labelled* self, std::string* value) {
  self->label = std::move(*value);
}

FFIGEN_EXPORT void Labelled_delete(Labelled* self) {
  delete self;
}

FFIGEN_EXPORT LabelledSettings* LabelledSettings_new() {
  return new LabelledSettings();
}

FFIGEN_EXPORT Settings* LabelledSettings_get_settings(LabelledSettings* self) {
  return std::addressof(self->settings);
}

FFIGEN_EXPORT void LabelledSettings_set_settings(LabelledSettings* self, Settings* value) {
  self->settings = *value;
}

FFIGEN_EXPORT std::string* LabelledSettings_get_label(LabelledSettings* self) {
  return new std::string(static_cast<Labelled*>(self)->label);
}

FFIGEN_EXPORT void LabelledSettings_set_label(LabelledSettings* self, std::string* value) {
  static_cast<Labelled*>(self)->label = std::move(*value);
}

FFIGEN_EXPORT void LabelledSettings_delete(LabelledSettings* self) {
  delete self;
}

FFIGEN_EXPORT NeedsArg* NeedsArg_new(int value) {
  return new NeedsArg(value);
}

FFIGEN_EXPORT int NeedsArg_get_value(NeedsArg* self) {
  return self->value;
}

FFIGEN_EXPORT void NeedsArg_set_value(NeedsArg* self, int value) {
  self->value = value;
}

FFIGEN_EXPORT void NeedsArg_delete(NeedsArg* self) {
  delete self;
}

FFIGEN_EXPORT Settings* Settings_new() {
  return new Settings();
}

FFIGEN_EXPORT std::string* Settings_get_name(Settings* self) {
  return new std::string(self->name);
}

FFIGEN_EXPORT void Settings_set_name(Settings* self, std::string* value) {
  self->name = std::move(*value);
}

FFIGEN_EXPORT int Settings_get_retries(Settings* self) {
  return self->retries;
}

FFIGEN_EXPORT void Settings_set_retries(Settings* self, int value) {
  self->retries = value;
}

FFIGEN_EXPORT std::vector<int>* Settings_get_ports(Settings* self) {
  return new std::vector<int>(self->ports);
}

FFIGEN_EXPORT void Settings_set_ports(Settings* self, std::vector<int>* value) {
  self->ports = std::move(*value);
}

FFIGEN_EXPORT void Settings_delete(Settings* self) {
  delete self;
}

FFIGEN_EXPORT std::string* ffigen_17p7jt5_std_string_new(const char* data, std::size_t size) {
  return new std::string(data, size);
}

FFIGEN_EXPORT const char* ffigen_17p7jt5_std_string_data(const std::string* value) {
  return value->data();
}

FFIGEN_EXPORT std::size_t ffigen_17p7jt5_std_string_size(const std::string* value) {
  return value->size();
}

FFIGEN_EXPORT void ffigen_17p7jt5_std_string_delete(std::string* value) {
  delete value;
}

FFIGEN_EXPORT std::vector<int>* ffigen_17p7jt5_std_vector_1uqfy5y_new(std::size_t capacity) {
  auto* self = new std::vector<int>();
  self->reserve(capacity);
  return self;
}

FFIGEN_EXPORT void ffigen_17p7jt5_std_vector_1uqfy5y_push(std::vector<int>* self, int value) {
  self->push_back(value);
}

FFIGEN_EXPORT std::size_t ffigen_17p7jt5_std_vector_1uqfy5y_size(const std::vector<int>* self) {
  return self->size();
}

FFIGEN_EXPORT int ffigen_17p7jt5_std_vector_1uqfy5y_get(std::vector<int>* self, std::size_t index) {
  return std::move((*self)[index]);
}

FFIGEN_EXPORT void ffigen_17p7jt5_std_vector_1uqfy5y_delete(std::vector<int>* self) {
  delete self;
}

}
