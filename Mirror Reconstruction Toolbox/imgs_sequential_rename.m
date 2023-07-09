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

default = load('defaults.mat');

fprintf(['ABOUT: This script is intended to rename images in a directory using an order-aware ' ...
    'format, as a sequence\nstarting from 1. E.g., given three images {img1.jpg, img10.jpg, img5.jpg}, ' ...
    'this script will first sort as\n{img1.jpg, img5.jpg, img10.jpg}, and then rename them as ' ...
    '{Image1.jpg, Image2.jpg, Image3.jpg} respectively.\n\nSorting done with "sortfiles_formatted.m" ' ...
    'or optionally by MATLAB File Exchange (FEX) "natsortfiles.m" if\nFEX_USE_NATSORT is enabled in ' ...
    'project-local "defaults.mat" AND the FEX files are setup correctly in\nMATLAB path.\n\n'] ...
)

while true
    dir_or_files = input(['[PROMPT] Rename (1) an entire directory of images, or (2) just a ' ...
        'few images? (1 or 2): ']);
    if ~ismember(dir_or_files, [1, 2])
        fprintf('[BAD PROMPT] Only 1 or 2 are accepted values. Please try again.\n')
        continue
    end
    break
end

if dir_or_files == 1
    input_dir = uigetdir('', 'Select the directory containing the images (cancel = use default directory)');
    
    if ~input_dir
        input_dir = default.BCT_CALIB_IMGS_DIR;
        if ~isfolder(input_dir)
            err_msg = sprintf( ...
                ['Default directory for calibration frames does not exist. ' ...
                '\nPossible issues:' ...
                '\n\t(1) Calibration frames might not have been extracted at all' ...
                '\n\t(2) Calibration frames might not have been extracted to the default folder' ...
                '\n\t(3) Project structure is incorrect' ...
                '\nPossible solutions:' ...
                '\n\t(1) Run `calib_extract_vid_frames.m` before this script' ...
                '\n\t(2) Locate video where it was saved or repeat (1) with default values ' ...
                '(leave inputs blank where possible)' ...
                '\n\t(3) Run `project_setup.m` and ensure that the relevant ' ...
                'directory is created'] ...
            );
            error(err_msg);
        end
    end
    
    if default.GUESS_IMG_EXT_WHEN_POSSIBLE
        img_extension = guess_img_extension(input_dir, default.SUPPORTED_IMG_EXTS);
        fprintf('Guessed Image Extension: %s\n', img_extension)
    else
        img_extension = prompt_img_extension( ...
            '[PROMPT] Enter image extension (blank = default image extension): ' ...
        );
    end
    
    % Need to sort since directory listings aren't sorted.
    
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

else
    img_filter = cellfun(@(extension) ['*' extension], default.SUPPORTED_IMG_EXTS, 'UniformOutput', false)';

    [input_imgs, imgs_dir] = uigetfile( ...
        img_filter, ...
        'Select the images to undistort (CTRL + A to select all)', ...
        'MultiSelect', 'on' ...
    );

    if ~isa(input_imgs, 'cell')
        if ~input_imgs
            error('Operation canceled by user.')
        end
        input_imgs = cellstr(input_imgs);  % force single selection to cell
    end
    
    img_filepaths = cellfun(@(file) fullfile(imgs_dir, file), input_imgs, 'UniformOutput', 'false');

end

fprintf('Renaming files...')

% Rename and move the image files sequentially.
move_path_conflict = false;
for i = 1 : numel(img_filepaths)
    img_filepath = img_filepaths{i};

    % New name based on old name and img_extension, but different number.
    new_img_file = sprintf(default.IMGNAME_FMT, i, img_extension);
    new_img_filepath = fullfile(input_dir, new_img_file);

    % Copy the current (original) file to the same input_dir with new name.
    if ~strcmp(img_filepath, new_img_filepath)
        movefile(img_filepath, new_img_filepath);
    else
        move_path_conflict = true;
    end
end

fprintf('done.\n')

if move_path_conflict
    fprintf(['[WARNING] Move Path Conflict: Attempted to copy file or directory onto itself.\n' ...
        'Move instruction was skipped.\n\n'] ...
    )
end