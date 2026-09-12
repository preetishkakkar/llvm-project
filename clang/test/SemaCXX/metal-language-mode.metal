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
