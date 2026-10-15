#include <memory>
#include "cpp_std_string_test.h"

#if defined(_WIN32)
#define FFIGEN_EXPORT __declspec(dllexport)
#else
#define FFIGEN_EXPORT
#endif

extern "C" {

FFIGEN_EXPORT StringBox* StringBox_new(std::string* value) {
  return new StringBox(std::move(*value));
}

FFIGEN_EXPORT std::string* StringBox_get(const StringBox* self) {
  return new std::string(self->get());
}

FFIGEN_EXPORT std::string* StringBox_ref(const StringBox* self) {
  return new std::string(self->ref());
}

FFIGEN_EXPORT void StringBox_set(StringBox* self, std::string* value) {
  self->set(std::move(*value));
}

FFIGEN_EXPORT void StringBox_append(StringBox* self, std::string* suffix) {
  self->append(std::move(*suffix));
}

FFIGEN_EXPORT void StringBox_prepend(StringBox* self, std::string* prefix) {
  self->prepend(std::move(*prefix));
}

FFIGEN_EXPORT std::string* StringBox_alias(const StringBox* self) {
  return new std::string(self->alias());
}

FFIGEN_EXPORT std::string* StringBox_repeat(std::string* value, int times) {
  return new std::string(StringBox::repeat(std::move(*value), times));
}

FFIGEN_EXPORT int StringBox_size(const StringBox* self) {
  return self->size();
}

FFIGEN_EXPORT void StringBox_delete(StringBox* self) {
  delete self;
}

FFIGEN_EXPORT std::string* ffigen_19kj6vk_std_string_new(const char* data, std::size_t size) {
  return new std::string(data, size);
}

FFIGEN_EXPORT const char* ffigen_19kj6vk_std_string_data(const std::string* value) {
  return value->data();
}

FFIGEN_EXPORT std::size_t ffigen_19kj6vk_std_string_size(const std::string* value) {
  return value->size();
}

FFIGEN_EXPORT void ffigen_19kj6vk_std_string_delete(std::string* value) {
  delete value;
}

}
