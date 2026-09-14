// RUN: mlir-opt -split-input-file -verify-diagnostics %s
spirv.func @query(%image : !spirv.sampled_image<!spirv.image<f32, Dim2D, NoDepth, Arrayed, SingleSampled, NeedSampler, Unknown>>, %uv : vector<2xf32>) "None" {
  %result = spirv.ImageQueryLod %image, %uv : !spirv.sampled_image<!spirv.image<f32, Dim2D, NoDepth, Arrayed, SingleSampled, NeedSampler, Unknown>>, vector<2xf32> -> vector<2xf32>
  spirv.Return
}
// -----
spirv.func @bad_layer(%image : !spirv.sampled_image<!spirv.image<f32, Dim2D, NoDepth, Arrayed, SingleSampled, NeedSampler, Unknown>>, %uv : vector<3xf32>) "None" {
  // expected-error @+1 {{expected 2 spatial coordinate}}
  %result = spirv.ImageQueryLod %image, %uv : !spirv.sampled_image<!spirv.image<f32, Dim2D, NoDepth, Arrayed, SingleSampled, NeedSampler, Unknown>>, vector<3xf32> -> vector<2xf32>
  spirv.Return
}
