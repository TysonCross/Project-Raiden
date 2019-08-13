/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * noise_removal_gpu_initialize.cu
 *
 * Code generation for function 'noise_removal_gpu_initialize'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "noise_removal_gpu.h"
#include "noise_removal_gpu_initialize.h"
#include "_coder_noise_removal_gpu_mex.h"
#include "noise_removal_gpu_data.h"

/* Function Definitions */
void noise_removal_gpu_initialize()
{
  mexFunctionCreateRootTLS();
  emlrtClearAllocCountR2012b(emlrtRootTLSGlobal, false, 0U, 0);
  emlrtEnterRtStackR2012b(emlrtRootTLSGlobal);
  emlrtLicenseCheckR2012b(emlrtRootTLSGlobal, "Distrib_Computing_Toolbox", 2);
  emlrtLicenseCheckR2012b(emlrtRootTLSGlobal, "Image_Toolbox", 2);
  emlrtFirstTimeR2012b(emlrtRootTLSGlobal);
}

/* End of code generation (noise_removal_gpu_initialize.cu) */
