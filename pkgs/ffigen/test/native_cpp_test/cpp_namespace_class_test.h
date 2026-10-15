// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// C++ classes declared inside a namespace or a record are named by their
// enclosing scopes, flattened with `$` to form a Dart identifier.

namespace zoo {
// POD struct in a namespace, used by value by the classes below.
struct Position {
  int x;
  int y;
};

// Class in a single namespace.
class Creature {
 public:
  Creature(int age);
  virtual ~Creature();
  int getAge() const;
  void setAge(int age);
  Position getPosition() const;
  void moveTo(Position position);
  static int sum(int a, int b);
  Creature olderBy(int years) const;
  static Creature* create(int age);

 private:
  int age_;
  Position position_;
};

// Class deriving from a class in the same namespace.
class Dog : public Creature {
 public:
  Dog(int age);
  int bark() const;
};

class Keeper {
 public:
  // Class nested inside a class that is itself in a namespace.
  class Badge {
   public:
    Badge(int number);
    int getNumber() const;

   private:
    int number_;
  };

  Keeper(int badgeNumber);
  ~Keeper();
  Badge* getBadge();
  int feed(Creature* animal) const;

 private:
  // A private nested class can't be named by the generated glue, so it must
  // be skipped.
  class Secret {
   public:
    Secret();
    int reveal() const;
  };

  Badge badge_;
  Secret* secret_;
};

namespace aquarium {
// Class in a nested namespace. Shares the leaf name `Creature` with
// `zoo::Creature` and `farm::Creature`.
class Creature {
 public:
  Creature(double depth);
  virtual ~Creature();
  double getDepth() const;

 private:
  double depth_;
};
}  // namespace aquarium
}  // namespace zoo

namespace farm {
// Another `Creature`, in a different namespace, to exercise leaf-name
// collisions. It derives from a class in another namespace.
class Creature : public zoo::Creature {
 public:
  Creature(int age, int legs);
  int getLegs() const;

 private:
  int legs_;
};
}  // namespace farm

// Class at global scope, sharing the leaf name of the namespaced classes and
// mentioning them in its methods.
class Creature {
 public:
  Creature();
  virtual ~Creature();
  int compare(const zoo::Creature* a, const zoo::aquarium::Creature* b) const;
};
