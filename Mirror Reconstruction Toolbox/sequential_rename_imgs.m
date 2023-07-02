%{
FEX natsortfiles may be used by setting FEX_USE_NATSORT = true in
`defaults.m` and running `create_defaults_matfile.m`

Rename images in a direcotry sequentially. That is, consecutively rename 
all images in a directory while maintaining the original frame numbering
sequence. That is, [frame_20, frame_60, frame_100] would be renamed to 
[Image1, Image2, Image3] and so on.

This script performs sorting based on the filename assumptions described in 
_imgname_assumptions.txt or by using Stephen Cobeldick's natsort from 
MATLAB File Exchange (FEX), which naturally sorts files without imposing 
restrictions on the filenames. Assuming you have added downloaded and added 
natsort to your MATLAB PATH, open this toolbox's `defaults.m` script and 
set FEX_USE_NATSORT to true. This will use natsort wherever natural sorting 
is required instead of our sorting functions (delimited fixed format and
alphanumeric).

If your use case calls for formats that break our filename assumptions or 
are generally quite complicated to create your own sorting function, consider 
using natsort. 
%}

defaults;

input_dir = uigetdir('', 'Select the directory containing the images (cancel = use default directory)');

if ~input_dir
    input_dir = BCT_CALIB_IMGS_DIR;
    if ~isfolder(input_dir)
        err_msg = sprintf( ...
            ['Default directory for calibration frames does not exist. ' ...
            '\nPossible issues:' ...
            '\n\t(1) Calibration frames might not have been extracted at all' ...
            '\n\t(2) Calibration frames might not have been extracted to the default folder' ...
            '\n\t(3) Project structure is incorrect' ...
            '\nPossible solutions:' ...
            '\n\t(1) Run `calib_extract_vid_imgs.m` before this script' ...
            '\n\t(2) Locate video where it was saved or repeat (1) with default values ' ...
            '(leave inputs blank where possible)' ...
            '\n\t(3) Run `setup_project_structure.m` and ensure that the relevant ' ...
            'directory is created'] ...
        );
        error(err_msg);
    end
end

while true

    img_extension_mapping = struct('b', '.bmp', 'j', '.jpg', 'p', '.png', 't', '.tif');    
    
    helpfmt = [
        'Supported Image Formats = ' ...
        repmat('%s, ', 1, numel(SUPPORTED_IMG_EXTS) - 1) ...
        '%s\n("j" = ".jpg", "p" = ".png", "t" = ".tif", "b" = ".bmp"). ' ...
        'Leave blank to use default image extension.\n'
    ];

    fprintf(helpfmt, SUPPORTED_IMG_EXTS{:});

    img_extension = input(['[PROMPT] Enter image extension of calibration frames ' ...
        '(blank = default image extension): '], 's');

    if isempty(img_extension)
        img_extension = IMG_EXT;
    elseif isfield(img_extension_mapping, img_extension)
        img_extension = img_extension_mapping.(img_extension);
    else
        fprintf(['[BAD INPUT] Unrecognized extension. Enter either "j" or ".jpg" ' ...
            'for JPG and similarly for other extensions.\n'])
        continue
    end
    
    break
end

% Get and natural sort all relevant image files. Sorting ensures we
% preserve the original sequence of frames in the renamed output.

% Read all image files from the directory.
img_filepaths = dir(fullfile(input_dir, ['*' img_extension]));

% Get the basenames of the image files and convert from dir struct
% to standard fullfile format of filepaths (cell row vector).
img_filepaths = fullfile(input_dir, {img_filepaths.name});

% Sort them to maintain correct sequential ordering.
if default.FEX_USE_NATSORT
    img_filepaths = natsortfiles(img_filepaths);
else
    [~, img_basenames, ~] = fileparts(img_filepaths);
    [~, sorted_indices] = sortfiles_formatted(img_basenames);
    img_filepaths = img_filepaths(sorted_indices);
end

% Rename and move the image files sequentially.
for i = 1 : numel(img_filepaths)
    img_filepath = img_filepaths{i};

    % New name based on old name and img_extension, but different number.
    new_img_file = sprintf(default.BCT_CALIB_IMGNAME_FMT, i, img_extension);
    new_img_filepath = fullfile(input_dir, new_img_file);

    % Copy the current (original) file to the same input_dir with new name.
    copyfile(img_filepath, new_img_filepath);
end