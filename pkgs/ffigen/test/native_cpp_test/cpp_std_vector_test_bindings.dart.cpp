#include <memory>
#include "cpp_std_vector_test.h"

#if defined(_WIN32)
#define FFIGEN_EXPORT __declspec(dllexport)
#else
#define FFIGEN_EXPORT
#endif

extern "C" {

FFIGEN_EXPORT std::string* ffigen_gbvei2_std_string_new(const char* data, std::size_t size) {
  return new std::string(data, size);
}

FFIGEN_EXPORT const char* ffigen_gbvei2_std_string_data(const std::string* value) {
  return value->data();
}

FFIGEN_EXPORT std::size_t ffigen_gbvei2_std_string_size(const std::string* value) {
  return value->size();
}

FFIGEN_EXPORT void ffigen_gbvei2_std_string_delete(std::string* value) {
  delete value;
}

FFIGEN_EXPORT std::size_t ffigen_gbvei2_std_vector_1jbktjf_size(const std::vector<bool>* self) {
  return self->size();
}

FFIGEN_EXPORT bool ffigen_gbvei2_std_vector_1jbktjf_get(std::vector<bool>* self, std::size_t index) {
  return std::move((*self)[index]);
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_1jbktjf_delete(std::vector<bool>* self) {
  delete self;
}

FFIGEN_EXPORT std::vector<const vec::Item*>* ffigen_gbvei2_std_vector_1u9e5b3_new(std::size_t capacity) {
  auto* self = new std::vector<const vec::Item*>();
  self->reserve(capacity);
  return self;
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_1u9e5b3_push(std::vector<const vec::Item*>* self, vec::Item* value) {
  self->push_back(value);
}

FFIGEN_EXPORT std::size_t ffigen_gbvei2_std_vector_1u9e5b3_size(const std::vector<const vec::Item*>* self) {
  return self->size();
}

FFIGEN_EXPORT vec::Item* ffigen_gbvei2_std_vector_1u9e5b3_get(std::vector<const vec::Item*>* self, std::size_t index) {
  return const_cast<vec::Item*>(std::move((*self)[index]));
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_1u9e5b3_delete(std::vector<const vec::Item*>* self) {
  delete self;
}

FFIGEN_EXPORT std::size_t ffigen_gbvei2_std_vector_11xl6ts_size(const std::vector<double>* self) {
  return self->size();
}

FFIGEN_EXPORT double ffigen_gbvei2_std_vector_11xl6ts_get(std::vector<double>* self, std::size_t index) {
  return std::move((*self)[index]);
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_11xl6ts_delete(std::vector<double>* self) {
  delete self;
}

FFIGEN_EXPORT std::vector<int>* ffigen_gbvei2_std_vector_1uqfy5y_new(std::size_t capacity) {
  auto* self = new std::vector<int>();
  self->reserve(capacity);
  return self;
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_1uqfy5y_push(std::vector<int>* self, int value) {
  self->push_back(value);
}

FFIGEN_EXPORT std::size_t ffigen_gbvei2_std_vector_1uqfy5y_size(const std::vector<int>* self) {
  return self->size();
}

FFIGEN_EXPORT int ffigen_gbvei2_std_vector_1uqfy5y_get(std::vector<int>* self, std::size_t index) {
  return std::move((*self)[index]);
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_1uqfy5y_delete(std::vector<int>* self) {
  delete self;
}

FFIGEN_EXPORT std::size_t ffigen_gbvei2_std_vector_tjfug8_size(const std::vector<std::size_t>* self) {
  return self->size();
}

FFIGEN_EXPORT size_t ffigen_gbvei2_std_vector_tjfug8_get(std::vector<std::size_t>* self, std::size_t index) {
  return std::move((*self)[index]);
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_tjfug8_delete(std::vector<std::size_t>* self) {
  delete self;
}

FFIGEN_EXPORT std::vector<std::string>* ffigen_gbvei2_std_vector_ymkc9d_new(std::size_t capacity) {
  auto* self = new std::vector<std::string>();
  self->reserve(capacity);
  return self;
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_ymkc9d_push(std::vector<std::string>* self, std::string* value) {
  self->push_back(std::move(*value));
}

FFIGEN_EXPORT std::size_t ffigen_gbvei2_std_vector_ymkc9d_size(const std::vector<std::string>* self) {
  return self->size();
}

FFIGEN_EXPORT std::string* ffigen_gbvei2_std_vector_ymkc9d_get(std::vector<std::string>* self, std::size_t index) {
  return new std::string(std::move((*self)[index]));
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_ymkc9d_delete(std::vector<std::string>* self) {
  delete self;
}

FFIGEN_EXPORT std::size_t ffigen_gbvei2_std_vector_tfmct4_size(const std::vector<std::unique_ptr<const vec::Item>>* self) {
  return self->size();
}

FFIGEN_EXPORT vec::Item* ffigen_gbvei2_std_vector_tfmct4_get(std::vector<std::unique_ptr<const vec::Item>>* self, std::size_t index) {
  return const_cast<vec::Item*>(std::move((*self)[index]).release());
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_tfmct4_delete(std::vector<std::unique_ptr<const vec::Item>>* self) {
  delete self;
}

FFIGEN_EXPORT std::vector<std::unique_ptr<vec::Item>>* ffigen_gbvei2_std_vector_5n0w1b_new(std::size_t capacity) {
  auto* self = new std::vector<std::unique_ptr<vec::Item>>();
  self->reserve(capacity);
  return self;
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_5n0w1b_push(std::vector<std::unique_ptr<vec::Item>>* self, vec::Item* value) {
  self->push_back(std::unique_ptr<vec::Item>(value));
}

FFIGEN_EXPORT bool ffigen_gbvei2_std_vector_5n0w1b_release(std::vector<std::unique_ptr<vec::Item>>* self, std::size_t index, vec::Item* pointer) {
  if (index >= self->size() || (*self)[index].get() != pointer) return false;
  (*self)[index].release();
  return true;
}

FFIGEN_EXPORT std::size_t ffigen_gbvei2_std_vector_5n0w1b_size(const std::vector<std::unique_ptr<vec::Item>>* self) {
  return self->size();
}

FFIGEN_EXPORT vec::Item* ffigen_gbvei2_std_vector_5n0w1b_get(std::vector<std::unique_ptr<vec::Item>>* self, std::size_t index) {
  return std::move((*self)[index]).release();
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_5n0w1b_delete(std::vector<std::unique_ptr<vec::Item>>* self) {
  delete self;
}

FFIGEN_EXPORT std::vector<std::vector<int>>* ffigen_gbvei2_std_vector_1drg142_new(std::size_t capacity) {
  auto* self = new std::vector<std::vector<int>>();
  self->reserve(capacity);
  return self;
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_1drg142_push(std::vector<std::vector<int>>* self, std::vector<int>* value) {
  self->push_back(std::move(*value));
}

FFIGEN_EXPORT std::size_t ffigen_gbvei2_std_vector_1drg142_size(const std::vector<std::vector<int>>* self) {
  return self->size();
}

FFIGEN_EXPORT std::vector<int>* ffigen_gbvei2_std_vector_1drg142_get(std::vector<std::vector<int>>* self, std::size_t index) {
  return new std::vector<int>(std::move((*self)[index]));
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_1drg142_delete(std::vector<std::vector<int>>* self) {
  delete self;
}

FFIGEN_EXPORT std::size_t ffigen_gbvei2_std_vector_198wnc8_size(const std::vector<std::vector<vec::Item*>>* self) {
  return self->size();
}

FFIGEN_EXPORT std::vector<vec::Item*>* ffigen_gbvei2_std_vector_198wnc8_get(std::vector<std::vector<vec::Item*>>* self, std::size_t index) {
  return new std::vector<vec::Item*>(std::move((*self)[index]));
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_198wnc8_delete(std::vector<std::vector<vec::Item*>>* self) {
  delete self;
}

FFIGEN_EXPORT std::vector<vec::Color>* ffigen_gbvei2_std_vector_kav0rc_new(std::size_t capacity) {
  auto* self = new std::vector<vec::Color>();
  self->reserve(capacity);
  return self;
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_kav0rc_push(std::vector<vec::Color>* self, vec::Color value) {
  self->push_back(value);
}

FFIGEN_EXPORT std::size_t ffigen_gbvei2_std_vector_kav0rc_size(const std::vector<vec::Color>* self) {
  return self->size();
}

FFIGEN_EXPORT vec::Color ffigen_gbvei2_std_vector_kav0rc_get(std::vector<vec::Color>* self, std::size_t index) {
  return std::move((*self)[index]);
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_kav0rc_delete(std::vector<vec::Color>* self) {
  delete self;
}

FFIGEN_EXPORT std::size_t ffigen_gbvei2_std_vector_1ebbtrw_size(const std::vector<vec::Id>* self) {
  return self->size();
}

FFIGEN_EXPORT uint32_t ffigen_gbvei2_std_vector_1ebbtrw_get(std::vector<vec::Id>* self, std::size_t index) {
  return std::move((*self)[index]);
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_1ebbtrw_delete(std::vector<vec::Id>* self) {
  delete self;
}

FFIGEN_EXPORT std::size_t ffigen_gbvei2_std_vector_e4df6o_size(const std::vector<vec::Item*>* self) {
  return self->size();
}

FFIGEN_EXPORT vec::Item* ffigen_gbvei2_std_vector_e4df6o_get(std::vector<vec::Item*>* self, std::size_t index) {
  return std::move((*self)[index]);
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_e4df6o_delete(std::vector<vec::Item*>* self) {
  delete self;
}

FFIGEN_EXPORT std::size_t ffigen_gbvei2_std_vector_1nep6zm_size(const std::vector<vec::MoveOnly>* self) {
  return self->size();
}

FFIGEN_EXPORT vec::MoveOnly* ffigen_gbvei2_std_vector_1nep6zm_get(std::vector<vec::MoveOnly>* self, std::size_t index) {
  return new vec::MoveOnly(std::move((*self)[index]));
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_1nep6zm_delete(std::vector<vec::MoveOnly>* self) {
  delete self;
}

FFIGEN_EXPORT std::vector<vec::Pair>* ffigen_gbvei2_std_vector_18jrvwb_new(std::size_t capacity) {
  auto* self = new std::vector<vec::Pair>();
  self->reserve(capacity);
  return self;
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_18jrvwb_push(std::vector<vec::Pair>* self, vec::Pair value) {
  self->push_back(value);
}

FFIGEN_EXPORT std::size_t ffigen_gbvei2_std_vector_18jrvwb_size(const std::vector<vec::Pair>* self) {
  return self->size();
}

FFIGEN_EXPORT vec::Pair ffigen_gbvei2_std_vector_18jrvwb_get(std::vector<vec::Pair>* self, std::size_t index) {
  return std::move((*self)[index]);
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_18jrvwb_delete(std::vector<vec::Pair>* self) {
  delete self;
}

FFIGEN_EXPORT std::vector<vec::Point>* ffigen_gbvei2_std_vector_g8iepf_new(std::size_t capacity) {
  auto* self = new std::vector<vec::Point>();
  self->reserve(capacity);
  return self;
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_g8iepf_push(std::vector<vec::Point>* self, vec::Point* value) {
  self->push_back(*value);
}

FFIGEN_EXPORT std::size_t ffigen_gbvei2_std_vector_g8iepf_size(const std::vector<vec::Point>* self) {
  return self->size();
}

FFIGEN_EXPORT vec::Point* ffigen_gbvei2_std_vector_g8iepf_get(std::vector<vec::Point>* self, std::size_t index) {
  return new vec::Point(std::move((*self)[index]));
}

FFIGEN_EXPORT void ffigen_gbvei2_std_vector_g8iepf_delete(std::vector<vec::Point>* self) {
  delete self;
}

FFIGEN_EXPORT vec::Item* vec_Item_new(std::string* name) {
  return new vec::Item(std::move(*name));
}

FFIGEN_EXPORT std::string* vec_Item_name(const vec::Item* self) {
  return new std::string(self->name());
}

FFIGEN_EXPORT int vec_Item_liveCount() {
  return vec::Item::liveCount();
}

FFIGEN_EXPORT void vec_Item_delete(vec::Item* self) {
  delete self;
}

FFIGEN_EXPORT vec::MoveOnly* vec_MoveOnly_new(int value) {
  return new vec::MoveOnly(value);
}

FFIGEN_EXPORT int vec_MoveOnly_value(const vec::MoveOnly* self) {
  return self->value();
}

FFIGEN_EXPORT void vec_MoveOnly_delete(vec::MoveOnly* self) {
  delete self;
}

FFIGEN_EXPORT vec::Point* vec_Point_new(int x, int y) {
  return new vec::Point(x, y);
}

FFIGEN_EXPORT int vec_Point_x(const vec::Point* self) {
  return self->x();
}

FFIGEN_EXPORT int vec_Point_y(const vec::Point* self) {
  return self->y();
}

FFIGEN_EXPORT void vec_Point_delete(vec::Point* self) {
  delete self;
}

FFIGEN_EXPORT vec::Registry* vec_Registry_new(std::vector<std::string>* itemNames) {
  return new vec::Registry(std::move(*itemNames));
}

FFIGEN_EXPORT std::vector<int>* vec_Registry_ints(const vec::Registry* self) {
  return new std::vector<int>(self->ints());
}

FFIGEN_EXPORT void vec_Registry_setInts(vec::Registry* self, std::vector<int>* values) {
  self->setInts(std::move(*values));
}

FFIGEN_EXPORT int vec_Registry_sum(const vec::Registry* self, std::vector<int>* values) {
  return self->sum(std::move(*values));
}

FFIGEN_EXPORT void vec_Registry_appendInts(vec::Registry* self, std::vector<int>* values) {
  self->appendInts(std::move(*values));
}

FFIGEN_EXPORT std::vector<int>* vec_Registry_intsRef(const vec::Registry* self) {
  return new std::vector<int>(self->intsRef());
}

FFIGEN_EXPORT std::vector<int>* vec_Registry_alias(const vec::Registry* self) {
  return new std::vector<int>(self->alias());
}

FFIGEN_EXPORT std::vector<std::size_t>* vec_Registry_sizes(const vec::Registry* self) {
  return new std::vector<std::size_t>(self->sizes());
}

FFIGEN_EXPORT std::vector<vec::Id>* vec_Registry_ids(const vec::Registry* self, uint32_t first, int count) {
  return new std::vector<vec::Id>(self->ids(first, count));
}

FFIGEN_EXPORT std::vector<int>* vec_Registry_handles(const vec::Registry* self) {
  return new std::vector<int>(self->handles());
}

FFIGEN_EXPORT std::vector<int>* vec_Registry_secrets(const vec::Registry* self) {
  return new std::vector<int>(self->secrets());
}

FFIGEN_EXPORT std::vector<vec::Item*>* vec_Registry_itemPtrs(vec::Registry* self) {
  return new std::vector<vec::Item*>(self->itemPtrs());
}

FFIGEN_EXPORT std::vector<std::unique_ptr<vec::Item>>* vec_Registry_makeUniqueItems(std::vector<std::string>* names) {
  return new std::vector<std::unique_ptr<vec::Item>>(vec::Registry::makeUniqueItems(std::move(*names)));
}

FFIGEN_EXPORT std::vector<double>* vec_Registry_halves(const vec::Registry* self, std::vector<int>* values) {
  return new std::vector<double>(self->halves(std::move(*values)));
}

FFIGEN_EXPORT std::vector<bool>* vec_Registry_parities(const vec::Registry* self, std::vector<int>* values) {
  return new std::vector<bool>(self->parities(std::move(*values)));
}

FFIGEN_EXPORT std::vector<vec::Color>* vec_Registry_colors(const vec::Registry* self) {
  return new std::vector<vec::Color>(self->colors());
}

FFIGEN_EXPORT int vec_Registry_countRed(const vec::Registry* self, std::vector<vec::Color>* colors) {
  return self->countRed(std::move(*colors));
}

FFIGEN_EXPORT std::vector<std::string>* vec_Registry_names(const vec::Registry* self) {
  return new std::vector<std::string>(self->names());
}

FFIGEN_EXPORT std::string* vec_Registry_join(std::vector<std::string>* parts, std::string* separator) {
  return new std::string(vec::Registry::join(std::move(*parts), std::move(*separator)));
}

FFIGEN_EXPORT std::vector<vec::Item*>* vec_Registry_items(vec::Registry* self) {
  return new std::vector<vec::Item*>(self->items());
}

FFIGEN_EXPORT std::vector<const vec::Item*>* vec_Registry_constItems(const vec::Registry* self) {
  return new std::vector<const vec::Item*>(self->constItems());
}

FFIGEN_EXPORT int vec_Registry_indexOf(const vec::Registry* self, std::vector<const vec::Item*>* items, std::string* name) {
  return self->indexOf(std::move(*items), std::move(*name));
}

FFIGEN_EXPORT std::vector<vec::Point>* vec_Registry_points(const vec::Registry* self, int count) {
  return new std::vector<vec::Point>(self->points(count));
}

FFIGEN_EXPORT int vec_Registry_sumX(const vec::Registry* self, std::vector<vec::Point>* points) {
  return self->sumX(std::move(*points));
}

FFIGEN_EXPORT std::vector<vec::Pair>* vec_Registry_pairs(const vec::Registry* self, int count) {
  return new std::vector<vec::Pair>(self->pairs(count));
}

FFIGEN_EXPORT int vec_Registry_sumPairs(const vec::Registry* self, std::vector<vec::Pair>* pairs) {
  return self->sumPairs(std::move(*pairs));
}

FFIGEN_EXPORT std::vector<std::unique_ptr<vec::Item>>* vec_Registry_makeItems(std::vector<std::string>* names) {
  return new std::vector<std::unique_ptr<vec::Item>>(vec::Registry::makeItems(std::move(*names)));
}

FFIGEN_EXPORT void vec_Registry_adopt(vec::Registry* self, std::vector<std::unique_ptr<vec::Item>>* items) {
  self->adopt(std::move(*items));
}

FFIGEN_EXPORT int vec_Registry_totalLength(std::vector<std::unique_ptr<vec::Item>>* items) {
  return vec::Registry::totalLength(std::move(*items));
}

FFIGEN_EXPORT void vec_Registry_adoptFirst(vec::Registry* self, std::vector<std::unique_ptr<vec::Item>>* items) {
  self->adoptFirst(std::move(*items));
}

FFIGEN_EXPORT std::vector<std::unique_ptr<const vec::Item>>* vec_Registry_makeConstItems(std::vector<std::string>* names) {
  return new std::vector<std::unique_ptr<const vec::Item>>(vec::Registry::makeConstItems(std::move(*names)));
}

FFIGEN_EXPORT std::vector<vec::MoveOnly>* vec_Registry_moveOnlies(const vec::Registry* self, int count) {
  return new std::vector<vec::MoveOnly>(self->moveOnlies(count));
}

FFIGEN_EXPORT std::vector<std::vector<int>>* vec_Registry_grid(const vec::Registry* self, int rows, int columns) {
  return new std::vector<std::vector<int>>(self->grid(rows, columns));
}

FFIGEN_EXPORT int vec_Registry_gridSum(std::vector<std::vector<int>>* grid) {
  return vec::Registry::gridSum(std::move(*grid));
}

FFIGEN_EXPORT std::vector<std::vector<vec::Item*>>* vec_Registry_itemsByLength(vec::Registry* self) {
  return new std::vector<std::vector<vec::Item*>>(self->itemsByLength());
}

FFIGEN_EXPORT std::vector<int>* vec_Registry_range(int count) {
  return new std::vector<int>(vec::Registry::range(count));
}

FFIGEN_EXPORT void vec_Registry_delete(vec::Registry* self) {
  delete self;
}

}
