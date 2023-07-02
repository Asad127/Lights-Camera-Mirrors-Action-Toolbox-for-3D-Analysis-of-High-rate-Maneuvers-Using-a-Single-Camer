function absolute_path = abspath(input_path)
% Converts a given path to the absolute path on the computer if it exists,
% otherwise retruns an empty character.

if isfolder(input_path)
    absolute_path = dir(input_path).folder;
elseif isfile(input_path)
    directory = dir(input_path).folder;
    absolute_path = fullfile(directory, dir(input_path).name);
else
    warning('Provided path is nto an existing file or folder. Returned an empty character.')
    absolute_path = '';
end

end