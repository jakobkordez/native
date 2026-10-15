// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "cpp_namespace_class_test.h"

namespace zoo {

Creature::Creature(int age) : age_(age), position_{0, 0} {}

Creature::~Creature() {}

int Creature::getAge() const { return age_; }

void Creature::setAge(int age) { age_ = age; }

Position Creature::getPosition() const { return position_; }

void Creature::moveTo(Position position) { position_ = position; }

int Creature::sum(int a, int b) { return a + b; }

Creature Creature::olderBy(int years) const { return Creature(age_ + years); }

Creature* Creature::create(int age) { return new Creature(age); }

Dog::Dog(int age) : Creature(age) {}

int Dog::bark() const { return getAge() * 10; }

Keeper::Badge::Badge(int number) : number_(number) {}

int Keeper::Badge::getNumber() const { return number_; }

Keeper::Secret::Secret() {}

int Keeper::Secret::reveal() const { return 7; }

Keeper::Keeper(int badgeNumber)
    : badge_(badgeNumber), secret_(new Secret()) {}

Keeper::~Keeper() { delete secret_; }

Keeper::Badge* Keeper::getBadge() { return &badge_; }

int Keeper::feed(Creature* animal) const {
  return animal->getAge() + secret_->reveal();
}

namespace aquarium {

Creature::Creature(double depth) : depth_(depth) {}

Creature::~Creature() {}

double Creature::getDepth() const { return depth_; }

}  // namespace aquarium
}  // namespace zoo

namespace farm {

Creature::Creature(int age, int legs) : zoo::Creature(age), legs_(legs) {}

int Creature::getLegs() const { return legs_; }

}  // namespace farm

Creature::Creature() {}

Creature::~Creature() {}

int Creature::compare(const zoo::Creature* a,
                      const zoo::aquarium::Creature* b) const {
  return a->getAge() - static_cast<int>(b->getDepth());
}
