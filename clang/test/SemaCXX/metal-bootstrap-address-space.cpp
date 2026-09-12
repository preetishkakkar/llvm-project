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

struct Record { unsigned first; unsigned second; }; // cpp-note 3 {{candidate constructor}} cpp-note 2 {{assignment operator) not viable}}
struct Packed { // cpp-note {{copy assignment operator) not viable}}
  unsigned value;
  Packed() = default;
  Packed(const Packed &) = default;
  Packed(unsigned scalar);
  operator unsigned() const; // cpp-note {{candidate function not viable}}
};

void pointer_separation_stays(DEVICE Record *records, unsigned index) {
  unsigned *pointer = &records[index].first; // both-error {{cannot initialize a variable of type 'unsigned int *'}}
}

#ifdef PLAIN_CPP
void rejected_cpp_copies(DEVICE Record *records, DEVICE Packed *packed, unsigned index) {
  Record local = records[index]; // cpp-error {{no matching constructor for initialization of 'Record'}}
  records[index] = local; // cpp-error {{no viable overloaded '='}}
  unsigned scalar = packed[index]; // cpp-error {{no viable conversion}}
  packed[index] = scalar; // cpp-error {{no viable overloaded '='}}
}
#else
void object_copies(DEVICE Record *records, CONSTANT Record *constants, DEVICE Packed *packed, unsigned index) {
  Record local = records[index];
  Record other = constants[index];
  records[index] = local;
  records[index] = constants[index];
  unsigned scalar = packed[index];
  packed[index] = scalar;
  unsigned component = packed[index].value;
  Record &wrong = records[index]; // expected-error {{changes address space}}
}
#endif
