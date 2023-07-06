function undistort_imgs(distorted_filepaths_or_dir, dist_coefs,  ...
     intrinsics, undistorted_dir)
% Undistort a given set of images in the form of a single directory, or a
% sorted cell array of image filepaths. In the case of a directory, the
% function uses natsort from MATLAB File Exchange if set, and otherwise
% assumes simple filename structure described in _imgname_assumptions.txt
% and applies `sortfiles_formatted.m` to sort the directory files.
%
% This is a function version of `create_undistorted_imgs.m`, which is
% aimed at undistorting selected images, not necessarily all within a
% directory, using the merged BCT calibration file directly. Thus, the
% script automatically undistorts w.r.t. all views' distortion coefs,
% whereas this function only does it for one view at a time.
%
% TAKES
% =========================================================================
% distorted_filepaths_or_dir (required):
%   Either a directory or cell array of image filepaths. In case of the
%   former, it is assumed the directory contains images and, based on value
%   of `GUESS_IMG_EXT_WHEN_POSSIBLE` in project's `defaults.m` file, the 
%   image extension is either guessed or the user is asked for it.
% dist_coefs (required):
%   The distortion coefficients to use for image undistortion.
% intrinsics (required):
%   The camera (or mirror view) intrinsics to use for image undistortion.
% undistorted_dir (optional, default = fullfile(input_imgs_dir, rect)):
%   Output directory where the undistorted images are stored. If not
%   provided and input is a directory, the undistorted images are stored
%   in a folder 'rect' within the input directory. If the input path is a 
%   cell array of filepaths, it treats their common directory as the input
%   directory.
%
% FUNCTIONS CALLED
% =========================================================================
% undistort_img.m:
%   Contains the math implementing the undistortion transformation. Returns
%   the undistorted image that this function proceeds to save.
% undistort_img_gray.m:
%   Grayscale version of `undistort_img.m`.

switch nargin
    case 0
        err_msg = sprintf( ...
            ['Require input images or directory of images to undistort.' ...
            '\nRequire distortion coefficients and camera intrinsics for undistortion.']);
        error(err_msg)
    case 1
        err_msg = sprintf('Require distortion coefficients and camera intrinsics for undistortion.');
        error(err_msg)
    case 2
        err_msg = sprintf('Require camera intrinsics for undistortion.');
        error(err_msg);
    case 3
        if isfolder(distorted_filepaths_or_dir)
            undistorted_dir = fullfile(distorted_filepaths_or_dir, 'rect');
        else
            [undistorted_dir, ~, ~] = distorted_filepaths_or_dir{1};
            undistorted_dir = fullfile(undistorted_dir, 'rect');
        end
end

default = load('defaults.mat');

if ~isfolder(undistorted_dir)
    mkdir(undistorted_dir)
end

if isfolder(distorted_filepaths_or_dir)
    input_dir = distorted_filepaths_or_dir;
    fprintf('Input path "%s" appears to be a directory.\n', input_dir)

    % Either ask the user to input image extension, or guess it based on
    % directory contents.
    if default.GUESS_IMG_EXT_WHEN_POSSIBLE
        img_extension = guess_img_extension(input_dir, default.SUPPORTED_IMG_EXTS);
        fprintf('Guessed Image Extension: %s\n', img_extension)
    else
        img_extension = prompt_img_extension('[PROMPT] Enter the extension of images to undistort: ');
    end

    % Get all image filepaths from the directory.
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
    % Assume the input paths are a cell array of already sorted image filepaths.
    img_filepaths = distorted_filepaths_or_dir;
end

total_imgs = numel(img_filepaths);
img_counter = 1;

st = dbstack;
bar = waitbar(0, sprintf('Undistorting images: %d/%d', img_counter, total_imgs), 'Name', st(1).name);

% Undistortion loop.
for i = 1 : total_imgs

    % Read the image file.
    img_file = img_filepaths{i};
    img = imread(img_file);
    dims = size(img);
    [~, img_name, img_extension] = fileparts(img_file);

    if ndims(img) == 2
        % Image is grayscale.
        undistorted_img = undistort_img_gray(img, dist_coefs, intrinsics);
    elseif ndims(img) == 3 && dims(3) == 3
        % Image is RGB.
        undistorted_img = undistort_img(img, dist_coefs, intrinsics);
    end

    undistorted_file = [img_name img_extension];
    undistorted_filepath = fullfile(undistorted_dir, undistorted_file);

    imwrite(undistorted_img, undistorted_filepath)
    waitbar(i/total_imgs, bar, sprintf('Undistorting images: %d/%d', img_counter, total_imgs));
    img_counter = img_counter + 1;
end

waitbar(1, bar, 'Finished!');
pause(1);
close(bar);

end