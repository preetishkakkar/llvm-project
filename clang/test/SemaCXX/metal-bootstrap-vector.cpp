// RUN: %clang_cc1 -triple spir64-unknown-unknown -std=c++17 -fmetal-bootstrap -fsyntax-only -verify %s
// RUN: %clang_cc1 -triple spir64-unknown-unknown -std=c++17 -fsyntax-only -verify=cpp -DPLAIN_CPP %s

typedef float float2 __attribute__((ext_vector_type(2)));
typedef float float4 __attribute__((ext_vector_type(4)));

#ifdef PLAIN_CPP
float4 ordinary_cpp() {
  return float4(1.0f, 2.0f, 3.0f, 4.0f); // cpp-error {{excess elements in scalar initializer}}
}
#else
float4 constructors(float x, float2 xy) {
  float4 a = float4(x, 2.0f, 3.0f, 4.0f);
  float4 b = float4(xy, x, 4.0f);
  float4 c = float4(xy, xy);
  float4 d = float4(x);
  float4 e = float4{1.0f};
  float4 f = float4();
  return a + b + c + d + e + f;
}
template <class T> T construct(float2 x) { return T(x, x); }
float4 instantiated(float2 x) { return construct<float4>(x); }
float4 numeric(unsigned x) { return float4(x, x, x, x); }
void invalid(float2 x) {
  (void)float4(x, 1.0f); // expected-error {{too few elements in vector initialization}}
  (void)float4(x, x, 1.0f); // expected-error {{too many elements in vector initialization}}
  (void)float4{x, x, x}; // expected-error {{too many elements in vector initialization}}
  int ordinary{1.5f}; // expected-error {{cannot be narrowed}} expected-note {{insert an explicit cast}} expected-warning {{implicit conversion from 'float' to 'int' changes value}}
}
#endif
