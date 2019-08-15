%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        DIRECTIONFROMCLUSTERS.m
% This function determines the most likely direction using the largest cluster 
% by determining the progression of the centroid of the cluster over several frames
% INPUT:
%        filePath: The filepath for full events segmented images to use
%        frameStart: The determined start of a lighting event
%        frameLength: The number of frames to consider as part of the classifiable event
% OUTPUT:
%        dirVector: The resultant vector of produced by the movement of the centroids
%        dir: The direction of the resultant vector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [dirVector, dir] = directionFromClusters(filePath, frameStart, frameLength)

%{ 
 % passed into script/function:
 filePath = '/home/tyson/Documents/MATLAB/temp/deeplabv3_2019-08-10_171747/pixelLabel.0001.png';
 frameStart = 1;
 frameLength = 99;
%}

    % script begin
    frameEnd = frameStart+frameLength;
    [folder, basename, ext] = fileparts(filePath);
    basename = strsplit(basename,'.');
    if (numel(basename) > 1)
        paddinglength = length(basename{end});
    else
        paddinglength = 3;
    end
    basename = basename{1};

    % Configuration 
    % ToDo: make arguments to function
    doRecontructImage = true;      % convert pointCloud/plane back into image
    useAllClusters = false;        % if false, use the largest cluster instead

    for jj=frameStart:frameEnd

        % Get the name of the image the user wants to use.
        str = strcat('%s.%0',string(paddinglength),'d%s');
        filename = sprintf(str, basename, jj, ext);
        fullFileName = fullfile(folder, filename);

        % [filename, folder] = uigetfile({'*.jpg';'*.bmp'},'Select image');
        grayImage = imread(fullFileName);

        % choose the lightning label (minus edges of frame)
        chosenLabel = 1;
        maskedImage = grayImage;
        maskedImage(maskedImage~=chosenLabel) = 0;
        maskedImage(maskedImage>0) = 1;
        edgeRemove = 4;
        maskedImage(edgeRemove,:) = 0;
        maskedImage(end-edgeRemove,:) = 0;
        maskedImage(:,edgeRemove) = 0;
        maskedImage(:,end-edgeRemove) = 0;

        % Prepare the ground mask
        groundLabel = 5;
        groundImage = grayImage;
        groundImage(groundImage~=groundLabel) = 0;
        groundImage(groundImage>0) = 1;
        edgeRemoveH = 4;
        edgeRemoveV = 3;
        se = offsetstrel('ball',edgeRemoveH,edgeRemoveV);
        groundImage = imdilate(groundImage,se);
        groundImage(groundImage>0) = 1;
        groundImage=1.0-groundImage;

        % remove the ground from the mask
        maskedImage = immultiply(maskedImage,groundImage);
        assert(min(size(maskedImage)==size(grayImage))==1);
        [x_max, y_max] = size(maskedImage);

        % convert to points
        clear pointCloud;
        pointCloud=[];
        index = 1;
        for x=1:x_max
            for y=1:y_max
                if (maskedImage(x,y)==chosenLabel)
                    pointCloud(index,2) = x;
                    pointCloud(index,1) = y;
                    index = index + 1;
                end
            end
        end

        % choose minimum cluster size
        minpts = min(round(sqrt(x_max)),10);

        % choose radius about centre
        epsilon = 12;
        if numel(pointCloud)>0
            [idx, corepts] = dbscan(pointCloud,epsilon,minpts);
        else
            idx = 0;
            corepts = [];
        end

        % if image is non-empty:
        if idx > 0

            % remove outliers
            pointCloud(~corepts,:)=[];
            idx(~corepts)=[];

            % Find Centroids:
            ia = unique(idx);
            numClusters = numel(ia);
            clusters{numClusters} = [];
            clusterCounts(numClusters) = 0;
            % clusterCentres{numClusters} = [x_max/2 y_max/2];
            clusterWeights(numClusters) = 0;
            for ii=1:numClusters
                clusters{ii} = pointCloud(idx==ii,:);
                clusterCounts(ii) = size(pointCloud(idx==ii,:),1);
                clusterCentres{ii} = mean(clusters{ii});
                clusterWeights(ii) = clusterCounts(ii)/size(pointCloud,1);
            end

            weightedCentre = [0 0];
            if useAllClusters
                % Weighting for all clusters
                for ii=1:numClusters
                    weightedCentre =  weightedCentre + ...
                        (clusterWeights(ii) .* clusterCentres{ii});
                end
                weightedCentre = round(weightedCentre);
            else
                % Just choose the largest cluster
                [maximum, index] = max(clusterCounts);
                weightedCentre = round(clusterCentres{index});
            end

            centroidMarker(jj,:) = weightedCentre;

            pointCloud =  clusters{index};

            % Calculate change in direction of centroids
            offset = 8;
            for kk=2:size(centroidMarker,1)
                if (~min(centroidMarker(kk,:)==[0 0]) && ...
                    ~min(centroidMarker(kk-1,:)==[0 0]))
                    p0 = centroidMarker(kk-1,:);
                    p1 = centroidMarker(kk,:);
                    direction{kk} = p1-p0;
                end
            end

            % calculate direction as summed vector
            if exist('direction','var')
                dirVector = [0 0];
                for kk=1:size(direction,2)
                    if direction{kk}~=0
                        dirVector = dirVector + direction{kk};
                    end
                end

                if size(direction,2)>2
                    if dirVector(2)<0
                        dir='up';
                    elseif dirVector(2)>0
                        dir='down';
                    else
                        dir='unknown';
                    end
                end 
            end
        end  % end of cluster centroid calculations

        if doRecontructImage
            % convert back into pixels
            clear reconstructedImage
            reconstructedImage = zeros(x_max,y_max);
            [sz, dim] = size(pointCloud);
            for index=1:sz
                x = pointCloud(index,2);
                y = pointCloud(index,1);
                reconstructedImage(x,y) = 1;
            end
            assert(max(size(maskedImage)-size(reconstructedImage))==0)
            
        end
    end
% disp(dir)
end

