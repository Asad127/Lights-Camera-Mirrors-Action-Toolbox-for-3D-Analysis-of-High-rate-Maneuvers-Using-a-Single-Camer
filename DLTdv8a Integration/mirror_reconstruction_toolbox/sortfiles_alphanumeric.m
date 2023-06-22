function [sorted_files, basename_numbers] = sortfiles_alphanumeric(basenames)
%{
    WORK IN PROGRESS
%}

% Separate basename into text and numeric parts
matches = regexp(filename, '(\d+|\D+)', 'match');

% Display the extracted parts
disp(numericParts);
disp(textParts);


end

