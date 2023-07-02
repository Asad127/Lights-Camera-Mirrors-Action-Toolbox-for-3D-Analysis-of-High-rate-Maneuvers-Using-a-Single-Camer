function img_extension = guess_img_extension(input_directory, supported_img_extensions)

listing = dir(input_directory);
listing = listing(3 : end);  % remove '.' and '..' from listing

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

img_extension = first_img_extension;

end