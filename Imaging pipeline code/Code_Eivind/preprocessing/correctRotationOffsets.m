function [ imArray, corrections ] = correctRotationOffsets( imArray, rotating )
%correctRotationOffsets Correct artifacts due to rotation in a stack of images.
%   Detailed explanation goes here

% Pre-assign array for storing corrections
[~, ~, nFrames] = size(imArray);
corrections = zeros(nFrames, 1);

% Create reference image without rotation artifacts
ref = createReferenceFromStationaryImages(imArray, rotating);

% Find Transitions between rotation and stationary periods.
transitions = zeros(size(rotating));
transitions(2:end) = diff(rotating);

% Find indices where trial starts and stop (a.k.a transitions)
if rotating(1) == 1
    stationaryStartIdx = find(transitions == -1);
    rotationStartIdx = vertcat(1, find(transitions == 1));
else 
    stationaryStartIdx = vertcat(1, find(transitions == -1));
    rotationStartIdx = find(transitions == 1);
end

startIdc = sort(vertcat(stationaryStartIdx, rotationStartIdx));

% Used for printing status to commandline
prevstr=[];

% Loop through different pieces of array.
for i = 1:numel(startIdc)
        
    % Find start and stop indices for current "piece"
    start = startIdc(i);
    if i == numel(startIdc)
        stop = length(rotating);
    else 
        stop = startIdc(i+1) - 1;
    end
    
    % Display message
    str = ['registering frame ' num2str(start) '-' num2str(stop)];
    refreshdisp(str, prevstr, i);
    prevstr=str;

    % Determine if current piece is rotating or not
    if i == 1
        rot = rotating(1);
    else
        rot = ~rot;
    end
    
    % Extract the images of the current "piece"
    imArray_piece = imArray(:, :, start:stop);
    
    % Only align if images are rotated.
    if rot
        rotation_offsets = findRotationOffsets(imArray_piece, ref);
        corrections(start:stop, 1) = rotation_offsets;    
        imArray(:,:, start:stop) = imArray_piece;
        
    end
    
    % Create new reference image if images are not rotated and it is not first piece
    % (A complete mess to make a ref stack of 100 images....)
    if ~rot && i ~= 1
        nFrames_piece = size(imArray_piece, 3);
        if nFrames_piece >= 100
            ref_stack = imArray_piece(:, :, end-99:end);
        elseif nFrames_piece < 100 && ~exist('ref_stack', 'var')
            ref_stack = imArray_piece;
        elseif nFrames_piece < 100 && size(ref_stack, 3) < 100
            nFrames_keep = min([100 - nFrames_piece, size(ref_stack, 3)]);
            ref_stack(:, :, 1:nFrames_keep) = ref_stack(:, :, end-(nFrames_keep-1):end);
            ref_stack(:, :, nFrames_keep+1:end) = imArray_piece;
        else    
            nFrames_keep = 100 - nFrames_piece;
            ref_stack(:, :, 1:nFrames_keep) = ref_stack(:, :, end-(nFrames_keep-1):end);
            ref_stack(:, :, nFrames_keep+1:end) = imArray_piece;
        end
        ref = createReferenceFromStationaryImages(ref_stack, rotating, ref);       
    end
        
end

fprintf(char(8*ones(1,length(prevstr))));
fprintf('Registered all images.');
fprintf('\n');

end


