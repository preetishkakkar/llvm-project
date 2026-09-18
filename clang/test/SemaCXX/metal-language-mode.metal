// RUN: %clang_cc1 -triple spir64-unknown-unknown -x metal -std=metal4.1 -fsyntax-only -verify=expected,metal41 %s
// RUN: %clang_cc1 -triple spir64-unknown-unknown -x metal -std=metal3.1 -fsyntax-only -verify=expected,metal31 -DMETAL31 %s
// RUN: %clang_cc1 -triple spir64-unknown-unknown -x c++ -std=c++17 -fsyntax-only -verify=cpp -DPLAIN_CPP %s

// Metal language mode (Metal2Vulkan fork): stage and address-space keywords,
// predefined macros and version gating. Ordinary C++ keeps every spelling as
// an identifier.

#ifdef PLAIN_CPP
// cpp-no-diagnostics
#if defined(__METAL__) || defined(__METAL_VERSION__)
#error Metal macros leaked into C++ mode
#endif
static_assert(sizeof(_Atomic(bool)) == 1, "C++ keeps byte atomics");
int device = 1;
int threadgroup = 2;
int thread = 3;
int kernel = 4;
int vertex = 5;
int fragment = 6;
int constant = 7;
#else

#if !defined(__METAL__) || !defined(__METAL2VULKAN__)
#error missing Metal mode macros
#endif
#ifdef METAL31
#if __METAL_VERSION__ != 310
#error wrong Metal version
#endif
#else
#if __METAL_VERSION__ != 410
#error wrong Metal version
#endif
#endif
#if !__has_attribute(metal_kernel) || !__has_attribute(metal_vertex) || !__has_attribute(metal_fragment)
#error missing Metal stage attributes
#endif

typedef float float4 __attribute__((ext_vector_type(4)));

struct Params {
  float scale;
};

kernel void compute(device float *out, constant Params &params,
                    threadgroup float *scratch, thread float *local) {
  thread float value = params.scale;
  scratch[0] = value;
  out[0] = scratch[0] + *local;
}

vertex float4 vertex_entry(thread float *position) {
  return float4(*position, 0.0f, 0.0f, 1.0f);
}

fragment float4 fragment_entry() {
  return float4(0.25f, 0.5f, 1.0f, 1.0f);
}

// The stage keywords are also usable as ordinary attributes.
__attribute__((metal_kernel)) void spelled_kernel() {}

// Address spaces separate pointers: a device pointer is not a thread pointer.
void pointer_separation(device float *buffer) {
  thread float *local = buffer; // expected-error {{cannot initialize a variable of type 'float *' with an lvalue of type 'device float *'}}
  threadgroup float *shared = buffer; // expected-error {{cannot initialize a variable of type 'threadgroup float *' with an lvalue of type 'device float *'}}
  (void)shared;
  (void)local;
}

// Member functions carry address-space qualifiers; the object must live in
// that space. Implicit copies and assignments work across spaces.
struct Uniforms {
  float scale;
  float apply(float value) const { return value * scale; }
  float apply_constant(float value) const constant { return value * scale; }
  float apply_device(float value) device { return value * scale; }
  void bump(float delta) { scale += delta; }
};

kernel void member_spaces(constant Uniforms &uniforms, device Uniforms *buffer, device float *out) {
  Uniforms local = uniforms;
  local.bump(1.0f);
  out[0] = local.apply(2.0f);
  out[1] = uniforms.apply_constant(2.0f);
  out[2] = buffer[0].apply_device(2.0f);
  buffer[1] = local;
  buffer[2] = uniforms;
  out[3] = uniforms.apply(2.0f); // expected-error {{cannot initialize object parameter of type 'const Uniforms' with an expression of type 'constant Uniforms'}}
  out[4] = local.apply_constant(2.0f); // expected-error {{cannot initialize object parameter of type 'const constant Uniforms' with an expression of type 'Uniforms'}}
  buffer[0].bump(1.0f); // expected-error {{cannot initialize object parameter of type 'Uniforms' with an expression of type 'device Uniforms'}}
  out[5] = local.apply_device(2.0f); // expected-error {{cannot initialize object parameter of type 'device Uniforms' with an expression of type 'Uniforms'}}
  const Uniforms frozen = local;
  out[6] = frozen.apply_constant(2.0f); // expected-error {{cannot initialize object parameter of type 'const constant Uniforms' with an expression of type 'const Uniforms'}}
}

// Vector comparisons and logical operators yield boolean vectors, and a
// one-argument vector construction converts component-wise.
typedef bool bool2 __attribute__((ext_vector_type(2)));
typedef bool bool4 __attribute__((ext_vector_type(4)));
typedef int int4 __attribute__((ext_vector_type(4)));
kernel void vector_booleans(device float4 *out, constant float4 &a, constant float4 &b) {
  bool4 mask = a < b;
  bool4 inverted = !mask;
  bool4 both = mask && inverted;
  int4 counts = int4(a);
  float4 back = float4(counts);
  bool4 flags = bool4(counts);
  out[0] = back + float4(flags);
  bool2 pair = both.xz;
  static_assert(sizeof(bool4) == 4, "one byte per component");
  (void)pair;
}

// Keywords cannot name variables.
void keywords_are_reserved() {
  int device = 1;   // expected-error {{expected unqualified-id}}
  int fragment = 2; // expected-error {{expected unqualified-id}}
}

// Version gating: `if constexpr` is C++17, so Metal 3.x reports it.
constexpr int gated() {
  if constexpr (true) // metal31-warning {{constexpr if is a C++17 extension}}
    return 1;
  return 0;
}

#endif

#ifndef PLAIN_CPP
// Threadgroup variables are never constructed: a struct or an array of structs
// in threadgroup storage needs no constructor callable in that address space,
// and other address spaces keep the constructor rules.
struct Item {
  unsigned key;
  float weight;
  Item() : key(0), weight(0.0f) {}
};
struct Plain { unsigned first; unsigned second; };
kernel void threadgroup_records(device unsigned *out, unsigned index) {
  threadgroup Item items[64];
  threadgroup Item single;
  threadgroup Plain pairs[8];
  items[index].key = index;
  single.weight = 1.0f;
  pairs[index].first = items[index].key;
  out[index] = pairs[index].first + items[index].key;
  Item local;
  out[index + 1] = local.key;
}

// Atomic types occupy at least a word: atomic_bool is four bytes in Metal.
static_assert(sizeof(_Atomic(bool)) == 4 && alignof(_Atomic(bool)) == 4, "atomic_bool is a word");
static_assert(sizeof(_Atomic(unsigned char)) == 4, "narrow atomics widen to a word");
static_assert(sizeof(_Atomic(unsigned)) == 4 && sizeof(_Atomic(float)) == 4, "word atomics stay words");
static_assert(sizeof(_Atomic(unsigned long)) == 8, "wide atomics keep their size");

// Half literals: the h/H suffix spells a half literal, and half is the native
// _Float16 type in Metal mode (the same suffix is OpenCL's __fp16 half elsewhere).
typedef _Float16 half;
static_assert(__is_same(decltype(1.5h), half), "h suffix is a half literal");
static_assert(__is_same(decltype(2.0H), half), "H suffix is a half literal");
half half_literal_arithmetic() { return 1.5h * 2.0h + 0.25H; }
static_assert(sizeof(1.0h) == 2, "half literals are 16-bit");
// bfloat literals: the bf/BF suffix spells a brain floating-point literal (__bf16).
typedef __bf16 bfloat;
static_assert(__is_same(decltype(1.5bf), bfloat), "bf suffix is a bfloat literal");
static_assert(__is_same(decltype(2.0BF), bfloat), "BF suffix is a bfloat literal");
static_assert(sizeof(0.5bf) == 2, "bfloat literals are 16-bit");
bfloat bfloat_literal_arithmetic() { return 1.5bf * 2.0bf + 0.25BF; }
// bfloat converts implicitly only to float (MSL 2.24): every other direction is explicit.
float bfloat_to_float(bfloat b) { return b; }
bfloat float_to_bfloat_explicit(float f) { return bfloat(f); }
bfloat float_to_bfloat_implicit(float f) { return f; } // expected-error {{implicit conversion from 'float' to 'bfloat' (aka '__bf16') is not allowed in Metal}}
bfloat half_to_bfloat_implicit(half h) { return h; } // expected-error {{implicit conversion from 'half' (aka '_Float16') to 'bfloat' (aka '__bf16') is not allowed in Metal}}
half bfloat_to_half_implicit(bfloat b) { return b; } // expected-error {{implicit conversion from 'bfloat' (aka '__bf16') to 'half' (aka '_Float16') is not allowed in Metal}}
float mixed_half_bfloat(half h, bfloat b) { return float(h) + float(b); }
bfloat mixed_operands(half h, bfloat b) { return bfloat(h + b); } // expected-error {{implicit conversion from 'bfloat' (aka '__bf16') to 'half' (aka '_Float16') is not allowed in Metal}} expected-error {{invalid operands to binary expression}}
#endif

// Device coherence: `coherent` is a qualifier keyword in Metal mode (recorded
// as the metal_coherent attribute) and [[coherent]] spells the same attribute;
// in plain C++ `coherent` is an ordinary identifier.
#ifndef PLAIN_CPP
kernel void coherent_keyword(device coherent float *a, coherent device float *b, device float *c [[coherent]]) { a[0] = b[0] + c[0]; }
[[coherent]] int coherent_var = 1;
#else
int coherent = 1;
#endif

// Multidimensional subscripts: Metal 4 tensors index as t[i, j], so Metal mode
// takes the C++23 form at every language version.
#ifndef PLAIN_CPP
struct grid2 { int v[4]; int operator[](int i, int j) const { return v[i * 2 + j]; } };
int multi_subscript(grid2 g) { return g[1, 0] + g[0, 1]; }
#endif
