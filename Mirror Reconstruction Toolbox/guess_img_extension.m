function img_extension = guess_img_extension(input_directory, supported_img_extensions)

listing = dir(input_directory);
listing = listing(~ismember({listing.name}, {'.', '..'}));  % remove '.' and '..' from listing

if isempty(listing)
    error('Input directory is empty.')
end

first_img_extension = nan;
for i = 1 : numel(listing)
    [~, ~, extension] = fileparts(listing(i).name);

    if ismember(extension, supported_img_extensions)
        if isnan(first_img_extension)
            first_img_extension = extension;
        elseif ~strcmp(extension, first_img_extension)
            err_msg = sprintf(['Multiple image extensions encountered in directory.\nPlease make sure ' ...
                'only one type of images exist in the input directory.']);
            error(err_msg)
        end
    end
end

if isnan(first_img_extension)
    error(['No images with extensions {', ...
        repmat('%s, ', 1, numel(supported_img_extensions) - 1), ...
        '%s} found in input directory.'], ...
        supported_img_extensions{:} ...
    )
end

img_extension = first_img_extension;

end