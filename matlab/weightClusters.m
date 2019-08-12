centroidMarker = zeros(100,2);

for jj=1:100
    % Get the name of the image the user wants to use.
    folder = '/home/tyson/Documents/MATLAB/temp/deeplabv3_2019-08-10_171747/';
    filename = sprintf('pixelLabel.%04d.png',jj);
    fullFileName = fullfile(folder, filename);

    % [filename, folder] = uigetfile({'*.jpg';'*.bmp'},'Select image');
    chosenLabel = 1;
    grayImage = imread(fullFileName);
    maskedImage = grayImage;
    maskedImage(maskedImage~=chosenLabel) = 0;
    [x_max, y_max] = size(maskedImage);

    subplot(2, 2, 1);
    imshow(maskedImage,[])
    xlim([0 x_max-1])
    ylim([0 y_max-1])
    axis on image;
    title('Binary mask','fontsize',fontSize);
    hold off


    X = zeros(x_max,2);
    index = 1;
    for x=1:x_max
        for y=1:y_max
            if (maskedImage(x,y)==chosenLabel)
                X(index,2) = x;
                X(index,1) = y;
                index = index + 1;
            end
        end
    end

    subplot(2, 2, 2);
    scatter(X(:,1),X(:,2),10,'.')
    axis on image;
    set(gca, 'YDir','reverse')
    xlim([0 255])
    ylim([0 255])
    title('Image as points','fontsize',fontSize);
    hold off

    minpts = min(round(sqrt(x_max)),12);

%     kD = pdist2(X,X,'euc','Smallest',minpts); % The minpts smallest pairwise distances

%     subplot(2, 2, 3);
%     plot(sort(kD(end,:)));
%     title('k-distance graph')
%     xlabel(strcat({'Points sorted with '},string(minpts),'th nearest distances'))
%     ylabel(strcat(string(minpts),'th nearest distances'))
%     grid
%     axis on image;

    epsilon = 128;
    [idx, corepts] = dbscan(X,epsilon,minpts);

    if idx > 0
        % remove outliers
        X(~corepts,:)=[];
        idx(~corepts)=[];

        subplot(2, 2, 3);
        gscatter(X(:,1),X(:,2),idx);
        axis on image;
        set(gca, 'YDir','reverse')
        xlim([0 255])
        ylim([0 255])
        title(strcat({'epsilon = '},string(epsilon),{' and minpts = '},string(minpts)))
        hold off


        % Find Centroids:
        ia = unique(idx);
        numClusters = numel(ia);
        clusters{numClusters}=[];
        clusterCounts(numClusters)=0;
        clusterCentres{numClusters}=[0 0];
        clusterWeights(numClusters)=0;
        weightedCentre = [0 0];
        for ii=1:numClusters
            clusters{ii} = X(idx==ii,:);
            clusterCounts(ii) = size(X(idx==ii,:),1);
            clusterCentres{ii} = mean(clusters{ii});
            clusterWeights(ii) = clusterCounts(ii)/size(X,1);
            weightedCentre =  weightedCentre + (clusterWeights(ii) .* clusterCentres{ii});
        end
        weightedCentre = round(weightedCentre);
        centroidMarker(jj,:) = weightedCentre;

        subplot(2, 2, 4);
        scatter(X(:,1),X(:,2));
        hold on
        scatter(weightedCentre(1),weightedCentre(2),'filled','r');
        axis on image;
        set(gca, 'YDir','reverse')
        xlim([0 255])
        ylim([0 255])
%         title(strcat({'epsilon = '},string(epsilon),{' and minpts = '},string(minpts)))
        hold off


    end

%     % clear reconstructedImage
%     reconstructedImage(ii,jj) = 0;
%     [sz, dim] = size(Y);
%     for index=1:sz
%         x = Y(index,2);
%         y = Y(index,1);
%         reconstructedImage(x,y) = 1;
%     end
%     
%     subplot(2, 2, 4);
%     imshow(reconstructedImage,[])
%     axis on image;
%     title('Reconstructed Image','fontsize',fontSize);
%     
%     assert(max(size(maskedImage)-size(reconstructedImage))==0)
    pause(.25)
end

% offset = 2;
% figure
% for kk=2:size(centroidMarker,1)
%     if (~min(centroidMarker(kk,:)==[0 0]) && ~min(centroidMarker(kk-1,:)==[0 0]))
%         p0 = centroidMarker(kk-1,:);
%         p1 = centroidMarker(kk,:);
%         vectarrow(p0,p1);
%         set(gca, 'YDir','reverse')
%         text(p1(1)+offset,p1(2)+offset,string(kk));
%         hold on
%     end
% end
% scatter(centroidMarker(:,1),centroidMarker(:,2),50)
