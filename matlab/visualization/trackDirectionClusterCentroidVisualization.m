clear all;
clc;
close all;

fontSize = 16;
frameStart = 7;
frameEnd = 43;

%% Main
% scr = get(groot,'ScreenSize');                              % screen resolution
% fig1 =  figure('Position',...                               % draw figure
%     [1 scr(4)*3/5 scr(3)*3/5 scr(4)*3/5]);
fig1 = figure('Position',[27,131,1661,785])
set(fig1,'numbertitle','off',...                            % Give figure useful title
    'name','ELEN3012 Lightning Direction (DBScan clustering)')
set(fig1, 'MenuBar', 'none');                               % Make figure clean
set(fig1, 'ToolBar', 'none');                               %

jj = frameStart;
keepPlaying = true;
% centroidMarker = zeros(frameEnd,2);

while keepPlaying
% for jj=frameStart:frameEnd

    
    % Get the name of the image the user wants to use.
%     folder = '/home/tyson/Documents/MATLAB/temp/deeplabv3_2019-08-10_171747/';
%     folder = '/home/tyson/Documents/MATLAB/temp/deeplabv3_2019-08-09_202933/';
    folder = '~/Desktop/test/output';
    filename = sprintf('pixelLabel.%04d.png',jj);
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

    % show results
    subplot(2, 4, 1);  
    plot_input = imshow(maskedImage,[])
    xlim([0 x_max-1])
    ylim([0 y_max-1])
    axis on image;
    title('Binary mask','fontsize',fontSize);
    hold off

    % convert to points
    clear X;
    pointImage=[];
    index = 1;
    for x=1:x_max
        for y=1:y_max
            if (maskedImage(x,y)==chosenLabel)
                pointImage(index,2) = x;
                pointImage(index,1) = y;
                index = index + 1;
            end
        end
    end

    % plot points
    subplot(2, 4, 2);
    if numel(pointImage)>0
        plot_point = scatter(pointImage(:,1),pointImage(:,2),10,'.');
    else
        cla;
    end
    axis on image;
    set(gca, 'YDir','reverse');
    xlim([0 255]);
    ylim([0 255]);
    title('Image as points','fontsize',fontSize);
    hold off

    % choose minimum cluster size
    minpts = min(round(sqrt(x_max)),4);

%     kD = pdist2(X,X,'euc','Smallest',minpts); % The minpts smallest pairwise distances

%     subplot(3, 3, 3);
%     plot(sort(kD(end,:)));
%     title('k-distance graph')
%     xlabel(strcat({'Points sorted with '},string(minpts),'th nearest distances'))
%     ylabel(strcat(string(minpts),'th nearest distances'))
%     grid
%     axis on image;

    % choose radius about centre
    epsilon = 10;
    if numel(pointImage)>0
        [idx, corepts] = dbscan(pointImage,epsilon,minpts);
    else
        idx = 0;
        corepts = [];
    end
    
    % convert back into pixels
    clear reconstructedImage
    reconstructedImage = zeros(x_max,y_max);
    [sz, dim] = size(pointImage);
    for index=1:sz
        x = pointImage(index,2);
        y = pointImage(index,1);
        reconstructedImage(x,y) = 1;
    end
    
    % if image is non-empty:
    if idx > 0
        % remove outliers
        pointImage(~corepts,:)=[];
        idx(~corepts)=[];

        subplot(2, 4, 5);
        plot_clusters = gscatter(pointImage(:,1),pointImage(:,2),idx);
        axis on image;
        set(gca, 'YDir','reverse')
        xlim([0 255])
        ylim([0 255])
        title(strcat({'epsilon = '},string(epsilon),{' and minpts = '},string(minpts)))
        hold off


        % Find Centroids:
        ia = unique(idx);
        numClusters = numel(ia);
%         clusters{numClusters} = [];
%         clusterCounts(numClusters) = 0;
%         clusterCentres{numClusters} = [x_max/2 y_max/2];
%         clusterWeights(numClusters) = 0;
%         weightedCentre = [0 0];
        for ii=1:numClusters
            clusters{ii} = pointImage(idx==ii,:);
            clusterCounts(ii) = size(pointImage(idx==ii,:),1);
            clusterCentres{ii} = mean(clusters{ii});
            clusterWeights(ii) = clusterCounts(ii)/size(pointImage,1);
        end

        % Weighting for all clusters
%         for ii=1:numClusters
%             weightedCentre =  weightedCentre + (clusterWeights(ii) .* clusterCentres{ii});
%         end
%         weightedCentre = round(weightedCentre);
        
        % Just choose the largest cluster
        [maximum, index] = max(clusterCounts);
        weightedCentre = round(clusterCentres{index});

        centroidMarker(jj,:) = weightedCentre;
        pointImage =  clusters{index};

        subplot(2, 4, 6);
        cla
        plot_reduced = scatter(pointImage(:,1),pointImage(:,2));
        hold on
        plot_centroid = scatter(weightedCentre(1),weightedCentre(2),'filled','r');
        axis on image;
        set(gca, 'YDir','reverse');
        xlim([0 255]);
        ylim([0 255]);
        title(strcat({'Weighted centroid = ['},string(weightedCentre(1)),{' '}, string(weightedCentre(2)),']'))
        hold off
        
        subplot(2, 4, [3, 4, 7, 8] )
%         scatter(centroidMarker(:,1),centroidMarker(:,2),50)
%         hold on
        plot_reconstructed = imshow(1-reconstructedImage,[])
        axis on image;
        title('Reconstructed Image','fontsize',fontSize);
        hold on
        offset = [6 0];
        for kk=2:size(centroidMarker,1)
            if (~min(centroidMarker(kk,:)==[0 0]) && ~min(centroidMarker(kk-1,:)==[0 0]))
                p0 = centroidMarker(kk-1,:);
                p1 = centroidMarker(kk,:);
                vectarrow(p0,p1);
                direction{kk} = p1-p0;
                set(gca, 'YDir','reverse')
                text(p1(1)+offset(1),p1(2)+offset(2),string(kk),...
                    'Color','red','FontSize',10);
                hold on
            end
        end
        
        if exist('direction','var')
            value = [0 0];
            for kk=1:size(direction,2)
                if direction{kk}~=0
                    value = value + direction{kk};
                end
            end
            offset = round([x_max/2,y_max/2]);
            vectarrow([0 0]+offset,value+offset);
            if size(direction,2)>2
                if value(2)<0
                    dir='up';
                elseif value(2)>0
                    dir='down';
                else
                    dir='unknown';
                end
                text(x_max/2,y_max/2,dir,'FontSize',fontSize);
            end
                
            axis on image;
%             set(gca, 'YDir','reverse')
            hold off
        end
        
        hold off
        assert(max(size(maskedImage)-size(reconstructedImage))==0)
        
    else
        subplot(2, 4, 5);
%         cla
        set(gca,'Color',[0.5 0.5 0.5 0.5]);
        for ii=1:numel(plot_clusters)
            plot_clusters(ii).Color = [0.5 0.5 0.5 0.5];
        end
        legend('hide');
        hold off
        subplot(2, 4, 6);
        %         cla
        set(gca,'Color',[0.5 0.5 0.5 0.5]);
        for ii=1:numel(plot_reduced)
            plot_reduced(ii).MarkerFaceColor  = [0.5 0.5 0.5];
            plot_reduced(ii).MarkerEdgeColor  = [0.5 0.5 0.5];
        end
%         for ii=1:numel(plot_centroid)
        plot_centroid.MarkerFaceColor  = [0.18 0.18 0.18];
        hold off
    end
    

    sgtitle(strcat({'Frame: '},string(jj)),...
        'FontSize',16);
    if jj < frameEnd
        jj = jj + 1;
    else
        pause(0.5)
        clf;
        clearvars -except jj frameStart frameEnd keepPlaying fig1 fontSize
        jj = frameStart;
    end
    
%%% Display Plot
    drawnow limitrate;                                      % draw graph
    if ~ishghandle(fig1)                                    % break if figure window closed
        keepPlaying = false;
        break
    end
end


