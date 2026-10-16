#include <memory>
#include "cpp_access_test.h"

#if defined(_WIN32)
#define FFIGEN_EXPORT __declspec(dllexport)
#else
#define FFIGEN_EXPORT
#endif

extern "C" {

FFIGEN_EXPORT access::Counted* access_Counted_new() {
  return new access::Counted();
}

FFIGEN_EXPORT void access_Counted_retain(access::Counted* self) {
  self->retain();
}

FFIGEN_EXPORT void access_Counted_release(access::Counted* self) {
  self->release();
}

FFIGEN_EXPORT int32_t access_Counted_count(const access::Counted* self) {
  return self->count();
}

FFIGEN_EXPORT int32_t access_Counted_liveCount() {
  return access::Counted::liveCount();
}

FFIGEN_EXPORT void * access_Counted_releaseFunction() {
  return access::Counted::releaseFunction();
}

FFIGEN_EXPORT int32_t access_Drawable_draw(const access::Drawable* self) {
  return self->draw();
}

FFIGEN_EXPORT access::Gate* access_Gate_new() {
  return new access::Gate();
}

FFIGEN_EXPORT access::Gate* access_Gate_new_1(int32_t code) {
  return new access::Gate(code);
}

FFIGEN_EXPORT int32_t access_Gate_code(const access::Gate* self) {
  return self->code();
}

FFIGEN_EXPORT bool access_Gate_isOpen(const access::Gate* self) {
  return self->isOpen();
}

FFIGEN_EXPORT void access_Gate_open(access::Gate* self) {
  self->open();
}

FFIGEN_EXPORT int32_t access_Gate_liveCount() {
  return access::Gate::liveCount();
}

FFIGEN_EXPORT void access_Gate_delete(access::Gate* self) {
  delete self;
}

FFIGEN_EXPORT int32_t access_Listener_notify(access::Listener* self, int32_t event) {
  return self->notify(event);
}

FFIGEN_EXPORT int32_t access_Polygon_sides(const access::Polygon* self) {
  return self->sides();
}

FFIGEN_EXPORT double access_Polygon_area(const access::Polygon* self) {
  return static_cast<const access::Shape*>(self)->area();
}

FFIGEN_EXPORT access::Shape* access_Polygon_makeSquare(double side) {
  return access::Shape::makeSquare(side);
}

FFIGEN_EXPORT access::Shape* access_Polygon_makeOwnedSquare(double side) {
  return access::Shape::makeOwnedSquare(side).release();
}

FFIGEN_EXPORT int32_t access_Polygon_liveCount() {
  return access::Shape::liveCount();
}

FFIGEN_EXPORT void access_Polygon_delete(access::Polygon* self) {
  delete self;
}

FFIGEN_EXPORT access::Recorder* access_Recorder_new() {
  return new access::Recorder();
}

FFIGEN_EXPORT int32_t access_Recorder_notify(access::Recorder* self, int32_t event) {
  return self->notify(event);
}

FFIGEN_EXPORT int32_t access_Recorder_last(const access::Recorder* self) {
  return self->last();
}

FFIGEN_EXPORT access::Listener* access_Recorder_asListener(access::Recorder* self) {
  return self->asListener();
}

FFIGEN_EXPORT void access_Recorder_delete(access::Recorder* self) {
  delete self;
}

FFIGEN_EXPORT access::Registry* access_Registry_instance() {
  return access::Registry::instance();
}

FFIGEN_EXPORT int32_t access_Registry_size(const access::Registry* self) {
  return self->size();
}

FFIGEN_EXPORT double access_Shape_area(const access::Shape* self) {
  return self->area();
}

FFIGEN_EXPORT int32_t access_Shape_sides(const access::Shape* self) {
  return self->sides();
}

FFIGEN_EXPORT access::Shape* access_Shape_makeSquare(double side) {
  return access::Shape::makeSquare(side);
}

FFIGEN_EXPORT access::Shape* access_Shape_makeOwnedSquare(double side) {
  return access::Shape::makeOwnedSquare(side).release();
}

FFIGEN_EXPORT int32_t access_Shape_liveCount() {
  return access::Shape::liveCount();
}

FFIGEN_EXPORT void access_Shape_delete(access::Shape* self) {
  delete self;
}

FFIGEN_EXPORT access::Square* access_Square_new(double side) {
  return new access::Square(side);
}

FFIGEN_EXPORT double access_Square_area(const access::Square* self) {
  return self->area();
}

FFIGEN_EXPORT int32_t access_Square_sides(const access::Square* self) {
  return static_cast<const access::Polygon*>(self)->sides();
}

FFIGEN_EXPORT access::Shape* access_Square_makeSquare(double side) {
  return access::Shape::makeSquare(side);
}

FFIGEN_EXPORT access::Shape* access_Square_makeOwnedSquare(double side) {
  return access::Shape::makeOwnedSquare(side).release();
}

FFIGEN_EXPORT int32_t access_Square_liveCount() {
  return access::Shape::liveCount();
}

FFIGEN_EXPORT void access_Square_delete(access::Square* self) {
  delete self;
}

FFIGEN_EXPORT int32_t access_SubRegistry_depth(const access::SubRegistry* self) {
  return self->depth();
}

FFIGEN_EXPORT access::Registry* access_SubRegistry_instance() {
  return access::Registry::instance();
}

FFIGEN_EXPORT int32_t access_SubRegistry_size(const access::SubRegistry* self) {
  return static_cast<const access::Registry*>(self)->size();
}

FFIGEN_EXPORT access::Widget* access_Widget_new() {
  return new access::Widget();
}

FFIGEN_EXPORT access::Widget* access_Widget_new_1(access::Widget* other) {
  return new access::Widget(*other);
}

FFIGEN_EXPORT int32_t access_Widget_draw(const access::Widget* self) {
  return self->draw();
}

FFIGEN_EXPORT int32_t access_Widget_liveCount() {
  return access::Widget::liveCount();
}

FFIGEN_EXPORT void access_Widget_destroy(access::Widget* widget) {
  access::Widget::destroy(widget);
}

FFIGEN_EXPORT int32_t access_Widget_drawCopy(access::Widget* widget) {
  return access::Widget::drawCopy(*widget);
}

}
