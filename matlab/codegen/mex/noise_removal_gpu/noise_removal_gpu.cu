/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * noise_removal_gpu.cu
 *
 * Code generation for function 'noise_removal_gpu'
 *
 */

/* Include files */
#include "MWCudaDimUtility.h"
#include "rt_nonfinite.h"
#include "noise_removal_gpu.h"

/* Function Declarations */
static __global__ void noise_removal_gpu_kernel1(const uint16_T noisyRGB[393216],
  uint16_T inpImg_padded[131072]);
static __global__ void noise_removal_gpu_kernel10(uint16_T inpImg_padded[131841]);
static __global__ void noise_removal_gpu_kernel11(uint16_T inpImg_padded[131072],
  uint16_T b_inpImg_padded[131841]);
static __global__ void noise_removal_gpu_kernel12(uint16_T inpImg_padded[131841],
  uint16_T b_inpImg_padded[131072]);
static __global__ void noise_removal_gpu_kernel13(uint16_T inpImg_padded[131072],
  int32_T initAuxVar, uint16_T rgbFixed[393216]);
static __global__ void noise_removal_gpu_kernel2(uint16_T inpImg_padded[131841]);
static __global__ void noise_removal_gpu_kernel3(uint16_T inpImg_padded[131072],
  uint16_T b_inpImg_padded[131841]);
static __global__ void noise_removal_gpu_kernel4(uint16_T inpImg_padded[131841],
  uint16_T outImg[131072]);
static __global__ void noise_removal_gpu_kernel5(const uint16_T noisyRGB[393216],
  uint16_T inpImg_padded[131072]);
static __global__ void noise_removal_gpu_kernel6(uint16_T inpImg_padded[131841]);
static __global__ void noise_removal_gpu_kernel7(uint16_T inpImg_padded[131072],
  uint16_T b_inpImg_padded[131841]);
static __global__ void noise_removal_gpu_kernel8(uint16_T inpImg_padded[131841],
  uint16_T outImg[131072]);
static __global__ void noise_removal_gpu_kernel9(const uint16_T noisyRGB[393216],
  uint16_T inpImg_padded[131072]);

/* Function Definitions */
static __global__ __launch_bounds__(512, 1) void noise_removal_gpu_kernel1(const
  uint16_T noisyRGB[393216], uint16_T inpImg_padded[131072])
{
  uint32_T threadId;
  int32_T minIdx;
  int32_T maxIdx;
  threadId = static_cast<uint32_T>(mwGetGlobalThreadIndex());
  minIdx = static_cast<int32_T>((threadId % 256U));
  maxIdx = static_cast<int32_T>(((threadId - static_cast<uint32_T>(minIdx)) /
    256U));
  if (maxIdx < 512) {
    inpImg_padded[minIdx + (maxIdx << 8)] = noisyRGB[minIdx + (maxIdx << 8)];
  }
}

static __global__ __launch_bounds__(288, 1) void noise_removal_gpu_kernel10
  (uint16_T inpImg_padded[131841])
{
  uint32_T threadId;
  int32_T minIdx;
  threadId = static_cast<uint32_T>(mwGetGlobalThreadIndex());
  minIdx = static_cast<int32_T>(threadId);
  if (minIdx < 257) {
    inpImg_padded[131584 + minIdx] = static_cast<uint16_T>(0U);
  }
}

static __global__ __launch_bounds__(512, 1) void noise_removal_gpu_kernel11
  (uint16_T inpImg_padded[131072], uint16_T b_inpImg_padded[131841])
{
  uint32_T threadId;
  int32_T maxIdx;
  int32_T minIdx;
  threadId = static_cast<uint32_T>(mwGetGlobalThreadIndex());
  maxIdx = static_cast<int32_T>(threadId);
  if (maxIdx < 512) {
    b_inpImg_padded[256 + 257 * maxIdx] = static_cast<uint16_T>(0U);
    for (minIdx = 0; minIdx < 256; minIdx++) {
      b_inpImg_padded[minIdx + 257 * maxIdx] = inpImg_padded[minIdx + (maxIdx <<
        8)];
    }
  }
}

static __global__ __launch_bounds__(1024, 1) void noise_removal_gpu_kernel12
  (uint16_T inpImg_padded[131841], uint16_T b_inpImg_padded[131072])
{
  int32_T maxIdx;
  int32_T iter;
  int32_T i0;
  real_T val;
  uint16_T newIm[4];
  int32_T startIdx;
  int32_T orow;
  int32_T ocol;
  uint16_T t;
  int32_T minIdx;
  int32_T b_iter;
  int32_T c_iter;
  __shared__ uint16_T inpImg_padded_shared[1089];
  int32_T baseR;
  int32_T srow;
  int32_T strideRow;
  int32_T scol;
  int32_T strideCol;
  int32_T y_idx;
  int32_T baseC;
  int32_T x_idx;
  ocol = mwGetGlobalThreadIndexInYDimension();
  orow = mwGetGlobalThreadIndexInXDimension();
  baseR = orow;
  srow = static_cast<int32_T>(threadIdx.x);
  strideRow = static_cast<int32_T>(blockDim.x);
  scol = static_cast<int32_T>(threadIdx.y);
  strideCol = static_cast<int32_T>(blockDim.y);
  for (y_idx = srow; y_idx <= 32; y_idx += strideRow) {
    baseC = ocol;
    for (x_idx = scol; x_idx <= 32; x_idx += strideCol) {
      if ((static_cast<int32_T>(((static_cast<int32_T>((baseR >= 0))) &&
             (static_cast<int32_T>((baseR < 257)))))) && (static_cast<int32_T>
           (((static_cast<int32_T>((baseC >= 0))) && (static_cast<int32_T>
              ((baseC < 513))))))) {
        inpImg_padded_shared[y_idx + 33 * x_idx] = inpImg_padded[257 * baseC +
          baseR];
      } else {
        inpImg_padded_shared[y_idx + 33 * x_idx] = static_cast<uint16_T>(0U);
      }

      baseC += strideCol;
    }

    baseR += strideRow;
  }

  __syncthreads();
  if ((static_cast<int32_T>((ocol < 512))) && (static_cast<int32_T>((orow < 256))))
  {
    for (maxIdx = 0; maxIdx < 2; maxIdx++) {
      for (i0 = 0; i0 < 2; i0++) {
        newIm[i0 + (maxIdx << 1)] = inpImg_padded_shared[(static_cast<int32_T>
          (threadIdx.x) + i0) + 33 * (static_cast<int32_T>(threadIdx.y) + maxIdx)];
      }
    }

    for (iter = 0; iter < 2; iter++) {
      startIdx = 1 + iter;
      minIdx = startIdx;
      t = newIm[startIdx - 1];
      i0 = 4 - (iter + startIdx);
      for (b_iter = 0; b_iter < i0; b_iter++) {
        c_iter = static_cast<int32_T>(((static_cast<uint32_T>(startIdx) +
          static_cast<uint32_T>(b_iter)) + 1U));
        if (static_cast<int32_T>(newIm[c_iter - 1]) < static_cast<int32_T>(t)) {
          t = newIm[c_iter - 1];
          minIdx = c_iter;
        }
      }

      t = newIm[minIdx - 1];
      newIm[minIdx - 1] = newIm[iter];
      newIm[iter] = t;
      maxIdx = startIdx;
      t = newIm[startIdx - 1];
      i0 = 4 - (iter + startIdx);
      for (b_iter = 0; b_iter < i0; b_iter++) {
        c_iter = static_cast<int32_T>(((static_cast<uint32_T>(startIdx) +
          static_cast<uint32_T>(b_iter)) + 1U));
        if (static_cast<int32_T>(newIm[c_iter - 1]) > static_cast<int32_T>(t)) {
          t = newIm[c_iter - 1];
          maxIdx = c_iter;
        }
      }

      t = newIm[maxIdx - 1];
      newIm[maxIdx - 1] = newIm[3 - iter];
      newIm[3 - iter] = t;
    }

    val = 0.5 * static_cast<real_T>(newIm[1]) + 0.5 * static_cast<real_T>(newIm
      [2]);
    if (val > 0.0) {
      b_inpImg_padded[orow + (ocol << 8)] = static_cast<uint16_T>((val + 0.5));
    } else {
      b_inpImg_padded[orow + (ocol << 8)] = static_cast<uint16_T>(0U);
    }
  }
}

static __global__ __launch_bounds__(512, 1) void noise_removal_gpu_kernel13
  (uint16_T inpImg_padded[131072], int32_T initAuxVar, uint16_T rgbFixed[393216])
{
  uint32_T threadId;
  int32_T j;
  threadId = static_cast<uint32_T>(mwGetGlobalThreadIndex());
  j = static_cast<int32_T>(threadId);
  if (j < 131072) {
    rgbFixed[(initAuxVar + j) + 1] = inpImg_padded[j];
  }
}

static __global__ __launch_bounds__(288, 1) void noise_removal_gpu_kernel2
  (uint16_T inpImg_padded[131841])
{
  uint32_T threadId;
  int32_T minIdx;
  threadId = static_cast<uint32_T>(mwGetGlobalThreadIndex());
  minIdx = static_cast<int32_T>(threadId);
  if (minIdx < 257) {
    inpImg_padded[131584 + minIdx] = static_cast<uint16_T>(0U);
  }
}

static __global__ __launch_bounds__(512, 1) void noise_removal_gpu_kernel3
  (uint16_T inpImg_padded[131072], uint16_T b_inpImg_padded[131841])
{
  uint32_T threadId;
  int32_T maxIdx;
  int32_T minIdx;
  threadId = static_cast<uint32_T>(mwGetGlobalThreadIndex());
  maxIdx = static_cast<int32_T>(threadId);
  if (maxIdx < 512) {
    b_inpImg_padded[256 + 257 * maxIdx] = static_cast<uint16_T>(0U);
    for (minIdx = 0; minIdx < 256; minIdx++) {
      b_inpImg_padded[minIdx + 257 * maxIdx] = inpImg_padded[minIdx + (maxIdx <<
        8)];
    }
  }
}

static __global__ __launch_bounds__(1024, 1) void noise_removal_gpu_kernel4
  (uint16_T inpImg_padded[131841], uint16_T outImg[131072])
{
  int32_T maxIdx;
  int32_T iter;
  int32_T i0;
  real_T val;
  uint16_T newIm[4];
  int32_T startIdx;
  int32_T orow;
  int32_T ocol;
  uint16_T t;
  int32_T minIdx;
  int32_T b_iter;
  int32_T c_iter;
  __shared__ uint16_T inpImg_padded_shared[1089];
  int32_T baseR;
  int32_T srow;
  int32_T strideRow;
  int32_T scol;
  int32_T strideCol;
  int32_T y_idx;
  int32_T baseC;
  int32_T x_idx;
  ocol = mwGetGlobalThreadIndexInYDimension();
  orow = mwGetGlobalThreadIndexInXDimension();
  baseR = orow;
  srow = static_cast<int32_T>(threadIdx.x);
  strideRow = static_cast<int32_T>(blockDim.x);
  scol = static_cast<int32_T>(threadIdx.y);
  strideCol = static_cast<int32_T>(blockDim.y);
  for (y_idx = srow; y_idx <= 32; y_idx += strideRow) {
    baseC = ocol;
    for (x_idx = scol; x_idx <= 32; x_idx += strideCol) {
      if ((static_cast<int32_T>(((static_cast<int32_T>((baseR >= 0))) &&
             (static_cast<int32_T>((baseR < 257)))))) && (static_cast<int32_T>
           (((static_cast<int32_T>((baseC >= 0))) && (static_cast<int32_T>
              ((baseC < 513))))))) {
        inpImg_padded_shared[y_idx + 33 * x_idx] = inpImg_padded[257 * baseC +
          baseR];
      } else {
        inpImg_padded_shared[y_idx + 33 * x_idx] = static_cast<uint16_T>(0U);
      }

      baseC += strideCol;
    }

    baseR += strideRow;
  }

  __syncthreads();
  if ((static_cast<int32_T>((ocol < 512))) && (static_cast<int32_T>((orow < 256))))
  {
    for (maxIdx = 0; maxIdx < 2; maxIdx++) {
      for (i0 = 0; i0 < 2; i0++) {
        newIm[i0 + (maxIdx << 1)] = inpImg_padded_shared[(static_cast<int32_T>
          (threadIdx.x) + i0) + 33 * (static_cast<int32_T>(threadIdx.y) + maxIdx)];
      }
    }

    for (iter = 0; iter < 2; iter++) {
      startIdx = 1 + iter;
      minIdx = startIdx;
      t = newIm[startIdx - 1];
      i0 = 4 - (iter + startIdx);
      for (b_iter = 0; b_iter < i0; b_iter++) {
        c_iter = static_cast<int32_T>(((static_cast<uint32_T>(startIdx) +
          static_cast<uint32_T>(b_iter)) + 1U));
        if (static_cast<int32_T>(newIm[c_iter - 1]) < static_cast<int32_T>(t)) {
          t = newIm[c_iter - 1];
          minIdx = c_iter;
        }
      }

      t = newIm[minIdx - 1];
      newIm[minIdx - 1] = newIm[iter];
      newIm[iter] = t;
      maxIdx = startIdx;
      t = newIm[startIdx - 1];
      i0 = 4 - (iter + startIdx);
      for (b_iter = 0; b_iter < i0; b_iter++) {
        c_iter = static_cast<int32_T>(((static_cast<uint32_T>(startIdx) +
          static_cast<uint32_T>(b_iter)) + 1U));
        if (static_cast<int32_T>(newIm[c_iter - 1]) > static_cast<int32_T>(t)) {
          t = newIm[c_iter - 1];
          maxIdx = c_iter;
        }
      }

      t = newIm[maxIdx - 1];
      newIm[maxIdx - 1] = newIm[3 - iter];
      newIm[3 - iter] = t;
    }

    val = 0.5 * static_cast<real_T>(newIm[1]) + 0.5 * static_cast<real_T>(newIm
      [2]);
    if (val > 0.0) {
      outImg[orow + (ocol << 8)] = static_cast<uint16_T>((val + 0.5));
    } else {
      outImg[orow + (ocol << 8)] = static_cast<uint16_T>(0U);
    }
  }
}

static __global__ __launch_bounds__(512, 1) void noise_removal_gpu_kernel5(const
  uint16_T noisyRGB[393216], uint16_T inpImg_padded[131072])
{
  uint32_T threadId;
  int32_T minIdx;
  int32_T maxIdx;
  threadId = static_cast<uint32_T>(mwGetGlobalThreadIndex());
  minIdx = static_cast<int32_T>((threadId % 256U));
  maxIdx = static_cast<int32_T>(((threadId - static_cast<uint32_T>(minIdx)) /
    256U));
  if (maxIdx < 512) {
    inpImg_padded[minIdx + (maxIdx << 8)] = noisyRGB[131072 + (minIdx + (maxIdx <<
      8))];
  }
}

static __global__ __launch_bounds__(288, 1) void noise_removal_gpu_kernel6
  (uint16_T inpImg_padded[131841])
{
  uint32_T threadId;
  int32_T minIdx;
  threadId = static_cast<uint32_T>(mwGetGlobalThreadIndex());
  minIdx = static_cast<int32_T>(threadId);
  if (minIdx < 257) {
    inpImg_padded[131584 + minIdx] = static_cast<uint16_T>(0U);
  }
}

static __global__ __launch_bounds__(512, 1) void noise_removal_gpu_kernel7
  (uint16_T inpImg_padded[131072], uint16_T b_inpImg_padded[131841])
{
  uint32_T threadId;
  int32_T maxIdx;
  int32_T minIdx;
  threadId = static_cast<uint32_T>(mwGetGlobalThreadIndex());
  maxIdx = static_cast<int32_T>(threadId);
  if (maxIdx < 512) {
    b_inpImg_padded[256 + 257 * maxIdx] = static_cast<uint16_T>(0U);
    for (minIdx = 0; minIdx < 256; minIdx++) {
      b_inpImg_padded[minIdx + 257 * maxIdx] = inpImg_padded[minIdx + (maxIdx <<
        8)];
    }
  }
}

static __global__ __launch_bounds__(1024, 1) void noise_removal_gpu_kernel8
  (uint16_T inpImg_padded[131841], uint16_T outImg[131072])
{
  int32_T maxIdx;
  int32_T iter;
  int32_T i0;
  real_T val;
  uint16_T newIm[4];
  int32_T startIdx;
  int32_T orow;
  int32_T ocol;
  uint16_T t;
  int32_T minIdx;
  int32_T b_iter;
  int32_T c_iter;
  __shared__ uint16_T inpImg_padded_shared[1089];
  int32_T baseR;
  int32_T srow;
  int32_T strideRow;
  int32_T scol;
  int32_T strideCol;
  int32_T y_idx;
  int32_T baseC;
  int32_T x_idx;
  ocol = mwGetGlobalThreadIndexInYDimension();
  orow = mwGetGlobalThreadIndexInXDimension();
  baseR = orow;
  srow = static_cast<int32_T>(threadIdx.x);
  strideRow = static_cast<int32_T>(blockDim.x);
  scol = static_cast<int32_T>(threadIdx.y);
  strideCol = static_cast<int32_T>(blockDim.y);
  for (y_idx = srow; y_idx <= 32; y_idx += strideRow) {
    baseC = ocol;
    for (x_idx = scol; x_idx <= 32; x_idx += strideCol) {
      if ((static_cast<int32_T>(((static_cast<int32_T>((baseR >= 0))) &&
             (static_cast<int32_T>((baseR < 257)))))) && (static_cast<int32_T>
           (((static_cast<int32_T>((baseC >= 0))) && (static_cast<int32_T>
              ((baseC < 513))))))) {
        inpImg_padded_shared[y_idx + 33 * x_idx] = inpImg_padded[257 * baseC +
          baseR];
      } else {
        inpImg_padded_shared[y_idx + 33 * x_idx] = static_cast<uint16_T>(0U);
      }

      baseC += strideCol;
    }

    baseR += strideRow;
  }

  __syncthreads();
  if ((static_cast<int32_T>((ocol < 512))) && (static_cast<int32_T>((orow < 256))))
  {
    for (maxIdx = 0; maxIdx < 2; maxIdx++) {
      for (i0 = 0; i0 < 2; i0++) {
        newIm[i0 + (maxIdx << 1)] = inpImg_padded_shared[(static_cast<int32_T>
          (threadIdx.x) + i0) + 33 * (static_cast<int32_T>(threadIdx.y) + maxIdx)];
      }
    }

    for (iter = 0; iter < 2; iter++) {
      startIdx = 1 + iter;
      minIdx = startIdx;
      t = newIm[startIdx - 1];
      i0 = 4 - (iter + startIdx);
      for (b_iter = 0; b_iter < i0; b_iter++) {
        c_iter = static_cast<int32_T>(((static_cast<uint32_T>(startIdx) +
          static_cast<uint32_T>(b_iter)) + 1U));
        if (static_cast<int32_T>(newIm[c_iter - 1]) < static_cast<int32_T>(t)) {
          t = newIm[c_iter - 1];
          minIdx = c_iter;
        }
      }

      t = newIm[minIdx - 1];
      newIm[minIdx - 1] = newIm[iter];
      newIm[iter] = t;
      maxIdx = startIdx;
      t = newIm[startIdx - 1];
      i0 = 4 - (iter + startIdx);
      for (b_iter = 0; b_iter < i0; b_iter++) {
        c_iter = static_cast<int32_T>(((static_cast<uint32_T>(startIdx) +
          static_cast<uint32_T>(b_iter)) + 1U));
        if (static_cast<int32_T>(newIm[c_iter - 1]) > static_cast<int32_T>(t)) {
          t = newIm[c_iter - 1];
          maxIdx = c_iter;
        }
      }

      t = newIm[maxIdx - 1];
      newIm[maxIdx - 1] = newIm[3 - iter];
      newIm[3 - iter] = t;
    }

    val = 0.5 * static_cast<real_T>(newIm[1]) + 0.5 * static_cast<real_T>(newIm
      [2]);
    if (val > 0.0) {
      outImg[orow + (ocol << 8)] = static_cast<uint16_T>((val + 0.5));
    } else {
      outImg[orow + (ocol << 8)] = static_cast<uint16_T>(0U);
    }
  }
}

static __global__ __launch_bounds__(512, 1) void noise_removal_gpu_kernel9(const
  uint16_T noisyRGB[393216], uint16_T inpImg_padded[131072])
{
  uint32_T threadId;
  int32_T minIdx;
  int32_T maxIdx;
  threadId = static_cast<uint32_T>(mwGetGlobalThreadIndex());
  minIdx = static_cast<int32_T>((threadId % 256U));
  maxIdx = static_cast<int32_T>(((threadId - static_cast<uint32_T>(minIdx)) /
    256U));
  if (maxIdx < 512) {
    inpImg_padded[minIdx + (maxIdx << 8)] = noisyRGB[262144 + (minIdx + (maxIdx <<
      8))];
  }
}

void noise_removal_gpu(noise_removal_gpuStackData *SD, const uint16_T noisyRGB
  [393216], uint16_T rgbFixed[393216])
{
  int32_T iy;
  int32_T j;
  int32_T initAuxVar;
  uint16_T (*gpu_noisyRGB)[393216];
  uint16_T (*gpu_inpImg_padded)[131072];
  uint16_T (*b_gpu_inpImg_padded)[131841];
  uint16_T (*gpu_outImg)[131072];
  uint16_T (*b_gpu_outImg)[131072];
  uint16_T (*gpu_rgbFixed)[393216];
  boolean_T outImg_dirtyOnGpu;
  boolean_T b_outImg_dirtyOnGpu;
  boolean_T rgbFixed_dirtyOnCpu;
  cudaMalloc(&b_gpu_outImg, 262144UL);
  cudaMalloc(&gpu_rgbFixed, 786432UL);
  cudaMalloc(&gpu_outImg, 262144UL);
  cudaMalloc(&b_gpu_inpImg_padded, 263682UL);
  cudaMalloc(&gpu_inpImg_padded, 262144UL);
  cudaMalloc(&gpu_noisyRGB, 786432UL);
  rgbFixed_dirtyOnCpu = false;

  /*  Extract the individual red, green, and blue color channels. */
  /*  Median Filter the channels */
  cudaMemcpy(gpu_noisyRGB, (void *)&noisyRGB[0], 786432UL,
             cudaMemcpyHostToDevice);
  noise_removal_gpu_kernel1<<<dim3(256U, 1U, 1U), dim3(512U, 1U, 1U)>>>
    (*gpu_noisyRGB, *gpu_inpImg_padded);
  noise_removal_gpu_kernel2<<<dim3(1U, 1U, 1U), dim3(288U, 1U, 1U)>>>
    (*b_gpu_inpImg_padded);
  noise_removal_gpu_kernel3<<<dim3(1U, 1U, 1U), dim3(512U, 1U, 1U)>>>
    (*gpu_inpImg_padded, *b_gpu_inpImg_padded);
  noise_removal_gpu_kernel4<<<dim3(8U, 16U, 1U), dim3(32U, 32U, 1U)>>>
    (*b_gpu_inpImg_padded, *gpu_outImg);
  outImg_dirtyOnGpu = true;
  noise_removal_gpu_kernel5<<<dim3(256U, 1U, 1U), dim3(512U, 1U, 1U)>>>
    (*gpu_noisyRGB, *gpu_inpImg_padded);
  noise_removal_gpu_kernel6<<<dim3(1U, 1U, 1U), dim3(288U, 1U, 1U)>>>
    (*b_gpu_inpImg_padded);
  noise_removal_gpu_kernel7<<<dim3(1U, 1U, 1U), dim3(512U, 1U, 1U)>>>
    (*gpu_inpImg_padded, *b_gpu_inpImg_padded);
  noise_removal_gpu_kernel8<<<dim3(8U, 16U, 1U), dim3(32U, 32U, 1U)>>>
    (*b_gpu_inpImg_padded, *b_gpu_outImg);
  b_outImg_dirtyOnGpu = true;
  noise_removal_gpu_kernel9<<<dim3(256U, 1U, 1U), dim3(512U, 1U, 1U)>>>
    (*gpu_noisyRGB, *gpu_inpImg_padded);
  noise_removal_gpu_kernel10<<<dim3(1U, 1U, 1U), dim3(288U, 1U, 1U)>>>
    (*b_gpu_inpImg_padded);
  noise_removal_gpu_kernel11<<<dim3(1U, 1U, 1U), dim3(512U, 1U, 1U)>>>
    (*gpu_inpImg_padded, *b_gpu_inpImg_padded);
  noise_removal_gpu_kernel12<<<dim3(8U, 16U, 1U), dim3(32U, 32U, 1U)>>>
    (*b_gpu_inpImg_padded, *gpu_inpImg_padded);

  /*  Reconstruct the noise free RGB image */
  iy = -1;
  for (j = 0; j < 131072; j++) {
    iy = j;
    if (outImg_dirtyOnGpu) {
      cudaMemcpy(&SD->f0.outImg[0], gpu_outImg, 262144UL, cudaMemcpyDeviceToHost);
      outImg_dirtyOnGpu = false;
    }

    rgbFixed[j] = SD->f0.outImg[j];
    rgbFixed_dirtyOnCpu = true;
  }

  initAuxVar = iy;
  for (j = 0; j < 131072; j++) {
    iy = (initAuxVar + j) + 1;
    if (b_outImg_dirtyOnGpu) {
      cudaMemcpy(&SD->f0.b_outImg[0], b_gpu_outImg, 262144UL,
                 cudaMemcpyDeviceToHost);
      b_outImg_dirtyOnGpu = false;
    }

    rgbFixed[iy] = SD->f0.b_outImg[j];
    rgbFixed_dirtyOnCpu = true;
  }

  if (rgbFixed_dirtyOnCpu) {
    cudaMemcpy(gpu_rgbFixed, &rgbFixed[0], 786432UL, cudaMemcpyHostToDevice);
  }

  noise_removal_gpu_kernel13<<<dim3(256U, 1U, 1U), dim3(512U, 1U, 1U)>>>
    (*gpu_inpImg_padded, iy, *gpu_rgbFixed);
  cudaMemcpy(&rgbFixed[0], gpu_rgbFixed, 786432UL, cudaMemcpyDeviceToHost);
  cudaFree(*gpu_noisyRGB);
  cudaFree(*gpu_inpImg_padded);
  cudaFree(*b_gpu_inpImg_padded);
  cudaFree(*gpu_outImg);
  cudaFree(*gpu_rgbFixed);
  cudaFree(*b_gpu_outImg);
}

/* End of code generation (noise_removal_gpu.cu) */
