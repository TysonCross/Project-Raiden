/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * noise_removal_gpu_types.h
 *
 * Code generation for function 'noise_removal_gpu'
 *
 */

#ifndef NOISE_REMOVAL_GPU_TYPES_H
#define NOISE_REMOVAL_GPU_TYPES_H

/* Include files */
#include "rtwtypes.h"

/* Type Definitions */
typedef struct {
  struct {
    uint16_T outImg[131072];
    uint16_T b_outImg[131072];
  } f0;
} noise_removal_gpuStackData;

#endif

/* End of code generation (noise_removal_gpu_types.h) */
