function img_extension = prompt_img_extension(prompt)
% Prompt the user to enter the image extension (usually when saving
% images/frames to disk). However, this may also be to confirm image
% extensions in some places, e.g., when looking in a directory for images.
% 
% This script's lazy cousin is `guess_img_extnsion.m`, which automatically
% assumes the first image extension is the required extension and
% double-checks that it is the only image extension in the directory, and
% otherwise throws an error. However, it obviously cannot work when we are
% trying to save stuff to disk and the source was not an existing image 
% (e.g., a video's frames) - in these cases, it's the user's choice.

default = load('defaults.mat');

while true

    img_extension_mapping = struct('b', '.bmp', 'j', '.jpg', 'p', '.png', 't', '.tif');    
    
    helpfmt = [
        'Supported Image Formats = ' ...
        repmat('%s, ', 1, numel(default.SUPPORTED_IMG_EXTS) - 1) ...
        '%s\nInput Mapping: "j" = ".jpg", "p" = ".png", "t" = ".tif", "b" = ".bmp"\n' ...
    ];

    fprintf(helpfmt, default.SUPPORTED_IMG_EXTS{:});

    img_extension = input(prompt, 's');

    if isempty(img_extension)
        img_extension = default.IMG_EXT;
    elseif isfield(img_extension_mapping, img_extension)
        img_extension = img_extension_mapping.(img_extension);
    else
        fprintf(['\n[BAD INPUT] Unrecognized extension. Enter either "j" or ".jpg" ' ...
            'for JPG and similar for other extensions.\n'])
        continue
    end
    
    break
end

end