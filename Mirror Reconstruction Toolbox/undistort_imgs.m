function undistort_imgs(distorted_filepaths_or_dir, dist_coefs,  ...
     intrinsics, undistorted_dir, undistorted_img_suffix, grayscale)
% Undistort a given set of images in the form of a single directory, or a 
% sorted cell array of image filepaths. In the case of a directory, the
% function uses natsort from MATLAB File Exchange if set, and otherwise 
% assumes simple filename structure described in _imgname_assumptions.txt 
% and applies sortfiles_formatted. 
%
% This is a function version of create_undistorted_imgs_script, which is
% aimed at undistorting selected images, not necessarily all within a
% directory, using the merged BCT calibration file directly.
%
% TAKES
% =====
% distorted_filepaths_or_dir (required):
%   Either a directory or cell array of image filepaths. In case of the
%   former, it is assumed the directory contains images and the user is
%   asked to enter the image extension.
% dist_coefs (required):
%   The distortion coefficients to use for image undistortion.
% intrinsics (required):
%   The camera (or mirror view) intrinsics to use for image undistortion.
% undistorted_dir (optional):
%   Output directory where the undistorted images are stored.
% undistorted_img_suffix (char vector, default = ''):
%   Characters to append to the end of the file's basename (before
%   extension). E.g., if this argument is '_rect' and input image was 
%   frame1.jpg, the output undistorted image would be frame1_rect.jpg.
% grayscale (boolean, default = false):
%   Whether the undistorted image is color or grayscale.
%
% FUNCTIONS CALLED
% =========================================================================
% undistort_img.m:
%   Contains the math implementing the undistortion transformation. Returns
%   the undistorted image that this function proceeds to save. 

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
            undistorted_dir = fullfile(distorted_filepaths_or_dir, '_rect');
        else
            [undistorted_dir, ~, ~] = distorted_filepaths_or_dir{1};
            undistorted_dir = fullfile(undistorted_dir, '_rect');
        end
        undistorted_img_suffix = '';
        grayscale = false;
    case 4
        undistorted_img_suffix = '';
        grayscale = false;
    case 5
        grayscale = false;
end

default = load('defaults.mat');

if isfolder(distorted_filepaths_or_dir)
    input_dir = distorted_filepaths_or_dir;
    fprintf('Input path "%s" appears to be a directory.\n', input_dir)
    
    % Either ask the user to input image extension, or guess it based on
    % directory contents.
    img_extension = guess_img_extension(input_dir, default.SUPPORTED_IMG_EXTS);
    fprintf('Guessed Image Extension: %s\n', img_extension)

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
    [~, img_name, img_extension] = fileparts(img_file);
    
    % Undistort and save it.
    if grayscale
        undistorted_img = undistort_img_gray(img, dist_coefs, intrinsics);
    else
        undistorted_img = undistort_img(img, dist_coefs, intrinsics);
    end
    imwrite(undistorted_img, fullfile(undistorted_dir, [img_name undistorted_img_suffix img_extension]))
    waitbar(i/total_imgs, bar, sprintf('Undistorting images: %d/%d', img_counter, total_imgs));
    img_counter = img_counter + 1;
end

waitbar(1, bar, 'Finished!');
pause(1);
close(bar);

end