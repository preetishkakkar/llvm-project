//===-- SPIRVInterlockOps.td - MLIR SPIR-V Interlock Ops ---*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the fragment shader interlock instructions of the
// SPV_EXT_fragment_shader_interlock specification. They bracket the critical
// section that the interlock execution modes order between fragments covering
// the same pixel, sample or shading-rate cell.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_SPIRV_IR_INTERLOCK_OPS
#define MLIR_DIALECT_SPIRV_IR_INTERLOCK_OPS

include "mlir/Dialect/SPIRV/IR/SPIRVBase.td"

// The two instructions delimit a critical section whose execution is ordered
// between invocations, so they are neither Pure nor speculatable: moving one
// changes which memory accesses the section covers.
class SPIRV_InterlockOp<string mnemonic> :
    SPIRV_ExtVendorOp<mnemonic, [InFunctionScope]> {
  let availability = [
    MinVersion<SPIRV_V_1_0>, MaxVersion<SPIRV_V_1_6>,
    Extension<[SPV_EXT_fragment_shader_interlock]>,
    Capability<[SPIRV_C_FragmentShaderSampleInterlockEXT,
                SPIRV_C_FragmentShaderPixelInterlockEXT,
                SPIRV_C_FragmentShaderShadingRateInterlockEXT]>
  ];

  let arguments = (ins);
  let results = (outs);
  let assemblyFormat = "attr-dict";
  let hasVerifier = 0;
}

// -----

def SPIRV_EXTBeginInvocationInterlockOp : SPIRV_InterlockOp<"BeginInvocationInterlock"> {
  let summary = "Begins the ordered critical section of a fragment invocation.";

  let description = [{
    Marks the beginning of the critical section whose execution is ordered with
    respect to the other fragment shader invocations that the entry point's
    interlock execution mode covers: the same pixel for
    PixelInterlockOrderedEXT or PixelInterlockUnorderedEXT, the same sample for
    the SampleInterlock modes, the same shading-rate cell for the
    ShadingRateInterlock ones.

    This instruction is only valid in the Fragment Execution Model, in an entry
    point that declares one interlock execution mode, and it must appear in the
    entry point function itself rather than in a function it calls, outside any
    loop or conditional, and at most once, all of which validation of the
    serialized module checks.

    #### Example:

    ```mlir
    spirv.EXTBeginInvocationInterlock
    ```
  }];
}

// -----

def SPIRV_EXTEndInvocationInterlockOp : SPIRV_InterlockOp<"EndInvocationInterlock"> {
  let summary = "Ends the ordered critical section of a fragment invocation.";

  let description = [{
    Marks the end of the critical section begun by
    OpBeginInvocationInterlockEXT. The same restrictions apply: the Fragment
    Execution Model, one interlock execution mode on the entry point, the entry
    point function itself, outside any loop or conditional, and at most once.

    #### Example:

    ```mlir
    spirv.EXTEndInvocationInterlock
    ```
  }];
}

#endif // MLIR_DIALECT_SPIRV_IR_INTERLOCK_OPS
