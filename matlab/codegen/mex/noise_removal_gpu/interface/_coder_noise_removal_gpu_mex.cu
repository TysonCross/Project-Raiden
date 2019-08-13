/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_noise_removal_gpu_mex.cu
 *
 * Code generation for function '_coder_noise_removal_gpu_mex'
 *
 */

/* Include files */
#include "noise_removal_gpu.h"
#include "_coder_noise_removal_gpu_mex.h"
#include "noise_removal_gpu_terminate.h"
#include "_coder_noise_removal_gpu_api.h"
#include "noise_removal_gpu_initialize.h"
#include "noise_removal_gpu_data.h"

/* Function Declarations */
static void noise_removal_gpu_mexFunction(noise_removal_gpuStackData *SD,
  int32_T nlhs, mxArray *plhs[1], int32_T nrhs, const mxArray *prhs[1]);

/* Function Definitions */
static void noise_removal_gpu_mexFunction(noise_removal_gpuStackData *SD,
  int32_T nlhs, mxArray *plhs[1], int32_T nrhs, const mxArray *prhs[1])
{
  const mxArray *outputs[1];

  /* Check for proper number of arguments. */
  if (nrhs != 1) {
    emlrtErrMsgIdAndTxt(emlrtRootTLSGlobal, "EMLRT:runTime:WrongNumberOfInputs",
                        5, 12, 1, 4, 17, "noise_removal_gpu");
  }

  if (nlhs > 1) {
    emlrtErrMsgIdAndTxt(emlrtRootTLSGlobal,
                        "EMLRT:runTime:TooManyOutputArguments", 3, 4, 17,
                        "noise_removal_gpu");
  }

  /* Call the function. */
  noise_removal_gpu_api(SD, prhs, nlhs, outputs);

  /* Copy over outputs to the caller. */
  emlrtReturnArrays(1, plhs, outputs);
}

void mexFunction(int32_T nlhs, mxArray *plhs[], int32_T nrhs, const mxArray
                 *prhs[])
{
  noise_removal_gpuStackData *c_noise_removal_gpuStackDataGlo = NULL;
  c_noise_removal_gpuStackDataGlo = (noise_removal_gpuStackData *)emlrtMxCalloc
    (1, (size_t)1U * sizeof(noise_removal_gpuStackData));
  mexAtExit(noise_removal_gpu_atexit);

  /* Module initialization. */
  noise_removal_gpu_initialize();

  /* Dispatch the entry-point. */
  noise_removal_gpu_mexFunction(c_noise_removal_gpuStackDataGlo, nlhs, plhs,
    nrhs, prhs);

  /* Module termination. */
  noise_removal_gpu_terminate();
  emlrtMxFree(c_noise_removal_gpuStackDataGlo);
}

emlrtCTX mexFunctionCreateRootTLS()
{
  emlrtCreateRootTLS(&emlrtRootTLSGlobal, &emlrtContextGlobal, NULL, 1);
  return emlrtRootTLSGlobal;
}

/* End of code generation (_coder_noise_removal_gpu_mex.cu) */
