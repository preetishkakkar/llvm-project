// RUN: mlir-opt -split-input-file -verify-diagnostics %s | FileCheck %s

func.func @samples(%image : !spirv.image<f32, Dim2D, NoDepth, NonArrayed, MultiSampled, NeedSampler, Unknown>) -> i32 {
  // CHECK: spirv.ImageQuerySamples
  %n = spirv.ImageQuerySamples %image : !spirv.image<f32, Dim2D, NoDepth, NonArrayed, MultiSampled, NeedSampler, Unknown> -> i32
  return %n : i32
}

// -----

func.func @fetch(%image : !spirv.image<f32, Dim2D, NoDepth, NonArrayed, MultiSampled, NeedSampler, Unknown>, %coord : vector<2xi32>, %sample : i32) -> vector<4xf32> {
  // CHECK: spirv.ImageFetch {{.*}} ["Sample"]
  %v = spirv.ImageFetch %image, %coord ["Sample"], %sample : !spirv.image<f32, Dim2D, NoDepth, NonArrayed, MultiSampled, NeedSampler, Unknown>, vector<2xi32>, i32 -> vector<4xf32>
  return %v : vector<4xf32>
}

// -----

func.func @missing_sample(%image : !spirv.image<f32, Dim2D, NoDepth, NonArrayed, MultiSampled, NeedSampler, Unknown>, %coord : vector<2xi32>) -> vector<4xf32> {
  // expected-error @+1 {{multisampled image accesses require a Sample operand}}
  %v = spirv.ImageFetch %image, %coord : !spirv.image<f32, Dim2D, NoDepth, NonArrayed, MultiSampled, NeedSampler, Unknown>, vector<2xi32> -> vector<4xf32>
  return %v : vector<4xf32>
}

// -----

func.func @single(%image : !spirv.image<f32, Dim2D, NoDepth, NonArrayed, SingleSampled, NeedSampler, Unknown>) -> i32 {
  // expected-error @+1 {{the MS operand of the underlying image type must be MultiSampled}}
  %n = spirv.ImageQuerySamples %image : !spirv.image<f32, Dim2D, NoDepth, NonArrayed, SingleSampled, NeedSampler, Unknown> -> i32
  return %n : i32
}

// -----

func.func @buffer(%image : !spirv.image<f32, Buffer, NoDepth, NonArrayed, MultiSampled, NeedSampler, Unknown>) -> i32 {
  // expected-error @+1 {{the Dim operand of the underlying image must be Dim2D}}
  %n = spirv.ImageQuerySamples %image : !spirv.image<f32, Buffer, NoDepth, NonArrayed, MultiSampled, NeedSampler, Unknown> -> i32
  return %n : i32
}
