function frames_to_vid(input_frame_filepaths_or_dir, output_vid_filepath)

default = load('defaults.mat');

switch nargin
    case 0
        error('Require a cell array of sorted frame filepaths OR a directory containing video frames.')
    case 1
        % If we have the input directory/file but not the output video
        % path, we will just place the video in the input directory.
        if isfolder(input_frame_filepaths_or_dir)
            output_vid_filepath = fullfile(input_frame_filepaths_or_dir, ['video' default.VID_EXT]);
        else
            [input_dir, ~, ~] = fileparts(input_frame_filepaths_or_dir);
            output_vid_filepath = fullfile(input_dir, ['video' default.VID_EXT]);
        end
end

if isfolder(input_frame_filepaths_or_dir)
    input_dir = input_frame_filepaths_or_dir;
    
    % Either ask the user to input image extension, or guess it based on
    % directory contents.
    if default.GUESS_IMG_EXT_WHEN_POSSIBLE
        img_extension = guess_img_extension(input_dir, default.SUPPORTED_IMG_EXTS);
    else
        img_extension = prompt_img_extension('[PROMPT] Enter the extension of images to undistort: ');
    end
    
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
    img_filepaths = input_filepaths;
end

% Split into fileparts just to ensure written video is mp4.
[output_dir, output_base, ~] = fileparts(output_vid_filepath);

% Set up the VideoWriter object
output_video = VideoWriter( ...
    fullfile(output_dir, [output_base default.VID_EXT]), ...
    'MPEG-4' ...
);

output_video.FrameRate = 30;
open(output_video);

st = dbstack;
bar = waitbar( ...
    0, ...
    sprintf('Stitching frames to video: %d/%d', 1, numel(img_filepaths)), ...
    'Name', st(1).name ...
);

% Loop through each image file, read frames, and write to the video
for i = 1 : numel(img_filepaths)
    % Read the current image file
    image_path = img_filepaths{i};
    frame = imread(image_path);
    
    % Write the frame to the video
    writeVideo(output_video, frame);

    waitbar( ...
        i/numel(img_filepaths), ...
        bar, ...
        sprintf('Stitching frames to video: %d/%d', i, numel(img_filepaths)) ...
    );

end

waitbar(1, bar, 'Finished!');
pause(1);
close(bar);
close(output_video);