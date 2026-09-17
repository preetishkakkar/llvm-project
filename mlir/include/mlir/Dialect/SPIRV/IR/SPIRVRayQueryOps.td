//===- SPIRVRayQueryOps.td - SPIR-V ray query ops ----------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the ray query instructions of SPV_KHR_ray_query. A ray
// query is an opaque traversal state in a Function or Private variable of
// !spirv.ray_query, initialized against a !spirv.acceleration_structure and
// then stepped and read through these instructions.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_SPIRV_IR_RAY_QUERY_OPS
#define MLIR_DIALECT_SPIRV_IR_RAY_QUERY_OPS

include "mlir/Dialect/SPIRV/IR/SPIRVBase.td"

def SPIRV_AccelerationStructure : DialectType<SPIRV_Dialect,
    CPred<"::llvm::isa<::mlir::spirv::AccelerationStructureKHRType>($_self)">,
    "acceleration structure type">;

class SPIRV_RayQueryOp<string mnemonic, list<Trait> traits = []> :
    SPIRV_KhrVendorOp<"RayQuery" # mnemonic, traits> {
  let availability = [
    MinVersion<SPIRV_V_1_0>, MaxVersion<SPIRV_V_1_6>,
    Extension<[SPV_KHR_ray_query]>,
    Capability<[SPIRV_C_RayQueryKHR]>
  ];
  let hasVerifier = 0;
}

// -----

def SPIRV_KHRRayQueryInitializeOp : SPIRV_RayQueryOp<"Initialize"> {
  let summary = "Initializes a ray query against an acceleration structure.";
  let description = [{
    Starts traversal of `accel` by the ray from `ray_origin` along
    `ray_direction` over the parametric range [`ray_t_min`, `ray_t_max`], under
    `ray_flags` and `cull_mask`. `ray_query` is a pointer to a ray query
    variable, which must not be in active traversal.

    #### Example:

    ```mlir
    spirv.KHR.RayQueryInitialize %q, %as, %flags, %mask, %origin, %tmin, %direction, %tmax
      : !spirv.ptr<!spirv.ray_query, Function>, !spirv.acceleration_structure, i32, i32, vector<3xf32>, f32, vector<3xf32>, f32
    ```
  }];
  let arguments = (ins
    SPIRV_AnyPtr:$ray_query,
    SPIRV_AccelerationStructure:$accel,
    SPIRV_Int32:$ray_flags,
    SPIRV_Int32:$cull_mask,
    VectorOfLengthAndType<[3], [SPIRV_Float32]>:$ray_origin,
    SPIRV_Float32:$ray_t_min,
    VectorOfLengthAndType<[3], [SPIRV_Float32]>:$ray_direction,
    SPIRV_Float32:$ray_t_max
  );
  let results = (outs);
  let assemblyFormat = "operands attr-dict `:` type(operands)";
}

def SPIRV_KHRRayQueryTerminateOp : SPIRV_RayQueryOp<"Terminate"> {
  let summary = "Terminates traversal of a ray query.";
  let description = [{
    Ends the traversal of the ray query `ray_query`, keeping its committed
    intersection.

    #### Example:

    ```mlir
    spirv.KHR.RayQueryTerminate %q : !spirv.ptr<!spirv.ray_query, Function>
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query);
  let results = (outs);
  let assemblyFormat = "operands attr-dict `:` type(operands)";
}

def SPIRV_KHRRayQueryGenerateIntersectionOp : SPIRV_RayQueryOp<"GenerateIntersection"> {
  let summary = "Commits a generated intersection for a candidate AABB.";
  let description = [{
    Commits an intersection at parametric distance `hit_t` for the candidate
    AABB intersection of `ray_query`.

    #### Example:

    ```mlir
    spirv.KHR.RayQueryGenerateIntersection %q, %t : !spirv.ptr<!spirv.ray_query, Function>, f32
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query, SPIRV_Float32:$hit_t);
  let results = (outs);
  let assemblyFormat = "operands attr-dict `:` type(operands)";
}

def SPIRV_KHRRayQueryConfirmIntersectionOp : SPIRV_RayQueryOp<"ConfirmIntersection"> {
  let summary = "Commits the candidate triangle intersection of a ray query.";
  let description = [{
    Commits the current candidate triangle intersection of `ray_query`.

    #### Example:

    ```mlir
    spirv.KHR.RayQueryConfirmIntersection %q : !spirv.ptr<!spirv.ray_query, Function>
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query);
  let results = (outs);
  let assemblyFormat = "operands attr-dict `:` type(operands)";
}

def SPIRV_KHRRayQueryProceedOp : SPIRV_RayQueryOp<"Proceed"> {
  let summary = "Advances traversal of a ray query to its next candidate.";
  let description = [{
    Continues the traversal of `ray_query` until it has a new candidate
    intersection to report (result true) or has finished (result false).

    #### Example:

    ```mlir
    %more = spirv.KHR.RayQueryProceed %q : !spirv.ptr<!spirv.ray_query, Function> -> i1
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query);
  let results = (outs SPIRV_Bool:$result);
  let assemblyFormat = "$ray_query attr-dict `:` type($ray_query) `->` type($result)";
}

def SPIRV_KHRRayQueryGetIntersectionTypeOp : SPIRV_RayQueryOp<"GetIntersectionType"> {
  let summary = "Reads the kind of the candidate or committed intersection.";
  let description = [{
    Reads the kind of the candidate or committed intersection of `ray_query`, for the candidate or the committed
    intersection as `intersection` says.

    #### Example:

    ```mlir
    %v = spirv.KHR.RayQueryGetIntersectionType %q {intersection = #spirv.ray_query_intersection<RayQueryCommittedIntersectionKHR>}
      : !spirv.ptr<!spirv.ray_query, Function> -> SPIRV_Int32
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query, SPIRV_RayQueryIntersectionAttr:$intersection);
  let results = (outs SPIRV_Int32:$result);
  let assemblyFormat = "$ray_query attr-dict `:` type($ray_query) `->` type($result)";
}

def SPIRV_KHRRayQueryGetIntersectionTOp : SPIRV_RayQueryOp<"GetIntersectionT"> {
  let summary = "Reads the parametric distance of the intersection along the ray.";
  let description = [{
    Reads the parametric distance of the intersection along the ray of `ray_query`, for the candidate or the committed
    intersection as `intersection` says.

    #### Example:

    ```mlir
    %v = spirv.KHR.RayQueryGetIntersectionT %q {intersection = #spirv.ray_query_intersection<RayQueryCommittedIntersectionKHR>}
      : !spirv.ptr<!spirv.ray_query, Function> -> SPIRV_Float32
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query, SPIRV_RayQueryIntersectionAttr:$intersection);
  let results = (outs SPIRV_Float32:$result);
  let assemblyFormat = "$ray_query attr-dict `:` type($ray_query) `->` type($result)";
}

def SPIRV_KHRRayQueryGetIntersectionInstanceCustomIndexOp : SPIRV_RayQueryOp<"GetIntersectionInstanceCustomIndex"> {
  let summary = "Reads the custom index of the instance the intersection is in.";
  let description = [{
    Reads the custom index of the instance the intersection is in of `ray_query`, for the candidate or the committed
    intersection as `intersection` says.

    #### Example:

    ```mlir
    %v = spirv.KHR.RayQueryGetIntersectionInstanceCustomIndex %q {intersection = #spirv.ray_query_intersection<RayQueryCommittedIntersectionKHR>}
      : !spirv.ptr<!spirv.ray_query, Function> -> SPIRV_Int32
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query, SPIRV_RayQueryIntersectionAttr:$intersection);
  let results = (outs SPIRV_Int32:$result);
  let assemblyFormat = "$ray_query attr-dict `:` type($ray_query) `->` type($result)";
}

def SPIRV_KHRRayQueryGetIntersectionInstanceIdOp : SPIRV_RayQueryOp<"GetIntersectionInstanceId"> {
  let summary = "Reads the index of the instance the intersection is in.";
  let description = [{
    Reads the index of the instance the intersection is in of `ray_query`, for the candidate or the committed
    intersection as `intersection` says.

    #### Example:

    ```mlir
    %v = spirv.KHR.RayQueryGetIntersectionInstanceId %q {intersection = #spirv.ray_query_intersection<RayQueryCommittedIntersectionKHR>}
      : !spirv.ptr<!spirv.ray_query, Function> -> SPIRV_Int32
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query, SPIRV_RayQueryIntersectionAttr:$intersection);
  let results = (outs SPIRV_Int32:$result);
  let assemblyFormat = "$ray_query attr-dict `:` type($ray_query) `->` type($result)";
}

def SPIRV_KHRRayQueryGetIntersectionInstanceShaderBindingTableRecordOffsetOp : SPIRV_RayQueryOp<"GetIntersectionInstanceShaderBindingTableRecordOffset"> {
  let summary = "Reads the shader binding table record offset of the instance the intersection is in.";
  let description = [{
    Reads the shader binding table record offset of the instance the intersection is in of `ray_query`, for the candidate or the committed
    intersection as `intersection` says.

    #### Example:

    ```mlir
    %v = spirv.KHR.RayQueryGetIntersectionInstanceShaderBindingTableRecordOffset %q {intersection = #spirv.ray_query_intersection<RayQueryCommittedIntersectionKHR>}
      : !spirv.ptr<!spirv.ray_query, Function> -> SPIRV_Int32
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query, SPIRV_RayQueryIntersectionAttr:$intersection);
  let results = (outs SPIRV_Int32:$result);
  let assemblyFormat = "$ray_query attr-dict `:` type($ray_query) `->` type($result)";
}

def SPIRV_KHRRayQueryGetIntersectionGeometryIndexOp : SPIRV_RayQueryOp<"GetIntersectionGeometryIndex"> {
  let summary = "Reads the geometry index of the intersection.";
  let description = [{
    Reads the geometry index of the intersection of `ray_query`, for the candidate or the committed
    intersection as `intersection` says.

    #### Example:

    ```mlir
    %v = spirv.KHR.RayQueryGetIntersectionGeometryIndex %q {intersection = #spirv.ray_query_intersection<RayQueryCommittedIntersectionKHR>}
      : !spirv.ptr<!spirv.ray_query, Function> -> SPIRV_Int32
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query, SPIRV_RayQueryIntersectionAttr:$intersection);
  let results = (outs SPIRV_Int32:$result);
  let assemblyFormat = "$ray_query attr-dict `:` type($ray_query) `->` type($result)";
}

def SPIRV_KHRRayQueryGetIntersectionPrimitiveIndexOp : SPIRV_RayQueryOp<"GetIntersectionPrimitiveIndex"> {
  let summary = "Reads the primitive index of the intersection.";
  let description = [{
    Reads the primitive index of the intersection of `ray_query`, for the candidate or the committed
    intersection as `intersection` says.

    #### Example:

    ```mlir
    %v = spirv.KHR.RayQueryGetIntersectionPrimitiveIndex %q {intersection = #spirv.ray_query_intersection<RayQueryCommittedIntersectionKHR>}
      : !spirv.ptr<!spirv.ray_query, Function> -> SPIRV_Int32
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query, SPIRV_RayQueryIntersectionAttr:$intersection);
  let results = (outs SPIRV_Int32:$result);
  let assemblyFormat = "$ray_query attr-dict `:` type($ray_query) `->` type($result)";
}

def SPIRV_KHRRayQueryGetIntersectionBarycentricsOp : SPIRV_RayQueryOp<"GetIntersectionBarycentrics"> {
  let summary = "Reads the barycentric coordinates of a triangle intersection.";
  let description = [{
    Reads the barycentric coordinates of a triangle intersection of `ray_query`, for the candidate or the committed
    intersection as `intersection` says.

    #### Example:

    ```mlir
    %v = spirv.KHR.RayQueryGetIntersectionBarycentrics %q {intersection = #spirv.ray_query_intersection<RayQueryCommittedIntersectionKHR>}
      : !spirv.ptr<!spirv.ray_query, Function> -> ...
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query, SPIRV_RayQueryIntersectionAttr:$intersection);
  let results = (outs VectorOfLengthAndType<[2], [SPIRV_Float32]>:$result);
  let assemblyFormat = "$ray_query attr-dict `:` type($ray_query) `->` type($result)";
}

def SPIRV_KHRRayQueryGetIntersectionFrontFaceOp : SPIRV_RayQueryOp<"GetIntersectionFrontFace"> {
  let summary = "Reads whether a triangle intersection was front-facing.";
  let description = [{
    Reads whether a triangle intersection was front-facing of `ray_query`, for the candidate or the committed
    intersection as `intersection` says.

    #### Example:

    ```mlir
    %v = spirv.KHR.RayQueryGetIntersectionFrontFace %q {intersection = #spirv.ray_query_intersection<RayQueryCommittedIntersectionKHR>}
      : !spirv.ptr<!spirv.ray_query, Function> -> SPIRV_Bool
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query, SPIRV_RayQueryIntersectionAttr:$intersection);
  let results = (outs SPIRV_Bool:$result);
  let assemblyFormat = "$ray_query attr-dict `:` type($ray_query) `->` type($result)";
}

def SPIRV_KHRRayQueryGetIntersectionObjectRayDirectionOp : SPIRV_RayQueryOp<"GetIntersectionObjectRayDirection"> {
  let summary = "Reads the ray direction in object space.";
  let description = [{
    Reads the ray direction in object space of `ray_query`, for the candidate or the committed
    intersection as `intersection` says.

    #### Example:

    ```mlir
    %v = spirv.KHR.RayQueryGetIntersectionObjectRayDirection %q {intersection = #spirv.ray_query_intersection<RayQueryCommittedIntersectionKHR>}
      : !spirv.ptr<!spirv.ray_query, Function> -> ...
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query, SPIRV_RayQueryIntersectionAttr:$intersection);
  let results = (outs VectorOfLengthAndType<[3], [SPIRV_Float32]>:$result);
  let assemblyFormat = "$ray_query attr-dict `:` type($ray_query) `->` type($result)";
}

def SPIRV_KHRRayQueryGetIntersectionObjectRayOriginOp : SPIRV_RayQueryOp<"GetIntersectionObjectRayOrigin"> {
  let summary = "Reads the ray origin in object space.";
  let description = [{
    Reads the ray origin in object space of `ray_query`, for the candidate or the committed
    intersection as `intersection` says.

    #### Example:

    ```mlir
    %v = spirv.KHR.RayQueryGetIntersectionObjectRayOrigin %q {intersection = #spirv.ray_query_intersection<RayQueryCommittedIntersectionKHR>}
      : !spirv.ptr<!spirv.ray_query, Function> -> ...
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query, SPIRV_RayQueryIntersectionAttr:$intersection);
  let results = (outs VectorOfLengthAndType<[3], [SPIRV_Float32]>:$result);
  let assemblyFormat = "$ray_query attr-dict `:` type($ray_query) `->` type($result)";
}

def SPIRV_KHRRayQueryGetIntersectionObjectToWorldOp : SPIRV_RayQueryOp<"GetIntersectionObjectToWorld"> {
  let summary = "Reads the object-to-world transform of the instance.";
  let description = [{
    Reads the object-to-world transform of the instance of `ray_query`, for the candidate or the committed
    intersection as `intersection` says.

    #### Example:

    ```mlir
    %v = spirv.KHR.RayQueryGetIntersectionObjectToWorld %q {intersection = #spirv.ray_query_intersection<RayQueryCommittedIntersectionKHR>}
      : !spirv.ptr<!spirv.ray_query, Function> -> ...
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query, SPIRV_RayQueryIntersectionAttr:$intersection);
  let results = (outs SPIRV_AnyMatrix:$result);
  let assemblyFormat = "$ray_query attr-dict `:` type($ray_query) `->` type($result)";
}

def SPIRV_KHRRayQueryGetIntersectionWorldToObjectOp : SPIRV_RayQueryOp<"GetIntersectionWorldToObject"> {
  let summary = "Reads the world-to-object transform of the instance.";
  let description = [{
    Reads the world-to-object transform of the instance of `ray_query`, for the candidate or the committed
    intersection as `intersection` says.

    #### Example:

    ```mlir
    %v = spirv.KHR.RayQueryGetIntersectionWorldToObject %q {intersection = #spirv.ray_query_intersection<RayQueryCommittedIntersectionKHR>}
      : !spirv.ptr<!spirv.ray_query, Function> -> ...
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query, SPIRV_RayQueryIntersectionAttr:$intersection);
  let results = (outs SPIRV_AnyMatrix:$result);
  let assemblyFormat = "$ray_query attr-dict `:` type($ray_query) `->` type($result)";
}

def SPIRV_KHRRayQueryGetRayTMinOp : SPIRV_RayQueryOp<"GetRayTMin"> {
  let summary = "Reads the minimum parametric distance of the query's ray.";
  let description = [{
    Reads the minimum parametric distance of the query's ray of `ray_query`.

    #### Example:

    ```mlir
    %v = spirv.KHR.RayQueryGetRayTMin %q : !spirv.ptr<!spirv.ray_query, Function> -> SPIRV_Float32
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query);
  let results = (outs SPIRV_Float32:$result);
  let assemblyFormat = "$ray_query attr-dict `:` type($ray_query) `->` type($result)";
}

def SPIRV_KHRRayQueryGetRayFlagsOp : SPIRV_RayQueryOp<"GetRayFlags"> {
  let summary = "Reads the flags the query was initialized with.";
  let description = [{
    Reads the flags the query was initialized with of `ray_query`.

    #### Example:

    ```mlir
    %v = spirv.KHR.RayQueryGetRayFlags %q : !spirv.ptr<!spirv.ray_query, Function> -> SPIRV_Int32
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query);
  let results = (outs SPIRV_Int32:$result);
  let assemblyFormat = "$ray_query attr-dict `:` type($ray_query) `->` type($result)";
}

def SPIRV_KHRRayQueryGetIntersectionCandidateAABBOpaqueOp : SPIRV_RayQueryOp<"GetIntersectionCandidateAABBOpaque"> {
  let summary = "Reads whether the candidate AABB intersection is opaque.";
  let description = [{
    Reads whether the candidate AABB intersection is opaque of `ray_query`.

    #### Example:

    ```mlir
    %v = spirv.KHR.RayQueryGetIntersectionCandidateAABBOpaque %q : !spirv.ptr<!spirv.ray_query, Function> -> SPIRV_Bool
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query);
  let results = (outs SPIRV_Bool:$result);
  let assemblyFormat = "$ray_query attr-dict `:` type($ray_query) `->` type($result)";
}

def SPIRV_KHRRayQueryGetWorldRayDirectionOp : SPIRV_RayQueryOp<"GetWorldRayDirection"> {
  let summary = "Reads the ray direction in world space.";
  let description = [{
    Reads the ray direction in world space of `ray_query`.

    #### Example:

    ```mlir
    %v = spirv.KHR.RayQueryGetWorldRayDirection %q : !spirv.ptr<!spirv.ray_query, Function> -> vector<3xf32>
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query);
  let results = (outs VectorOfLengthAndType<[3], [SPIRV_Float32]>:$result);
  let assemblyFormat = "$ray_query attr-dict `:` type($ray_query) `->` type($result)";
}

def SPIRV_KHRRayQueryGetWorldRayOriginOp : SPIRV_RayQueryOp<"GetWorldRayOrigin"> {
  let summary = "Reads the ray origin in world space.";
  let description = [{
    Reads the ray origin in world space of `ray_query`.

    #### Example:

    ```mlir
    %v = spirv.KHR.RayQueryGetWorldRayOrigin %q : !spirv.ptr<!spirv.ray_query, Function> -> vector<3xf32>
    ```
  }];
  let arguments = (ins SPIRV_AnyPtr:$ray_query);
  let results = (outs VectorOfLengthAndType<[3], [SPIRV_Float32]>:$result);
  let assemblyFormat = "$ray_query attr-dict `:` type($ray_query) `->` type($result)";
}

#endif // MLIR_DIALECT_SPIRV_IR_RAY_QUERY_OPS
