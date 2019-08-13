/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_noise_removal_gpu_api.cu
 *
 * Code generation for function '_coder_noise_removal_gpu_api'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "noise_removal_gpu.h"
#include "_coder_noise_removal_gpu_api.h"
#include "noise_removal_gpu_data.h"

/* Variable Definitions */
static const int32_T iv0[3] = { 256, 512, 3 };

/* Function Declarations */
static uint16_T (*b_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier *
  parentId))[393216];
static uint16_T (*c_emlrt_marshallIn(const mxArray *src, const
  emlrtMsgIdentifier *msgId))[393216];
static uint16_T (*emlrt_marshallIn(const mxArray *noisyRGB, const char_T
  *identifier))[393216];
static const mxArray *emlrt_marshallOut(const uint16_T u[393216]);

/* Function Definitions */
static uint16_T (*b_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier *
  parentId))[393216]
{
  uint16_T (*y)[393216];
  y = c_emlrt_marshallIn(emlrtAlias(u), parentId);
  emlrtDestroyArray(&u);
  return y;
}
  static uint16_T (*c_emlrt_marshallIn(const mxArray *src, const
  emlrtMsgIdentifier *msgId))[393216]
{
  uint16_T (*ret)[393216];
  emlrtCheckBuiltInR2012b(emlrtRootTLSGlobal, (const emlrtMsgIdentifier *)msgId,
    src, "uint16", false, 3U, *(int32_T (*)[3])&iv0[0]);
  ret = (uint16_T (*)[393216])emlrtMxGetData(src);
  emlrtDestroyArray(&src);
  return ret;
}

static uint16_T (*emlrt_marshallIn(const mxArray *noisyRGB, const char_T
  *identifier))[393216]
{
  uint16_T (*y)[393216];
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = const_cast<const char *>(identifier);
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y = b_emlrt_marshallIn(emlrtAlias(noisyRGB), &thisId);
  emlrtDestroyArray(&noisyRGB);
  return y;
}
  static const mxArray *emlrt_marshallOut(const uint16_T u[393216])
{
  const mxArray *y;
  const mxArray *m0;
  static const int32_T iv2[3] = { 0, 0, 0 };

  y = NULL;
  m0 = emlrtCreateNumericArray(3, iv2, mxUINT16_CLASS, mxREAL);
  emlrtMxSetData((mxArray *)m0, (void *)&u[0]);
  emlrtSetDimensions((mxArray *)m0, *(int32_T (*)[3])&iv0[0], 3);
  emlrtAssign(&y, m0);
  return y;
}

void noise_removal_gpu_api(noise_removal_gpuStackData *SD, const mxArray * const
  prhs[1], int32_T, const mxArray *plhs[1])
{
  uint16_T (*rgbFixed)[393216];
  uint16_T (*noisyRGB)[393216];
  rgbFixed = (uint16_T (*)[393216])mxMalloc(sizeof(uint16_T [393216]));

  /* Marshall function inputs */
  noisyRGB = emlrt_marshallIn(emlrtAlias(prhs[0]), "noisyRGB");

  /* Invoke the target function */
  noise_removal_gpu(SD, *noisyRGB, *rgbFixed);

  /* Marshall function outputs */
  plhs[0] = emlrt_marshallOut(*rgbFixed);
}

/* End of code generation (_coder_noise_removal_gpu_api.cu) */
