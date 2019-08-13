/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * noise_removal_gpu_terminate.cu
 *
 * Code generation for function 'noise_removal_gpu_terminate'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "noise_removal_gpu.h"
#include "noise_removal_gpu_terminate.h"
#include "_coder_noise_removal_gpu_mex.h"
#include "noise_removal_gpu_data.h"

/* Function Definitions */
void noise_removal_gpu_atexit()
{
  mexFunctionCreateRootTLS();
  emlrtEnterRtStackR2012b(emlrtRootTLSGlobal);
  emlrtLeaveRtStackR2012b(emlrtRootTLSGlobal);
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
  emlrtExitTimeCleanup(&emlrtContextGlobal);
}

void noise_removal_gpu_terminate()
{
  emlrtLeaveRtStackR2012b(emlrtRootTLSGlobal);
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
}

/* End of code generation (noise_removal_gpu_terminate.cu) */
