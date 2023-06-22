function [sorted_files, sorted_indices] = sortfiles_formatted(basenames)
%{
Sorting Method # 1: Sort using the filename assumptions and single unique
numeric part constraint per filename.
%}

% Extract numeric parts using regular expressions.
unique_numeric_parts = cellfun(@(basename) str2double(regexp(basename, '\d+', 'match')), basenames, 'UniformOutput', false);
num_numeric_parts = numel(unique_numeric_parts{1});

% 1: 20, 20, 30, 31, 52
% 2: 1, 5, 3, 10, 20

if num_numeric_parts ~= 1
    location_wise_parts = cell(1, num_numeric_parts);
    fprintf('Which of the following numeric parts of the filename do you want to sort according to?\n')
    for i = 1 : num_numeric_parts
        array_numeric_parts = cell2mat(unique_numeric_parts');
        location_wise_parts{i} = array_numeric_parts(:, i);
        fprintf(['%d: ', repmat('%d, ', 1, numel(unique_numeric_parts) - 1), '%d\n'], i, location_wise_parts{i});
    end

    numeric_idx = input('Select the number corresponding to the part you want to use: ');
    unique_numeric_parts = location_wise_parts(numeric_idx);
end

% Get the sorting key for rearranging our image files array
[~, sorted_indices] = sort(cell2mat(unique_numeric_parts));  % cell2mat(cellarr) = [cellarr{:}]
sorted_files = basenames(sorted_indices);

