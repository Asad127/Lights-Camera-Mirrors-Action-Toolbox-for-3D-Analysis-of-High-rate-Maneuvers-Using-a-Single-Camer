function absolute_path = abspath(input_path)
% Converts a given path to the absolute path on the computer if it exists,
% otherwise throws an error. If it already is an absolute path
% and exists, nothing is changed.

if isfolder(input_path)
    absolute_path = dir(input_path).folder;
elseif isfile(input_path)
    directory = dir(input_path).folder;
    absolute_path = fullfile(directory, dir(input_path).name);
else
    error('Path does not exist, cannot make it absolute.')
end

end