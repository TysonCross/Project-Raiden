%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%          TRACKDIRECTIONCLUSTERCENTROIDVISUALIZATION.M
% Given the output of the semantic segmentation this script produces and
% tracks a centroid of the largest cluster of pixels. The centroids
% movement is tracked across the frames and this process is plotted.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all;
clc;
close all;

fontSize = 14;
% frameStart = 3;
% frameEnd = 38;
frameStart = 29;
frameEnd = 33;

origOffset = 3466;

%% Main
scr = get(groot,'ScreenSize');                              % screen resolution
% left bottom width height
h = scr(4)*0.8;
w = h * 1.78;
l = scr(3)/2 - w/2;
b = scr(4) - h/2;

pos = [l b w h];
fig1 =  figure('Position', pos);                               % draw figure
%     [scr(1)/2 scr(4)*1.78 scr(3)*1.78 scr(4)*1.78]);
% fig1 = figure('Position',[27,131,1661,785]);
set(fig1,'numbertitle','off',...                            % Give figure useful title
    'name','ELEN3012 Lightning Direction (DBScan clustering)')
set(fig1, 'MenuBar', 'none');                               % Make figure clean
set(fig1, 'ToolBar', 'none');                               %
set(fig1,'color','w');
set(fig1,'defaultAxesFontName', 'Roboto');                     % Make fonts pretty
set(fig1,'defaultTextFontName', 'Roboto');                     % CMU Serif
set(fig1, 'MenuBar', 'figure');
set(fig1, 'ToolBar', 'figure');

jj = frameStart;
keepPlaying = true;

while keepPlaying
    Tmain = text(0.5,-0.1,strcat({'Frame: '},string(jj)),'FontSize',20,'HorizontalAlignment','center');
    set(gca, 'visible', 0);

    % Get the name of the image the user wants to use.
    folder = '/home/tyson/Raiden/networks/output/test_deeplabv3_256x256_2019-08-18_121943/2017-11-22_144155_010/output';
    filename = sprintf('pixelLabel.%03d.png',jj);
    fullFileName = fullfile(folder, filename);
    
    origFolder = ('/home/tyson/Raiden/data/resized/256x256/2017-11-22_144155/2017-11-22_144155_010/image/');
    origFile = sprintf('2017-11-22_144155_010.%08d.png',jj+origOffset);
    origFileName = fullfile(origFolder,origFile);

    % [filename, folder] = uigetfile({'*.jpg';'*.bmp'},'Select image');
    labelImage = imread(fullFileName);
    origImage = imread(origFileName);
    
    % choose the lightning label (minus edges of frame)
    chosenLabel = 1;
    maskedImage = labelImage;
    maskedImage(maskedImage~=chosenLabel) = 0;
    maskedImage(maskedImage>0) = 1;
    edgeRemove = 4;
    maskedImage(edgeRemove,:) = 0;
    maskedImage(end-edgeRemove,:) = 0;
    maskedImage(:,edgeRemove) = 0;
    maskedImage(:,end-edgeRemove) = 0;
    
    % Prepare the ground mask
    groundLabel = 5;
    groundImage = labelImage;
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
    assert(min(size(maskedImage)==size(labelImage))==1);
    [x_max, y_max] = size(maskedImage);

    
%% PLOT 

    % plot results
    sp1 = subplot_tight(2, 5, 1);
    cla;
    imshow(origImage);
    p1 = gca;
    box on
%     if ~exist('t1')
        t1 = title('Input Image');
%     end
    hold off
    
    % plot labels
    sp2 = subplot_tight(2, 5, 2);
    cla;
    setupColors;
    segImage = labeloverlay(origImage,labelImage, ...
                'Colormap',cmap,'Transparency',0.4);
    imshow(segImage);
    p2 = gca;
    box on
%     if ~exist('t2')
        t2 = title('Output Label');
%     end
    hold off
    
    % show masked image
    sp3 = subplot_tight(2, 5, 3); 
%     cla;
    plot_input = imshow(maskedImage,[]);
%     xlim([0 x_max-1])
%     ylim([0 y_max-1])
%     axis on image;
    p3 = gca;
%     if ~exist('t3')
        t3 = title('Binary mask','fontsize',fontSize);
%     end
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
    sp4 = subplot_tight(2, 5, 6);
    if numel(pointImage)>0
        plot_point = scatter(pointImage(:,1),pointImage(:,2),10,'.');
    else
        cla;
    end
    axis on image;
    set(gca, 'YDir','reverse');
    xlim([0 255]);
    ylim([0 255]);
    xticks([0 128 255]);
    yticks([0 128 255]);
    box on
%     if ~exist('t4')
        t4 = title('Image as points','fontsize',fontSize);
%     end
    hold off

    % choose minimum cluster size
    minpts = min(round(sqrt(x_max)),4);

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

        % plot clusters
        sp5 = subplot_tight(2, 5, 7);
        plot_clusters = gscatter(pointImage(:,1),pointImage(:,2),idx);
        sp5.Legend.Visible = 'off'
        axis on image;
        set(gca, 'YDir','reverse');
        xlim([0 255]);
        ylim([0 255]);
        hFig=findall(0,'type','figure');
        hLeg=findobj(hFig(1,1),'type','legend');
        set(hLeg,'visible','off')
        xticks([0 128 255]);
        yticks([0 128 255]);
        box on
%         if ~exist('t5')
            t5 = title(strcat({'epsilon = '},string(epsilon),{' and minpts = '},string(minpts)));
%         end
        hold off


        % Find Centroids:
        ia = unique(idx);
        numClusters = numel(ia);

%       % Weighted cluster initialise:
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
        hold off
        
        % plot reduced clusters
        sp6 = subplot_tight(2, 5, 8);
        plot_reduced = scatter(pointImage(:,1),pointImage(:,2));
        hold on
        plot_centroid = scatter(weightedCentre(1),weightedCentre(2),'filled','r');
        axis on image;
        set(gca, 'YDir','reverse');
        xlim([0 255]);
        ylim([0 255]);
        xticks([0 128 255]);
        yticks([0 128 255]);
        box on
        hold off
%         if ~exist('t6')
            t6 = title(strcat({'Weighted centroid = ['},string(weightedCentre(1)),{' '}, string(weightedCentre(2)),']'),'FontSize',12);
%         end
        hold off
        
        % plot centroids
        sp7 = subplot_tight(2, 5, [4, 5, 9, 10] );
%         scatter(centroidMarker(:,1),centroidMarker(:,2),50)
%         hold on
%         cla;
        plot_reconstructed = imshow(1-reconstructedImage,[]);
        set(gca, 'YDir','reverse')
        xlim([0 255]);
        ylim([0 255]);
        xticks([0 128 255]);
        yticks([0 128 255]);
%         if ~exist('t7')
            t7 = title('Reconstructed Image','fontsize',fontSize);
%         end
        hold on
        offset = [6 0];
        for kk=2:size(centroidMarker,1)
            if (~min(centroidMarker(kk,:)==[0 0]) && ~min(centroidMarker(kk-1,:)==[0 0]))
                p0 = centroidMarker(kk-1,:);
                p1 = centroidMarker(kk,:);
                vectarrow(p0,p1,0.9,[0 1 0]);
                direction{kk} = p1-p0;
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
            vectarrow([0 0]+offset,value+offset,2,[1 0 0]);
            if size(direction,2)>2
                if value(2)<0
                    dir='up';
                elseif value(2)>0
                    dir='down';
                else
                    dir='unknown';
                end
                text(128,240,dir,'FontSize',20,'Color',[1 0 0 0.8],'HorizontalAlignment','center');
            end
            hold off
        end
        axis on image
        hold off
        assert(max(size(maskedImage)-size(reconstructedImage))==0)
        
    else
%         sp5 = subplot(2, 5, 7);
        set(sp5,'Color',[0.5 0.5 0.5 0.5]);
        for ii=1:numel(plot_clusters)
%             if exist('plot_clusters(ii).Color','var')
                plot_clusters(ii).Color = [0.5 0.5 0.5 0.5];
%             end
        end
        legend('hide');
        hold off
        
%        sp6 = subplot(2, 5, 8);
        set(sp6,'Color',[0.5 0.5 0.5 0.5]);
        if exist('plot_reduced','var')
            plot_reduced.MarkerFaceColor = [0.5 0.5 0.5];
            plot_reduced.MarkerEdgeAlpha = 0;
            %             for ii=1:numel(plot_reduced)
            %                 if exist('plot_reduced(ii).MarkerFaceColor')
            %                     plot_reduced(ii).MarkerFaceColor  = [0.5 0.5 0.5];
            %                     plot_reduced(ii).MarkerEdgeColor  = [0.5 0.5 0.5];
            %                 end
        end
%         if exist('plot_centroid.MarkerFaceColor','var')
            plot_centroid.MarkerFaceColor  = [0.18 0.18 0.18];
%         end
        title(sp5, "Cluster observation skipped");
        hold off
    end
   
    if jj < frameEnd
        jj = jj + 1;
    else
%         clf;
%         pause(0.5);
        clearvars -except jj frameStart frameEnd keepPlaying fig1 fontSize origOffset plot_clusters plot_clusters
        jj = frameStart;
    end
    
%%% Display Plot
    sp5.HandleVisibility = 'off';
    sp6.HandleVisibility = 'off';
    sp7.HandleVisibility = 'off';
    plot_reduced.HandleVisibility = 'off';
    drawnow limitrate;                                      % draw graph
    clf;
    if exist('sp7','var')&& ishghandle(fig1)
        sp5.HandleVisibility = 'on';
        sp6.HandleVisibility = 'on';
        sp7.HandleVisibility = 'on';
        plot_reduced.HandleVisibility = 'on';
    end

%     delete([t1 t2 t3 t4 t5 t6 t7]);
%     arrayfun(@cla,findall(0,'type','axes'));
%     if exist('sp1')
%         delete(sp1);
%     end
%     if exist('sp2')
%         delete(sp2);
%     end
%     if exist('sp2')
%         delete(sp2);
%     end
%     if exist('sp2')
%         delete(sp2);
%     end
%     if exist('sp2')
%         delete(sp2);
%     end
%     if exist('sp2')
%         delete(sp2);
%     end
%     if exist('sp2')
%         delete(sp2);
%     end
    if ~ishghandle(fig1)                                    % break if figure window closed
        keepPlaying = false;
        break
    end
end
close all


