#include <memory>
#include "cpp_namespace_class_test.h"

#if defined(_WIN32)
#define FFIGEN_EXPORT __declspec(dllexport)
#else
#define FFIGEN_EXPORT
#endif

extern "C" {

FFIGEN_EXPORT Creature* Creature_new() {
  return new Creature();
}

FFIGEN_EXPORT int Creature_compare(const Creature* self, zoo::Creature* a, zoo::aquarium::Creature* b) {
  return self->compare(a, b);
}

FFIGEN_EXPORT void Creature_delete(Creature* self) {
  delete self;
}

FFIGEN_EXPORT farm::Creature* farm_Creature_new(int age, int legs) {
  return new farm::Creature(age, legs);
}

FFIGEN_EXPORT int farm_Creature_getLegs(const farm::Creature* self) {
  return self->getLegs();
}

FFIGEN_EXPORT int farm_Creature_getAge(const farm::Creature* self) {
  return static_cast<const zoo::Creature*>(self)->getAge();
}

FFIGEN_EXPORT void farm_Creature_setAge(farm::Creature* self, int age) {
  static_cast<zoo::Creature*>(self)->setAge(age);
}

FFIGEN_EXPORT zoo::Position farm_Creature_getPosition(const farm::Creature* self) {
  return static_cast<const zoo::Creature*>(self)->getPosition();
}

FFIGEN_EXPORT void farm_Creature_moveTo(farm::Creature* self, zoo::Position position) {
  static_cast<zoo::Creature*>(self)->moveTo(position);
}

FFIGEN_EXPORT int farm_Creature_sum(int a, int b) {
  return zoo::Creature::sum(a, b);
}

FFIGEN_EXPORT zoo::Creature* farm_Creature_olderBy(const farm::Creature* self, int years) {
  return new zoo::Creature(static_cast<const zoo::Creature*>(self)->olderBy(years));
}

FFIGEN_EXPORT zoo::Creature* farm_Creature_create(int age) {
  return zoo::Creature::create(age);
}

FFIGEN_EXPORT void farm_Creature_delete(farm::Creature* self) {
  delete self;
}

FFIGEN_EXPORT zoo::Creature* zoo_Creature_new(int age) {
  return new zoo::Creature(age);
}

FFIGEN_EXPORT int zoo_Creature_getAge(const zoo::Creature* self) {
  return self->getAge();
}

FFIGEN_EXPORT void zoo_Creature_setAge(zoo::Creature* self, int age) {
  self->setAge(age);
}

FFIGEN_EXPORT zoo::Position zoo_Creature_getPosition(const zoo::Creature* self) {
  return self->getPosition();
}

FFIGEN_EXPORT void zoo_Creature_moveTo(zoo::Creature* self, zoo::Position position) {
  self->moveTo(position);
}

FFIGEN_EXPORT int zoo_Creature_sum(int a, int b) {
  return zoo::Creature::sum(a, b);
}

FFIGEN_EXPORT zoo::Creature* zoo_Creature_olderBy(const zoo::Creature* self, int years) {
  return new zoo::Creature(self->olderBy(years));
}

FFIGEN_EXPORT zoo::Creature* zoo_Creature_create(int age) {
  return zoo::Creature::create(age);
}

FFIGEN_EXPORT void zoo_Creature_delete(zoo::Creature* self) {
  delete self;
}

FFIGEN_EXPORT zoo::Dog* zoo_Dog_new(int age) {
  return new zoo::Dog(age);
}

FFIGEN_EXPORT int zoo_Dog_bark(const zoo::Dog* self) {
  return self->bark();
}

FFIGEN_EXPORT int zoo_Dog_getAge(const zoo::Dog* self) {
  return static_cast<const zoo::Creature*>(self)->getAge();
}

FFIGEN_EXPORT void zoo_Dog_setAge(zoo::Dog* self, int age) {
  static_cast<zoo::Creature*>(self)->setAge(age);
}

FFIGEN_EXPORT zoo::Position zoo_Dog_getPosition(const zoo::Dog* self) {
  return static_cast<const zoo::Creature*>(self)->getPosition();
}

FFIGEN_EXPORT void zoo_Dog_moveTo(zoo::Dog* self, zoo::Position position) {
  static_cast<zoo::Creature*>(self)->moveTo(position);
}

FFIGEN_EXPORT int zoo_Dog_sum(int a, int b) {
  return zoo::Creature::sum(a, b);
}

FFIGEN_EXPORT zoo::Creature* zoo_Dog_olderBy(const zoo::Dog* self, int years) {
  return new zoo::Creature(static_cast<const zoo::Creature*>(self)->olderBy(years));
}

FFIGEN_EXPORT zoo::Creature* zoo_Dog_create(int age) {
  return zoo::Creature::create(age);
}

FFIGEN_EXPORT void zoo_Dog_delete(zoo::Dog* self) {
  delete self;
}

FFIGEN_EXPORT zoo::Keeper* zoo_Keeper_new(int badgeNumber) {
  return new zoo::Keeper(badgeNumber);
}

FFIGEN_EXPORT zoo::Keeper::Badge* zoo_Keeper_getBadge(zoo::Keeper* self) {
  return self->getBadge();
}

FFIGEN_EXPORT int zoo_Keeper_feed(const zoo::Keeper* self, zoo::Creature* animal) {
  return self->feed(animal);
}

FFIGEN_EXPORT void zoo_Keeper_delete(zoo::Keeper* self) {
  delete self;
}

FFIGEN_EXPORT zoo::Keeper::Badge* zoo_Keeper_Badge_new(int number) {
  return new zoo::Keeper::Badge(number);
}

FFIGEN_EXPORT int zoo_Keeper_Badge_getNumber(const zoo::Keeper::Badge* self) {
  return self->getNumber();
}

FFIGEN_EXPORT void zoo_Keeper_Badge_delete(zoo::Keeper::Badge* self) {
  delete self;
}

FFIGEN_EXPORT zoo::aquarium::Creature* zoo_aquarium_Creature_new(double depth) {
  return new zoo::aquarium::Creature(depth);
}

FFIGEN_EXPORT double zoo_aquarium_Creature_getDepth(const zoo::aquarium::Creature* self) {
  return self->getDepth();
}

FFIGEN_EXPORT void zoo_aquarium_Creature_delete(zoo::aquarium::Creature* self) {
  delete self;
}

}
