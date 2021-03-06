function imArray = shiftStack(imArray, dx, dy)
%shiftStack displaces a stack dx pixels to the right and dy pixels down.

stackInfo = whos('imArray');

if dx ~= 0 || dy ~= 0
    % Create an empty canvas to hold the image
    
    imdim = size(imArray);
    
    if size(imArray,3) == 1
        imdim(3) = 1;
    end
    canvas = zeros(imdim(1) + abs(dy)*2, ...
                   imdim(2) + abs(dx)*2, imdim(3), stackInfo.class);

    canvas(abs(dy) + (1 : imdim(1)), ...
           abs(dx) + (1 : imdim(2)), :) = imArray; % put im in cntr...


    % Crop frame
    imArray = canvas( abs(dy) - dy + (1:imdim(1)), ...
                      abs(dx) - dx + (1:imdim(2)), :);

end


end