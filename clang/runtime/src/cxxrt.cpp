// cxxrt.cpp - minimal C++ runtime support for SLURM16 (no exceptions, no
// RTTI): operator new/delete, pure virtual calls and static initialization
// guards.
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

namespace std {
enum class align_val_t : size_t {};
struct nothrow_t {
  explicit nothrow_t() = default;
};
extern const nothrow_t nothrow;
const nothrow_t nothrow{};
} // namespace std

void *operator new(size_t n) {
  void *p = malloc(n ? n : 1);
  if (!p) {
    puts("operator new: out of memory");
    abort();
  }
  return p;
}
void *operator new[](size_t n) { return operator new(n); }
void *operator new(size_t n, const std::nothrow_t &) noexcept {
  return malloc(n ? n : 1);
}
void *operator new[](size_t n, const std::nothrow_t &) noexcept {
  return malloc(n ? n : 1);
}
void operator delete(void *p) noexcept { free(p); }
void operator delete[](void *p) noexcept { free(p); }
void operator delete(void *p, size_t) noexcept { free(p); }
void operator delete[](void *p, size_t) noexcept { free(p); }

extern "C" {

void __cxa_pure_virtual() {
  puts("pure virtual function called");
  abort();
}

void __cxa_deleted_virtual() {
  puts("deleted virtual function called");
  abort();
}

// Single threaded: a guard is just a "done" flag.
int __cxa_guard_acquire(long long *g) { return *(char *)g == 0; }
void __cxa_guard_release(long long *g) { *(char *)g = 1; }
void __cxa_guard_abort(long long *) {}

void *__dso_handle = 0;

int __cxa_atexit(void (*fn)(void *), void *arg, void *) {
  // Destructors of static objects are never run on SLURM16 when registered
  // this way (the default is -fno-use-cxa-atexit, which uses atexit()).
  (void)fn;
  (void)arg;
  return 0;
}
}
