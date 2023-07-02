function convert_vid_to_mp4(input_vid, output_vid)

default = load('defaults.mat');

switch nargin
    case 0
        % Transpose the resulting cell array to get a cell column vector as 
        % required by the ui boxes' extension/format filters
        vid_filter = cellfun(@(extension) ['*' extension], default.SUPPORTED_VID_EXTS, 'UniformOutput', false)';
        [input_file, input_dir] = uigetfile(vid_filter, 'Locate the video to convert to mp4');
        [~, input_name, ~] = fileparts(input_file);
        input_vid = fullfile(input_dir, input_file);
        output_vid = uiputfile( ...
            ['*' default.VID_EXT], ...
            'Choose location to save the converted video to', ...
            fullfile(input_dir, [input_name default.VID_EXT]) ...
        );
    case 1
        [input_dir, input_name, input_ext] = fileparts(input_vid);
        input_vid = fullfile(input_dir, [input_name input_ext]);
        output_vid = uiputfile( ...
            ['*' default.VID_EXT], ...
            'Choose location to save the converted video to', ...
            fullfile(input_dir, [input_name default.VID_EXT]) ...
        );
end

vid_in = VideoReader(input_vid);
vid_out = VideoWriter(output_vid, 'MPEG-4');
open(vid_out);

total_frames = vid_in.NumFrames;
curr_frame = 1;

st = dbstack.name;
bar = waitbar( ...
    curr_frame/total_frames, ...
    sprintf("Converting video to MP4: %d/%d", curr_frame, total_frames), ...
    'Name', st(1).name);

fprintf('Converting video "%s" to MP4...', input_vid);

while hasFrame(vid_in)
    frame_in = readFrame(vid_in);
    writeVideo(vid_out, frame_in);
    curr_frame = curr_frame+ 1;
    bar = waitbar(curr_frame/total_frames, sprintf("Converting video to MP4: %d/%d", curr_frame, total_frames));
end

% Cleanup
close(vid_in);
close(vid_out);
waitbar(1, bar, "Finished!")
pause(1);
fprintf("done.\n")

end