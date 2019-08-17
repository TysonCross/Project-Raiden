function [imds, pxds] = randomSubset(imds_full, pxds_full, percentage)
% Reduce the data to a randomised subset by percentage

  % Set initial random state
  rng(now);
  numFiles = numel(imds_full.Files);
  shuffledIndices = randperm(numFiles);

  % Use a percentage% of the images
  N = round(percentage * numFiles);
  idx = shuffledIndices(1:N);

  % Create image datastore from subset
  imageFileSubSet = imds_full.Files(idx);
  imds = imageDatastore(imageFileSubSet,'FileExtensions','.tif');

  % Create pixel label datastores from subset
  loadLabels;
  labelFileSubSet = pxds_full.Files(idx);
  % pxds = pixelLabelDatastore(labelFileSubSet, labelNames, ...
    labelIDs,'FileExtensions','.tif');
  pxds = pixelLabelDatastore(labelFileSubSet, labelNames, ...
    labelIDs_scalar,'FileExtensions','.tif');

end
