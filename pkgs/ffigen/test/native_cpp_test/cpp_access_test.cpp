// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "cpp_access_test.h"

namespace access {

namespace {
int32_t gateCount = 0;
int32_t shapeCount = 0;
int32_t countedCount = 0;
int32_t widgetCount = 0;

void releaseCounted(void* counted) {
  static_cast<Counted*>(counted)->release();
}
}  // namespace

Gate::Gate() : Gate(0, false) {}

Gate::Gate(int32_t code) : Gate(code, false) {}

Gate::Gate(int32_t code, bool open) : code_(code), open_(open) { ++gateCount; }

Gate::~Gate() { --gateCount; }

int32_t Gate::code() const { return code_; }

bool Gate::isOpen() const { return open_; }

void Gate::open() { open_ = true; }

int32_t Gate::liveCount() { return gateCount; }

void Gate::lock() { open_ = false; }

int32_t Gate::protectedCount() { return gateCount; }

void Gate::unlock() { open_ = true; }

int32_t Gate::privateCount() { return gateCount; }

Shape::Shape() { ++shapeCount; }

Shape::~Shape() { --shapeCount; }

Shape* Shape::makeSquare(double side) { return new Square(side); }

std::unique_ptr<Shape> Shape::makeOwnedSquare(double side) {
  return std::unique_ptr<Shape>(new Square(side));
}

int32_t Shape::liveCount() { return shapeCount; }

Polygon::Polygon(int32_t sides) : sides_(sides) {}

int32_t Polygon::sides() const { return sides_; }

Square::Square(double side) : Polygon(4), side_(side) {}

double Square::area() const { return side_ * side_; }

Recorder::Recorder() : last_(0) {}

Recorder::~Recorder() {}

int32_t Recorder::notify(int32_t event) {
  last_ = event;
  return event * 2;
}

int32_t Recorder::last() const { return last_; }

Listener* Recorder::asListener() { return this; }

Counted::Counted() : count_(1) { ++countedCount; }

Counted::~Counted() { --countedCount; }

void Counted::retain() { ++count_; }

void Counted::release() {
  if (--count_ == 0) delete this;
}

int32_t Counted::count() const { return count_; }

int32_t Counted::liveCount() { return countedCount; }

void* Counted::releaseFunction() {
  return reinterpret_cast<void*>(&releaseCounted);
}

int32_t Counted::countOf(Counted counted) { return counted.count_; }

Counted Counted::copy() const { return *this; }

int32_t Drawable::draw() const { return 1; }

Widget::Widget() { ++widgetCount; }

Widget::Widget(const Widget& other) : Drawable(other) { ++widgetCount; }

Widget::~Widget() { --widgetCount; }

int32_t Widget::draw() const { return 2; }

int32_t Widget::liveCount() { return widgetCount; }

void Widget::destroy(Widget* widget) { delete widget; }

int32_t Widget::drawCopy(Widget widget) { return widget.draw(); }

Widget Widget::copy() const { return *this; }

std::unique_ptr<Widget> Widget::makeOwned() { return nullptr; }

Registry::Registry() {}

Registry::~Registry() {}

Registry* Registry::instance() {
  static Registry* registry = new Registry();
  return registry;
}

int32_t Registry::size() const { return 3; }

int32_t SubRegistry::depth() const { return 1; }

}  // namespace access
