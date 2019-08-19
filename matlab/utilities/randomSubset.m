function [imds, pxds] = randomSubset(imds_full, pxds_full, percentage)
% Reduce the data to a randomised subset by percentage

  % create subsets for important/rare labels
  loadLabels;
  numFiles = numel(imds_full.Files);
  strokeSetIndx = [];
  leaderSetIndx = [];
  otherSetIndx = [];
  parfor ii=1:numFiles
    im = imds_full.readimage(ii);
    if ismember(double(Label.stroke), im)
        strokeSetIndx = [strokeSetIndx ii];
    elseif ismember(double(Label.leader), im)
        leaderSetIndx = [leaderSetIndx ii];
    else
        otherSetIndx = [otherSetIndx ii];
    end
  end
  reset(imds_full);

  % Set initial random state
  rng(now);
  leaderSetIndx = leaderSetIndx(randperm(length(leaderSetIndx)));
  otherSetIndx = otherSetIndx(randperm(length(otherSetIndx)));

  % Use the same percentage of each subset of non-stroke images
  N_leader = round(percentage * length(leaderSetIndx));
  N_other = round(percentage * length(otherSetIndx));
  leaderSetIndx = leaderSetIndx(1:N_leader);
  otherSetIndx = otherSetIndx(1:N_other);
  idx = cat(1,strokeSetIndx(:),leaderSetIndx(:),otherSetIndx(:));
  idx = sort(idx);

  % Create image datastores from subsets
  imageFileSubSet = imds_full.Files(idx);
  imds = imageDatastore(imageFileSubSet);

  % Create pixel label datastores from subset
  labelFileSubSet = pxds_full.Files(idx);
  pxds = pixelLabelDatastore(labelFileSubSet, labelNames, ...
    labelIDs_scalar); % alternative: labelIDs

end
