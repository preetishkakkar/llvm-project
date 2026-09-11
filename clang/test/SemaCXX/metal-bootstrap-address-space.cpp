// RUN: %clang_cc1 -triple spir64-unknown-unknown -std=c++17 -fmetal-bootstrap -fsyntax-only -verify=expected,both %s
// RUN: %clang_cc1 -triple spir64-unknown-unknown -std=c++17 -fsyntax-only -verify=cpp,both -DPLAIN_CPP %s

#define GROUP __attribute__((address_space(3)))
#define DEVICE __attribute__((address_space(1)))
#define CONSTANT __attribute__((address_space(2)))

void ordinary_storage() {
  unsigned scalar;
  unsigned array[4];
  unsigned DEVICE *pointer;
}

#ifdef PLAIN_CPP
void rejected_cpp_storage() {
  GROUP unsigned scalar; // cpp-error {{automatic variable qualified with an address space}}
  GROUP unsigned array[4]; // cpp-error {{automatic variable qualified with an address space}}
}
#else
void threadgroup_storage(unsigned index) {
  GROUP unsigned scalar;
  GROUP unsigned array[4];
  scalar = index;
  array[index] = scalar;
  GROUP unsigned *pointer = array;
  unsigned *wrong = array; // expected-error {{cannot initialize a variable of type 'unsigned int *'}}
}
#endif

void other_address_spaces_stay_rejected() {
  DEVICE unsigned device; // both-error {{automatic variable qualified with an address space}}
  CONSTANT unsigned constant; // both-error {{automatic variable qualified with an address space}}
}
