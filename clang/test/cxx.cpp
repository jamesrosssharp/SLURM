#include "common.h"

struct Shape {
  virtual ~Shape() {}
  virtual int32_t area() const = 0;
  virtual const char *name() const { return "shape"; }
};

struct Rect : Shape {
  int16_t w, h;
  Rect(int16_t w, int16_t h) : w(w), h(h) {}
  int32_t area() const override { return (int32_t)w * h; }
  const char *name() const override { return "rect"; }
};

struct Square : Rect {
  explicit Square(int16_t s) : Rect(s, s) {}
  const char *name() const override { return "square"; }
};

struct Circle : Shape {
  int16_t r;
  explicit Circle(int16_t r) : r(r) {}
  int32_t area() const override { return 3 * (int32_t)r * r; }
};

template <typename T, int N> struct Stack {
  T data[N];
  int n = 0;
  void push(T v) { data[n++] = v; }
  T pop() { return data[--n]; }
  bool empty() const { return n == 0; }
};

template <typename T> T maximum(T a, T b) { return a > b ? a : b; }

struct Vec {
  int16_t x, y;
  Vec operator+(const Vec &o) const { return {int16_t(x + o.x), int16_t(y + o.y)}; }
  Vec &operator*=(int16_t k) {
    x *= k;
    y *= k;
    return *this;
  }
};

static int16_t ctor_count;
struct Global {
  int16_t v;
  Global(int16_t v) : v(v) { ++ctor_count; }
};
Global g1(11), g2(22);

static int16_t get_static() {
  static Global local(33);
  return local.v;
}

namespace ns {
int16_t f(int16_t x) { return x + 1; }
int16_t f(int32_t x) { return int16_t(x >> 16); }
} // namespace ns

int main() {
  PD(ctor_count); PD(g1.v); PD(g2.v); PD(get_static()); PD(get_static());
  PD(ctor_count);
  NL();
  Shape *shapes[] = {new Rect(3, 4), new Square(5), new Circle(2)};
  for (Shape *s : shapes) {
    out_str(s->name()); putchar(' '); PD(s->area());
  }
  for (Shape *s : shapes)
    delete s;
  NL();
  Stack<int32_t, 8> st;
  for (int32_t i = 1; i <= 5; ++i)
    st.push(i * 70000);
  while (!st.empty())
    PD(st.pop());
  NL();
  PD(maximum<int16_t>(3, -7)); PD(maximum(100000L, 99999L));
  PD(maximum<uint16_t>(3, 65535));
  NL();
  Vec v = Vec{1, 2} + Vec{10, 20};
  v *= 3;
  PD(v.x); PD(v.y);
  NL();
  int16_t base = 5;
  auto add = [base](int16_t x) { return int16_t(x + base); };
  auto mul = [&base](int16_t x) { return int16_t(x * base); };
  base = 7;
  PD(add(1)); PD(mul(2));
  NL();
  PD(ns::f(int16_t(41))); PD(ns::f(int32_t(0x70000)));
  NL();
  int16_t *arr = new int16_t[10];
  for (int i = 0; i < 10; ++i)
    arr[i] = int16_t(i * 3);
  int32_t s = 0;
  for (int i = 0; i < 10; ++i)
    s += arr[i];
  delete[] arr;
  PD(s);
  NL();
  return 0;
}
