//===-- SPIRVInterpolateOps.td - MLIR SPIR-V Interpolation Ops -*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the GLSL.std.450 pull-model interpolation instructions
// (InterpolateAtCentroid, InterpolateAtSample and InterpolateAtOffset). Unlike
// every other GL extended instruction, these take a pointer to a fragment Input
// variable rather than a value, because the interpolation is performed on the
// interface variable itself.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_SPIRV_IR_INTERPOLATE_OPS
#define MLIR_DIALECT_SPIRV_IR_INTERPOLATE_OPS

include "mlir/Dialect/SPIRV/IR/SPIRVBase.td"

// The interpolation instructions read the values a quad's invocations hold for
// the interface variable, so like the derivative instructions they are neither
// Pure nor speculatable: moving one into or out of divergent control flow
// changes its result. They also require the InterpolationFunction capability,
// which a Vulkan host enables through the sampleRateShading feature.
class SPIRV_GLInterpolateOp<string mnemonic, int opcode, list<Trait> traits = []> :
    SPIRV_ExtInstOp<mnemonic, "GL", "GLSL.std.450", opcode,
                    !listconcat([InFunctionScope], traits)> {
  let availability = [
    MinVersion<SPIRV_V_1_0>, MaxVersion<SPIRV_V_1_6>, Extension<[]>,
    Capability<[SPIRV_C_InterpolationFunction]>
  ];
  // The pointer's storage class and pointee type are exactly what SPIRV-Tools validates on the
  // serialized module, which every module this dialect produces goes through.
  let hasVerifier = 0;
}

// -----

def SPIRV_GLInterpolateAtCentroidOp : SPIRV_GLInterpolateOp<"InterpolateAtCentroid", 76> {
  let summary = [{
    Return the value of the input interpolant sampled at a centroid location.
  }];

  let description = [{
    The value is sampled at a location inside both the pixel and the primitive
    being processed. Result Type must be a floating-point scalar or vector.
    Interpolant must be a pointer to the Input Storage Class, pointing to a
    value of the same type as Result Type. This instruction is only valid in
    the Fragment Execution Model.

    #### Example:

    ```mlir
    %0 = spirv.GL.InterpolateAtCentroid %input : !spirv.ptr<vector<4xf32>, Input> -> vector<4xf32>
    ```
  }];

  let arguments = (ins
    SPIRV_AnyPtr:$interpolant
  );

  let results = (outs
    SPIRV_ScalarOrVectorOf<SPIRV_Float>:$result
  );

  let assemblyFormat = [{
    $interpolant `:` type($interpolant) `->` type($result) attr-dict
  }];
}

// -----

def SPIRV_GLInterpolateAtSampleOp : SPIRV_GLInterpolateOp<"InterpolateAtSample", 77> {
  let summary = [{
    Return the value of the input interpolant at the location of a sample.
  }];

  let description = [{
    The value is sampled at the location of the sample numbered Sample. If
    multisampling is not in use, or Sample names no sample of the pixel, the
    position of the interpolation is undefined. Result Type must be a
    floating-point scalar or vector; Interpolant must be a pointer to the Input
    Storage Class of the same type, and Sample must be a 32-bit integer. This
    instruction is only valid in the Fragment Execution Model.

    #### Example:

    ```mlir
    %0 = spirv.GL.InterpolateAtSample %input, %sample : !spirv.ptr<vector<4xf32>, Input>, i32 -> vector<4xf32>
    ```
  }];

  let arguments = (ins
    SPIRV_AnyPtr:$interpolant,
    SPIRV_Int32:$sample
  );

  let results = (outs
    SPIRV_ScalarOrVectorOf<SPIRV_Float>:$result
  );

  let assemblyFormat = [{
    $interpolant `,` $sample `:` type($interpolant) `,` type($sample) `->` type($result) attr-dict
  }];
}

// -----

def SPIRV_GLInterpolateAtOffsetOp : SPIRV_GLInterpolateOp<"InterpolateAtOffset", 78> {
  let summary = [{
    Return the value of the input interpolant at an offset from the pixel center.
  }];

  let description = [{
    Offset is a vector of two floating-point values giving the offset from the
    center of the pixel, in units of pixels, and does not have to be one of the
    sample positions. Result Type must be a floating-point scalar or vector;
    Interpolant must be a pointer to the Input Storage Class of the same type.
    This instruction is only valid in the Fragment Execution Model.

    #### Example:

    ```mlir
    %0 = spirv.GL.InterpolateAtOffset %input, %offset : !spirv.ptr<vector<4xf32>, Input>, vector<2xf32> -> vector<4xf32>
    ```
  }];

  let arguments = (ins
    SPIRV_AnyPtr:$interpolant,
    VectorOfLengthAndType<[2], [SPIRV_Float32]>:$offset
  );

  let results = (outs
    SPIRV_ScalarOrVectorOf<SPIRV_Float>:$result
  );

  let assemblyFormat = [{
    $interpolant `,` $offset `:` type($interpolant) `,` type($offset) `->` type($result) attr-dict
  }];
}

#endif // MLIR_DIALECT_SPIRV_IR_INTERPOLATE_OPS
