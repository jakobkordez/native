#include <memory>
#include "cpp_overload_test.h"

#if defined(_WIN32)
#define FFIGEN_EXPORT __declspec(dllexport)
#else
#define FFIGEN_EXPORT
#endif

extern "C" {

FFIGEN_EXPORT std::string* ffigen_1jybc2n_std_string_new(const char* data, std::size_t size) {
  return new std::string(data, size);
}

FFIGEN_EXPORT const char* ffigen_1jybc2n_std_string_data(const std::string* value) {
  return value->data();
}

FFIGEN_EXPORT std::size_t ffigen_1jybc2n_std_string_size(const std::string* value) {
  return value->size();
}

FFIGEN_EXPORT void ffigen_1jybc2n_std_string_delete(std::string* value) {
  delete value;
}

FFIGEN_EXPORT lab::Experiment* lab_Experiment_new() {
  return new lab::Experiment();
}

FFIGEN_EXPORT lab::Experiment* lab_Experiment_new_1(int32_t id) {
  return new lab::Experiment(id);
}

FFIGEN_EXPORT lab::Experiment* lab_Experiment_new_2(int32_t id, double weight) {
  return new lab::Experiment(id, weight);
}

FFIGEN_EXPORT lab::Properties* lab_Experiment_propertiesConst(const lab::Experiment* self) {
  return const_cast<lab::Properties*>(self->properties());
}

FFIGEN_EXPORT lab::Properties* lab_Experiment_properties(lab::Experiment* self) {
  return self->properties();
}

FFIGEN_EXPORT int32_t * lab_Experiment_resultsConst(const lab::Experiment* self) {
  return const_cast<int32_t *>(self->results());
}

FFIGEN_EXPORT int32_t * lab_Experiment_results(lab::Experiment* self) {
  return self->results();
}

FFIGEN_EXPORT std::string* lab_Experiment_streamsConst(const lab::Experiment* self) {
  return new std::string(self->streams());
}

FFIGEN_EXPORT std::string* lab_Experiment_streams(lab::Experiment* self) {
  return new std::string(self->streams());
}

FFIGEN_EXPORT int32_t lab_Experiment_getId(const lab::Experiment* self) {
  return self->getId();
}

FFIGEN_EXPORT double lab_Experiment_getWeight(const lab::Experiment* self) {
  return self->getWeight();
}

FFIGEN_EXPORT int32_t lab_Experiment_add(const lab::Experiment* self, int32_t a, int32_t b) {
  return self->add(a, b);
}

FFIGEN_EXPORT double lab_Experiment_add_1(const lab::Experiment* self, double a, double b) {
  return self->add(a, b);
}

FFIGEN_EXPORT int32_t lab_Experiment_add_2(const lab::Experiment* self, int32_t a, int32_t b, int32_t c) {
  return self->add(a, b, c);
}

FFIGEN_EXPORT std::string* lab_Experiment_add_3(const lab::Experiment* self, std::string* a, std::string* b) {
  return new std::string(self->add(std::move(*a), std::move(*b)));
}

FFIGEN_EXPORT int32_t lab_Experiment_scale(int32_t value) {
  return lab::Experiment::scale(value);
}

FFIGEN_EXPORT double lab_Experiment_scale_1(double value) {
  return lab::Experiment::scale(value);
}

FFIGEN_EXPORT int32_t lab_Experiment_describe(const lab::Experiment* self) {
  return self->describe();
}

FFIGEN_EXPORT int32_t lab_Experiment_describe_1(const lab::Experiment* self, int32_t detail) {
  return self->describe(detail);
}

FFIGEN_EXPORT bool lab_Experiment_operatorEqual(const lab::Experiment* self, int32_t id) {
  return self->operator==(id);
}

FFIGEN_EXPORT int32_t lab_Experiment_operatorSubscript(const lab::Experiment* self, int32_t index) {
  return self->operator[](index);
}

FFIGEN_EXPORT int32_t lab_Experiment_operatorCall(const lab::Experiment* self, int32_t value) {
  return self->operator()(value);
}

FFIGEN_EXPORT int32_t lab_Experiment_operatorCall_1(const lab::Experiment* self, int32_t a, int32_t b) {
  return self->operator()(a, b);
}

FFIGEN_EXPORT lab::Experiment* lab_Experiment_operatorPostIncrement(lab::Experiment* self, int arg0) {
  return new lab::Experiment(self->operator++(arg0));
}

FFIGEN_EXPORT lab::Experiment* lab_Experiment_operatorPlus(const lab::Experiment* self, int32_t delta) {
  return new lab::Experiment(self->operator+(delta));
}

FFIGEN_EXPORT lab::Experiment* lab_Experiment_operatorNegate(const lab::Experiment* self) {
  return new lab::Experiment(self->operator-());
}

FFIGEN_EXPORT lab::Experiment* lab_Experiment_operatorMinus(const lab::Experiment* self, int32_t delta) {
  return new lab::Experiment(self->operator-(delta));
}

FFIGEN_EXPORT bool lab_Experiment_operatorLogicalNot(const lab::Experiment* self) {
  return self->operator!();
}

FFIGEN_EXPORT void lab_Experiment_delete(lab::Experiment* self) {
  delete self;
}

FFIGEN_EXPORT lab::Properties* lab_Properties_new(int32_t limit) {
  return new lab::Properties(limit);
}

FFIGEN_EXPORT int32_t lab_Properties_getLimit(const lab::Properties* self) {
  return self->getLimit();
}

FFIGEN_EXPORT void lab_Properties_setLimit(lab::Properties* self, int32_t limit) {
  self->setLimit(limit);
}

FFIGEN_EXPORT void lab_Properties_delete(lab::Properties* self) {
  delete self;
}

FFIGEN_EXPORT lab::Refinement* lab_Refinement_new(int32_t id) {
  return new lab::Refinement(id);
}

FFIGEN_EXPORT double lab_Refinement_add(const lab::Refinement* self, double a, double b) {
  return static_cast<const lab::Variant*>(self)->add(a, b);
}

FFIGEN_EXPORT int32_t lab_Refinement_describe(const lab::Refinement* self, int32_t detail) {
  return static_cast<const lab::Variant*>(self)->describe(detail);
}

FFIGEN_EXPORT lab::Properties* lab_Refinement_propertiesConst(const lab::Refinement* self) {
  return const_cast<lab::Properties*>(static_cast<const lab::Experiment*>(self)->properties());
}

FFIGEN_EXPORT lab::Properties* lab_Refinement_properties(lab::Refinement* self) {
  return static_cast<lab::Experiment*>(self)->properties();
}

FFIGEN_EXPORT int32_t * lab_Refinement_resultsConst(const lab::Refinement* self) {
  return const_cast<int32_t *>(static_cast<const lab::Experiment*>(self)->results());
}

FFIGEN_EXPORT int32_t * lab_Refinement_results(lab::Refinement* self) {
  return static_cast<lab::Experiment*>(self)->results();
}

FFIGEN_EXPORT std::string* lab_Refinement_streamsConst(const lab::Refinement* self) {
  return new std::string(static_cast<const lab::Experiment*>(self)->streams());
}

FFIGEN_EXPORT std::string* lab_Refinement_streams(lab::Refinement* self) {
  return new std::string(static_cast<lab::Experiment*>(self)->streams());
}

FFIGEN_EXPORT int32_t lab_Refinement_getId(const lab::Refinement* self) {
  return static_cast<const lab::Experiment*>(self)->getId();
}

FFIGEN_EXPORT double lab_Refinement_getWeight(const lab::Refinement* self) {
  return static_cast<const lab::Experiment*>(self)->getWeight();
}

FFIGEN_EXPORT int32_t lab_Refinement_add_1(const lab::Refinement* self, int32_t a, int32_t b) {
  return static_cast<const lab::Experiment*>(self)->add(a, b);
}

FFIGEN_EXPORT int32_t lab_Refinement_add_2(const lab::Refinement* self, int32_t a, int32_t b, int32_t c) {
  return static_cast<const lab::Experiment*>(self)->add(a, b, c);
}

FFIGEN_EXPORT std::string* lab_Refinement_add_3(const lab::Refinement* self, std::string* a, std::string* b) {
  return new std::string(static_cast<const lab::Experiment*>(self)->add(std::move(*a), std::move(*b)));
}

FFIGEN_EXPORT int32_t lab_Refinement_scale(int32_t value) {
  return lab::Experiment::scale(value);
}

FFIGEN_EXPORT double lab_Refinement_scale_1(double value) {
  return lab::Experiment::scale(value);
}

FFIGEN_EXPORT int32_t lab_Refinement_describe_1(const lab::Refinement* self) {
  return static_cast<const lab::Experiment*>(self)->describe();
}

FFIGEN_EXPORT bool lab_Refinement_operatorEqual(const lab::Refinement* self, int32_t id) {
  return static_cast<const lab::Experiment*>(self)->operator==(id);
}

FFIGEN_EXPORT int32_t lab_Refinement_operatorSubscript(const lab::Refinement* self, int32_t index) {
  return static_cast<const lab::Experiment*>(self)->operator[](index);
}

FFIGEN_EXPORT int32_t lab_Refinement_operatorCall(const lab::Refinement* self, int32_t value) {
  return static_cast<const lab::Experiment*>(self)->operator()(value);
}

FFIGEN_EXPORT int32_t lab_Refinement_operatorCall_1(const lab::Refinement* self, int32_t a, int32_t b) {
  return static_cast<const lab::Experiment*>(self)->operator()(a, b);
}

FFIGEN_EXPORT lab::Experiment* lab_Refinement_operatorPostIncrement(lab::Refinement* self, int arg0) {
  return new lab::Experiment(static_cast<lab::Experiment*>(self)->operator++(arg0));
}

FFIGEN_EXPORT lab::Experiment* lab_Refinement_operatorPlus(const lab::Refinement* self, int32_t delta) {
  return new lab::Experiment(static_cast<const lab::Experiment*>(self)->operator+(delta));
}

FFIGEN_EXPORT lab::Experiment* lab_Refinement_operatorNegate(const lab::Refinement* self) {
  return new lab::Experiment(static_cast<const lab::Experiment*>(self)->operator-());
}

FFIGEN_EXPORT lab::Experiment* lab_Refinement_operatorMinus(const lab::Refinement* self, int32_t delta) {
  return new lab::Experiment(static_cast<const lab::Experiment*>(self)->operator-(delta));
}

FFIGEN_EXPORT bool lab_Refinement_operatorLogicalNot(const lab::Refinement* self) {
  return static_cast<const lab::Experiment*>(self)->operator!();
}

FFIGEN_EXPORT void lab_Refinement_delete(lab::Refinement* self) {
  delete self;
}

FFIGEN_EXPORT lab::Variant* lab_Variant_new(int32_t id) {
  return new lab::Variant(id);
}

FFIGEN_EXPORT double lab_Variant_add(const lab::Variant* self, double a, double b) {
  return self->add(a, b);
}

FFIGEN_EXPORT int32_t lab_Variant_describe(const lab::Variant* self, int32_t detail) {
  return self->describe(detail);
}

FFIGEN_EXPORT lab::Properties* lab_Variant_propertiesConst(const lab::Variant* self) {
  return const_cast<lab::Properties*>(static_cast<const lab::Experiment*>(self)->properties());
}

FFIGEN_EXPORT lab::Properties* lab_Variant_properties(lab::Variant* self) {
  return static_cast<lab::Experiment*>(self)->properties();
}

FFIGEN_EXPORT int32_t * lab_Variant_resultsConst(const lab::Variant* self) {
  return const_cast<int32_t *>(static_cast<const lab::Experiment*>(self)->results());
}

FFIGEN_EXPORT int32_t * lab_Variant_results(lab::Variant* self) {
  return static_cast<lab::Experiment*>(self)->results();
}

FFIGEN_EXPORT std::string* lab_Variant_streamsConst(const lab::Variant* self) {
  return new std::string(static_cast<const lab::Experiment*>(self)->streams());
}

FFIGEN_EXPORT std::string* lab_Variant_streams(lab::Variant* self) {
  return new std::string(static_cast<lab::Experiment*>(self)->streams());
}

FFIGEN_EXPORT int32_t lab_Variant_getId(const lab::Variant* self) {
  return static_cast<const lab::Experiment*>(self)->getId();
}

FFIGEN_EXPORT double lab_Variant_getWeight(const lab::Variant* self) {
  return static_cast<const lab::Experiment*>(self)->getWeight();
}

FFIGEN_EXPORT int32_t lab_Variant_add_1(const lab::Variant* self, int32_t a, int32_t b) {
  return static_cast<const lab::Experiment*>(self)->add(a, b);
}

FFIGEN_EXPORT int32_t lab_Variant_add_2(const lab::Variant* self, int32_t a, int32_t b, int32_t c) {
  return static_cast<const lab::Experiment*>(self)->add(a, b, c);
}

FFIGEN_EXPORT std::string* lab_Variant_add_3(const lab::Variant* self, std::string* a, std::string* b) {
  return new std::string(static_cast<const lab::Experiment*>(self)->add(std::move(*a), std::move(*b)));
}

FFIGEN_EXPORT int32_t lab_Variant_scale(int32_t value) {
  return lab::Experiment::scale(value);
}

FFIGEN_EXPORT double lab_Variant_scale_1(double value) {
  return lab::Experiment::scale(value);
}

FFIGEN_EXPORT int32_t lab_Variant_describe_1(const lab::Variant* self) {
  return static_cast<const lab::Experiment*>(self)->describe();
}

FFIGEN_EXPORT bool lab_Variant_operatorEqual(const lab::Variant* self, int32_t id) {
  return static_cast<const lab::Experiment*>(self)->operator==(id);
}

FFIGEN_EXPORT int32_t lab_Variant_operatorSubscript(const lab::Variant* self, int32_t index) {
  return static_cast<const lab::Experiment*>(self)->operator[](index);
}

FFIGEN_EXPORT int32_t lab_Variant_operatorCall(const lab::Variant* self, int32_t value) {
  return static_cast<const lab::Experiment*>(self)->operator()(value);
}

FFIGEN_EXPORT int32_t lab_Variant_operatorCall_1(const lab::Variant* self, int32_t a, int32_t b) {
  return static_cast<const lab::Experiment*>(self)->operator()(a, b);
}

FFIGEN_EXPORT lab::Experiment* lab_Variant_operatorPostIncrement(lab::Variant* self, int arg0) {
  return new lab::Experiment(static_cast<lab::Experiment*>(self)->operator++(arg0));
}

FFIGEN_EXPORT lab::Experiment* lab_Variant_operatorPlus(const lab::Variant* self, int32_t delta) {
  return new lab::Experiment(static_cast<const lab::Experiment*>(self)->operator+(delta));
}

FFIGEN_EXPORT lab::Experiment* lab_Variant_operatorNegate(const lab::Variant* self) {
  return new lab::Experiment(static_cast<const lab::Experiment*>(self)->operator-());
}

FFIGEN_EXPORT lab::Experiment* lab_Variant_operatorMinus(const lab::Variant* self, int32_t delta) {
  return new lab::Experiment(static_cast<const lab::Experiment*>(self)->operator-(delta));
}

FFIGEN_EXPORT bool lab_Variant_operatorLogicalNot(const lab::Variant* self) {
  return static_cast<const lab::Experiment*>(self)->operator!();
}

FFIGEN_EXPORT void lab_Variant_delete(lab::Variant* self) {
  delete self;
}

}
