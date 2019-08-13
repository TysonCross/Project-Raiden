[Im16,info] = read(imds);
[~, filename, ext] = fileparts(info.Filename);
inputImage = imread(fullfile(destinationPath,strcat(filename,ext)));
noisyRGB = imnoise(Im16,'salt & pepper', 0.05);
cfg1 = coder.gpuConfig('mex');
codegen -args {noisyRGB} -config cfg1 noise_removal_gpu -o noise_removal_gpu_mex
