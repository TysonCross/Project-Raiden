/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * noise_removal_gpu.h
 *
 * Code generation for function 'noise_removal_gpu'
 *
 */

#ifndef NOISE_REMOVAL_GPU_H
#define NOISE_REMOVAL_GPU_H

/* Include files */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tmwtypes.h"
#include "mex.h"
#include "emlrt.h"
#include "rtwtypes.h"
#include "noise_removal_gpu_types.h"

/* Function Declarations */
extern void noise_removal_gpu(noise_removal_gpuStackData *SD, const uint16_T
  noisyRGB[393216], uint16_T rgbFixed[393216]);

#endif

/* End of code generation (noise_removal_gpu.h) */
