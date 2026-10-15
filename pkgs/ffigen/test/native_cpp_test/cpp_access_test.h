// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test header for member access, deleted members, abstract classes and
// destructors that the bindings can't call.

#include <cstdint>
#include <memory>

namespace access {

// Only the public, non-deleted members get bindings.
class Gate {
 public:
  Gate();
  explicit Gate(int32_t code);
  explicit Gate(double code) = delete;
  ~Gate();

  int32_t code() const;
  bool isOpen() const;
  void open();
  void close() = delete;
  static int32_t liveCount();

 protected:
  Gate(int32_t code, bool open);
  void lock();
  static int32_t protectedCount();

 private:
  void unlock();
  static int32_t privateCount();

  int32_t code_;
  bool open_;
};

// An abstract class with a public virtual destructor. It gets no
// constructors, but the bindings can delete it.
class Shape {
 public:
  virtual ~Shape();
  virtual double area() const = 0;
  virtual int32_t sides() const = 0;

  static Shape* makeSquare(double side);
  static std::unique_ptr<Shape> makeOwnedSquare(double side);
  static int32_t liveCount();

 protected:
  Shape();
};

// Abstract too, since it doesn't override area(), though its constructor is
// public.
class Polygon : public Shape {
 public:
  explicit Polygon(int32_t sides);
  int32_t sides() const override;

 private:
  int32_t sides_;
};

// Concrete, with an implicit destructor that's virtual because Shape's is.
class Square : public Polygon {
 public:
  explicit Square(double side);
  double area() const override;

 private:
  double side_;
};

// An interface that can't be deleted through, since its destructor is
// protected.
class Listener {
 public:
  virtual int32_t notify(int32_t event) = 0;

 protected:
  ~Listener() = default;
};

// A deletable implementation of Listener.
class Recorder : public Listener {
 public:
  Recorder();
  virtual ~Recorder();
  int32_t notify(int32_t event) override;
  int32_t last() const;
  Listener* asListener();

 private:
  int32_t last_;
};

// A concrete class with a protected destructor, which deletes itself.
class Counted {
 public:
  Counted();
  void retain();
  void release();
  int32_t count() const;
  static int32_t liveCount();

  // The address of a function that releases a Counted, for a custom
  // finalizer.
  static void* releaseFunction();

  // A copy would have to be destroyed by the glue, or deleted by Dart.
  static int32_t countOf(Counted counted);
  Counted copy() const;

 protected:
  virtual ~Counted();

 private:
  int32_t count_;
};

// A polymorphic class whose implicit destructor isn't virtual.
class Drawable {
 public:
  virtual int32_t draw() const;
};

// A polymorphic class whose destructor is public, but not virtual, so the
// bindings can't delete it.
class Widget : public Drawable {
 public:
  Widget();
  Widget(const Widget& other);
  ~Widget();
  int32_t draw() const override;
  static int32_t liveCount();
  static void destroy(Widget* widget);

  // A copy can be destroyed by the glue, but not deleted by Dart.
  static int32_t drawCopy(Widget widget);
  Widget copy() const;
  static std::unique_ptr<Widget> makeOwned();
};

// A class with a private destructor.
class Registry {
 public:
  static Registry* instance();
  int32_t size() const;

 private:
  Registry();
  ~Registry();
};

// The implicit destructor is deleted, because Registry's is private.
class SubRegistry : public Registry {
 public:
  int32_t depth() const;
};

}  // namespace access
