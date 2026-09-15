//===-- SPIRVDerivativeOps.td - MLIR SPIR-V Derivative Ops -*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the derivative instructions of the SPIR-V specification
// ("3.52.17 Derivative Instructions") and OpDemoteToHelperInvocation, which a
// fragment shader uses to discard while keeping derivatives valid.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_SPIRV_IR_DERIVATIVE_OPS
#define MLIR_DIALECT_SPIRV_IR_DERIVATIVE_OPS

include "mlir/Dialect/SPIRV/IR/SPIRVBase.td"

// Derivatives read neighboring invocations of the same primitive, so their
// value depends on control flow. Do not mark these ops Pure or speculatable:
// moving them into or out of divergent control flow changes their result.
class SPIRV_DerivativeOp<string mnemonic> :
    SPIRV_UnaryOp<mnemonic, SPIRV_Float, SPIRV_Float,
                  [InFunctionScope, AllTypesMatch<["operand", "result"]>]> {
  let availability = [
    MinVersion<SPIRV_V_1_0>, MaxVersion<SPIRV_V_1_6>, Extension<[]>,
    Capability<[SPIRV_C_Shader]>
  ];
}

// -----

def SPIRV_DPdxOp : SPIRV_DerivativeOp<"DPdx"> {
  let summary = [{
    Same result as either OpDPdxFine or OpDPdxCoarse on the operand.
  }];

  let description = [{
    Selection of which one is based on external factors. Result Type must be a
    scalar or vector of floating-point type; the type of the operand must be
    the same as Result Type. This instruction is only valid in the Fragment
    Execution Model, which validation of the serialized module checks.

    #### Example:

    ```mlir
    %1 = spirv.DPdx %0 : vector<2xf32>
    ```
  }];
}

// -----

def SPIRV_DPdyOp : SPIRV_DerivativeOp<"DPdy"> {
  let summary = [{
    Same result as either OpDPdyFine or OpDPdyCoarse on the operand.
  }];

  let description = [{
    Selection of which one is based on external factors. Result Type must be a
    scalar or vector of floating-point type; the type of the operand must be
    the same as Result Type. This instruction is only valid in the Fragment
    Execution Model.

    #### Example:

    ```mlir
    %1 = spirv.DPdy %0 : f32
    ```
  }];
}

// -----

def SPIRV_FwidthOp : SPIRV_DerivativeOp<"Fwidth"> {
  let summary = [{
    Result is the same as computing the sum of the absolute values of OpDPdx
    and OpDPdy on the operand.
  }];

  let description = [{
    Result Type must be a scalar or vector of floating-point type; the type of
    the operand must be the same as Result Type. This instruction is only
    valid in the Fragment Execution Model.

    #### Example:

    ```mlir
    %1 = spirv.Fwidth %0 : vector<4xf32>
    ```
  }];
}

// -----

def SPIRV_DemoteToHelperInvocationOp : SPIRV_Op<"DemoteToHelperInvocation",
                                                [InFunctionScope]> {
  let summary = "Demote the fragment shader invocation to a helper invocation.";

  let description = [{
    Any stores to memory after this instruction are suppressed and the
    fragment does not write outputs to the framebuffer. Unlike OpKill, the
    invocation keeps executing, so derivatives computed by neighboring
    invocations remain valid. This instruction is only valid in the Fragment
    Execution Model and is not a block terminator.

    #### Example:

    ```mlir
    spirv.DemoteToHelperInvocation
    ```
  }];

  let availability = [
    MinVersion<SPIRV_V_1_0>, MaxVersion<SPIRV_V_1_6>,
    Extension<[SPV_EXT_demote_to_helper_invocation]>,
    Capability<[SPIRV_C_DemoteToHelperInvocation]>
  ];

  let arguments = (ins);

  let results = (outs);

  let assemblyFormat = "attr-dict";

  let hasVerifier = 0;
}

#endif // MLIR_DIALECT_SPIRV_IR_DERIVATIVE_OPS
