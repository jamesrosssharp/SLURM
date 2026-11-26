// Inline functions, templates, a function-local static in an inline function
// and classes with vtables, used from two translation units: each gets a weak
// definition in both objects, and the linker must keep exactly one.
#include <stdint.h>
struct Shape {
  virtual ~Shape() {}
  virtual int16_t area() const = 0;
};
struct Sq : Shape {
  int16_t s;
  Sq(int16_t s) : s(s) {}
  int16_t area() const override { return s * s; }
};
template <class T> T twice(T x) { return x + x; }
inline int16_t counter() {
  static int16_t n;
  return ++n;
}
