function [strokeCount, strokesInfo] = getStrokeCount(imds, gap)
    %#ok<*AGROW>
    strokeIndices = getStrokeIndices(imds);
    if nargin > 2
        gap =2;
    end
    % testCase1: strokeIndices = [1]; %expect 1 duration 1 
    % testCase2: strokeIndices = [ 1 5 8]; %expect 3 all 1
    % testCase3: strokeIndices = [ 1 2 3 8 9];%expect 2 duration 3 and 2
    % testCase4: strokeIndices = []; % expect 0 0
    % testCase5: strokeIndices = [ 1 2 4 8 11 19];% 4 duration 4 1 1 1
    strokeIndexLength = length(strokeIndices);
    frameIndices = []; %#ok<NASGU>
    strikeDurations = []; % Stores the durations of each stroke
    if strokeIndexLength>=1
        %initial vals
        strokeCount = 1;
        frameIndices = strokeIndices(1);
        for i=1 : strokeIndexLength
        %check if the values follow each other
        %then count them clumps
            if i == strokeIndexLength
                % collect all info on last loop
                previousStrikeIndex = frameIndices(end);
                currentDuration = strokeIndices(i) - previousStrikeIndex +1;
                strikeDurations = [strikeDurations; currentDuration]; 
                strokesInfo = [frameIndices strikeDurations];
                break;
            
            else
                % all i < strokeIndexLength
                strokeWindow = strokeIndices(i)+gap;
          
                if strokeIndices(i+1) > strokeWindow
                    strokeCount = strokeCount +1; %increase count
                    previousStrikeIndex = frameIndices(end);
                    currentDuration = strokeIndices(i) - previousStrikeIndex + 1;
                    strikeDurations = [strikeDurations; currentDuration]; 
                    frameIndices = [frameIndices ; strokeIndices(i+1)]; 
                end
            end
        end
    else
        %Return an message indicating no stroke and a 0 value
        strokeCount = 0;
        strokesInfo = [];
    end
end