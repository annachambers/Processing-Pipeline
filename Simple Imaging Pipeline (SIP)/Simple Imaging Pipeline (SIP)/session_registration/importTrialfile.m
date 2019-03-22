function trialData = importTrialfile(filename, startRow, endRow)
%IMPORTFILE Import numeric data from a text file as a matrix.
%   M1006201711011751PREADAA001TRIALS = IMPORTFILE(FILENAME) Reads data
%   from text file FILENAME for the default selection.
%
%   M1006201711011751PREADAA001TRIALS = IMPORTFILE(FILENAME, STARTROW,
%   ENDROW) Reads data from rows STARTROW through ENDROW of text file
%   FILENAME.
%
% Example:
%   m1006201711011751PreADAA001trials = importfile('m1006-20171101_1751_PreADAA-001_trials.txt', 1, 2);
%
%    See also TEXTSCAN.

% Auto-generated by MATLAB on 2017/11/02 12:09:23

%% Initialize variables.
delimiter = '\t';
if nargin<=2
    startRow = 1;
    endRow = inf;
end

%% Read columns of data as text:
% Get number of trials
try
    num_trials = length(dlmread(filename,','))-1;
    cont = 1;

catch
    cont = 0;
end

if cont == 1
    formatSpec = '%s';
    for x = 1:num_trials-1
        formatSpec = [formatSpec '%s'];
    end
    formatSpec = [formatSpec,'%[^\n\r]'];

    %% Open the text file.
    fileID = fopen(filename,'r');

    %% Read columns of data according to the format.
    % This call is based on the structure of the file used to generate this
    % code. If an error occurs for a different file, try regenerating the code
    % from the Import Tool.
    dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
    for block=2:length(startRow)
        frewind(fileID);
        dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(block)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
        for col=1:length(dataArray)
            dataArray{col} = [dataArray{col};dataArrayBlock{col}];
        end
    end

    %% Close the text file.
    fclose(fileID);

    %% Convert the contents of columns containing numeric text to numbers.
    % Replace non-numeric text with NaN.
    raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
    for col=1:length(dataArray)-1
        raw(1:length(dataArray{col}),col) = dataArray{col};
    end
    numericData = NaN(size(dataArray{1},1),size(dataArray,2));

    for col=1:num_trials
        % Converts text in the input cell array to numbers. Replaced non-numeric
        % text with NaN.
        rawData = dataArray{col};
        for row=1:size(rawData, 1);
            % Create a regular expression to detect and remove non-numeric prefixes and
            % suffixes.
            regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\.]*)+[\,]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\.]*)*[\,]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
            try
                result = regexp(rawData{row}, regexstr, 'names');
                numbers = result.numbers;

                % Detected commas in non-thousand locations.
                invalidThousandsSeparator = false;
                if any(numbers=='.');
                    thousandsRegExp = '^\d+?(\.\d{3})*\,{0,1}\d*$';
                    if isempty(regexp(numbers, thousandsRegExp, 'once'));
                        numbers = NaN;
                        invalidThousandsSeparator = true;
                    end
                end
                % Convert numeric text to numbers.
                if ~invalidThousandsSeparator;
                    numbers = strrep(numbers, '.', '');
                    numbers = strrep(numbers, ',', '.');
                    numbers = textscan(numbers, '%f');
                    numericData(row, col) = numbers{1};
                    raw{row, col} = numbers{1};
                end
            catch me
            end
        end
    end


    % Find the number of trials valid in the trials file
    stop = 0;
    for x = 1:col
        if ~isempty(raw{1,x})
            stop = stop+1;
        else
            break;
        end
    end


    %% Create output variable
    data = zeros(row,col);
    
    for x = 1:row
        for y = 1:col
            stringValue = (dataArray{y}{x});
            stringValue = strrep(stringValue,',','.');
            data(x,y) = str2double(stringValue); 
            
        end        
    end
    trialData = data;

else
    trialData = 0;
end

