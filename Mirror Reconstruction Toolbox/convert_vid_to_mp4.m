function convert_vid_to_mp4(input_vid, output_vid)

default = load('defaults.mat');

switch nargin
    case 0
        % Transpose the resulting cell array to get a cell column vector as 
        % required by the ui boxes' extension/format filters
        vid_filter = cellfun(@(extension) ['*' extension], default.SUPPORTED_VID_EXTS, 'UniformOutput', false)';
        [input_file, input_dir] = uigetfile(vid_filter, 'Locate the video to convert to mp4');
        
        if ~input_file
            error('Operation canceled by user.')
        end

        [~, input_name, ~] = fileparts(input_file);
        input_vid = fullfile(input_dir, input_file);
    
        output_vid = uiputfile( ...
            ['*' default.VID_EXT], ...
            ['Choose path to place converted video (cancel = place converted file ' ...
            'in same directory with the same basename as input video)'], ...
            fullfile([input_name default.VID_EXT]) ...
        );
        if ~output_vid
            output_vid = fullfile(input_dir, [input_name default.VID_EXT]);
        end

    case 1
        [input_dir, input_name, input_ext] = fileparts(input_vid);
        input_vid = fullfile(input_dir, [input_name input_ext]);

        output_vid = uiputfile( ...
            ['*' default.VID_EXT], ...
            ['Choose path to place converted video (cancel = place converted file ' ...
            'in same directory with the same basename as input video)'], ...
            fullfile([input_name default.VID_EXT]) ...
        );
        if ~output_vid
            output_vid = fullfile(input_dir, [input_name default.VID_EXT]);
        end
end


if ~isfile(input_vid)
    error('Provided input video path is not a file or does not exist.\nProvided Path: %s', input_vid)
end

[~, input_name, ~] = fileparts(input_vid);

if isempty(output_vid)
    output_vid = [input_name default.VID_EXT];
end

% In case it's used as a function, it is possible the directories are
% relative and potentially non-existent.
[output_vid_dir, output_vid_base, output_vid_extension] = fileparts(output_vid);

if isempty(output_vid_extension)
    fprintf(['\n[BAD ARGUMENT] Expected a full path to a video file with extension, but the ' ...
        'extension is missing.\nUnclear if "%s" is a directory or file.\n'], output_vid ...
    )

    while true
        dir_or_file = input('[PROMPT] Consider it a (1) directory or (2) file? (enter 1 or 2): ');
        if ~ismember(dir_or_file, {1, 2})
            fprintf(['\n[BAD INPUT] Only "1" and "2" (w/o quotes) are accepted inputs. Please try ' ...
                'again.\n'] ...
            )
            continue
        end
        break
    end

    if dir_or_file == 1
        % Consider a directory, append filename to its end.
        output_vid = fullfile(output_vid, [input_name default.VID_EXT]);
    else
        % Consider a file, add extension.
        output_vid = [output_vid default.VID_EXT];
    end
end
    
% Path shenanigans to ensure intermediate directories exist, and create 
% them if they do not.
if ~isempty(output_vid_dir) && ~isempty(output_vid_base)
    % Path may or may not be relative and contains directories.
    if ~isfolder(output_vid_dir)
        mkdir(output_vid_dir)
        output_vid = fullfile(output_vid_dir, [output_vid_base output_vid_extension]);
    end

elseif isempty(output_vid_dir) && ~isempty(output_vid_base)
    % Path is relative and does not contain directories (i.e., just file).
    output_vid = fullfile(pwd, output_vid);

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

fprintf('Converting video to MP4...');

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
fprintf("done.\n\n\t%-15s: %s\n\t%-15s: %s\n\n", 'Source Video', abspath(input_vid), 'Converted Video', abspath(output_vid))

end