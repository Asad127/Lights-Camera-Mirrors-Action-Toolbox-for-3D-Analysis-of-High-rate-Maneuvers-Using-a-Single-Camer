%{
THIS SCRIPT IS A STARTING POINT WHEN EXTENDING TO MORE THAN 3 VIEWS. At
that point, preserving the identity of each mirror would require the user
to cancel a lot of dialog boxes is a certain mirror is unused. In that
case, we can get rid of view labels and fix the camera to 1, and ANY mirror
view after tha would be 2, then any other could be 3, etc. Not sure if
we'll need this, ever.

MATLAB UI-based input. Only preliminary part may be configured with
defaults by leaving inputs blank.

This script merges the required variables, i.e., extrinsics, intrinsics, 
and distortion from each BCT calibration file (one per view) into one
.mat file. It also calculates the 11 DLT coefficients required by DLTdv8a
and puts them in the required CSV format.

FIRST INPUT IS ASSUMED THE CAMERA! This is important as permutation 
transform must be done only on mirror views. If not including the camera
view, enter blank when asked for calibration file for camera.

FUNCTIONS CALLED
===========================================================================
krt_to_dlt:
    Converts the provided KRT parameters (corresponding to a single view)
    into the 11 DLT coefficients required by DLTdv8a and returns them. 
%}

%% PRELIMINARY %%
defaults;  % script to load in the defined constants

logic_str = ["False", "True"];
fprintf('RELEVANT DEFAULT CONFIGURATIONS FOR BLANK COMMAND WINDOW INPUTS\n')
fprintf('======================================================================\n')
fprintf('Number of calibration files: %d\n', NUM_CALIB_FILES);
fprintf('Camera view present in files: %s\n', logic_str(CAMERA_VIEW_PRESENT + 1));
fprintf('Extrinsics reference image: %s\n', EXTRINSICS_REFERENCE_IMG_SUFFIX);
fprintf('======================================================================\n')
fprintf( ...
    ['Browse the calibration files for the camera and mirrors. A min-max ' ...
    'of 2 and 3 files are accepted.\nIt is expected that the first input ' ...
    'file is the calibration of the actual camera. If you have 2 views\nand ' ...
    'the camera view is not included, please specify when prompted. To use ' ...
    'default value for a command\nwindow input, leave it blank (just press ' ...
    'enter).\n'] ...
);

nocam_offset = 0;

% User prompts
while true
    if ~HIDE_PROMPT_HELP
        fprintf('\nHELP: Leave the following prompt blank to use default instead.\n')
    end
    num_files = input(['[PROMPT 1/2] Enter number of calibration files (views) ' ...
        'for your data: ']);
    if isempty(num_files)
        num_files = NUM_CALIB_FILES;
    end
    if num_files < MIN_VIEWS || num_files > MAX_VIEWS
        fprintf(['Please provide exactly 2 or 3 files corresponding to 2 or 3 ' ...
            'views and try again.\n'])
        continue
    end 
    break
end

while true
    if num_files < MAX_VIEWS
        if ~HIDE_PROMPT_HELP
            fprintf('\tHELP: Leave the following prompt blank to use default instead.\n\t')
        end
        has_camera = input(['[TWO-VIEW CAM PROMPT] Does your project involve the ' ...
            'camera view? (1 or [] = yes, other = no): ']);
        if isempty(has_camera)
            has_camera = CAMERA_VIEW_PRESENT;
        end
        if ~logical(has_camera)
            nocam_offset = 1;
        end
    end
    break
end

while true
    if ~HIDE_PROMPT_HELP
        fprintf(['\nHELP: Leave the following prompt blank to use default instead. ' ...
            'The entered value should be numeric if\nimage is part of calibration ' ...
            'set, and "ext" (w/o quotes) if reference extrinsics were computed on a\n' ...
            'separate image via Compute Extrinsic function of BCT.\n'])
    end
    extrinsics_reference_img_suffix = input(['[PROMPT 2/2] Enter calibration ' ...
        'image suffix to use as world reference image for extrinsics: '], 's');
    
    if isempty(extrinsics_reference_img_suffix)
        extrinsics_reference_img_suffix = EXTRINSICS_REFERENCE_IMG_SUFFIX;
    end

    if extrinsics_reference_img_suffix ~= "ext"
        if isnan(str2double(extrinsics_reference_img_suffix))
            fprintf(['Extrinsics reference suffix contains non-numeric characters. ' ...
                'Ensure it is numeric-convertible or "ext" and try again.\n'])
            continue
        end
    end
    break
end

%% MAIN %%

% We fill two consecutive rows of an array corresponding to the calibration 
% params and the fieldnames corresponding to the current file number. Idea 
% is to column-major flattern them into a comma separated value list with 
% arr{:} to save necessary values. This array should contain only the
% params unique to each view.
merged_bct = cell(num_files * 2, NUM_UNIQUE_VARS_PER_CAM);  

dlts = zeros(11, num_files);  % for 11 DLT coefficients against each input file
history_received_files = strings(1, num_files);  % for duplicate check
total_prompts = num_files + 2;  % +2 since we have 2 prompts after the calibration files
prompt_num = 1;  % UI prompt number, not command window

viewnames = {
    [BCT_CAM_CALIB_BASENAME BCT_EXTENSION] ...
    [sprintf(BCT_MIR_CALIB_BASENAME, 1) BCT_EXTENSION] ... 
    [sprintf(BCT_MIR_CALIB_BASENAME, 2) BCT_EXTENSION]
};

for k = 1 + nocam_offset : num_files + nocam_offset
    if k == 1
        prompt = sprintf(['PROMPT %s/%s: Select BCT camera calibration results ' ...
            'file'], prompt_num, total_prompts);
    else
        prompt = sprintf(['PROMPT %s/%s: Select BCT mirror %d calibration ' ...
            'results file'], prompt_num, total_prompts, k-1);
    end
    
    defname = viewnames(k);

    % Get file and check if duplicate.
    while true
        [file, path] = uigetfile(['*' BCT_EXTENSION], prompt, defname);

        if ~file
            if k == 1
                calib_file = BCT_CAM_CALIB_PATH;
            else
                calib_file = sprintf(BCT_MIR_CALIB_PATH, k-1);
            end
        else
            calib_file = fullfile(path, file);
        end
        
        % Duplicate file check
        if ismember(calib_file, history_received_files)
            fprintf(['Duplicate calibration filepath encountered. Please make ' ...
                'sure each calibration file is distinct and try again.\n']);
            continue
        end
        break
    end
    
    calib = load(calib_file);
    
    % Do not replace the ellipses with commas, that will make it a cell
    % column vector instead of a row vector, which is significant in this
    % case as we rely on the column-major reshape to save the relevant params.

    % These are the fieldnames in the saved file. They are numbered
    % according to the current view/file.
    fields_save = {
        sprintf('CF_%d', k)...  % calib file
        sprintf('KK_%d', k)...  % intrinsics
        sprintf('kc_%d', k)...  % distortion
        sprintf('Rc_%d', k)...  % rotation mtx
        sprintf('Tc_%d', k)     % translation vec
    };
    
    % Performing permutation for mirror views in this script ensures 
    % we don't need to mess around in any other script. See `defaults` 
    % and `reconstruct_3d_from_trackfile_dltdv8a.m` for more details.
    if k == 1
        values_calib = {
            calib_file...
            calib.KK...
            calib.kc...
            calib.(sprintf('Rc_%s', extrinsics_reference_img_suffix))...
            calib.(sprintf('Tc_%s', extrinsics_reference_img_suffix))
        };
    else
        values_calib = {
            calib_file...
            calib.KK...
            calib.kc...
            calib.(sprintf('Rc_%s', extrinsics_reference_img_suffix)) * PERM_TRANSFORM...
            calib.(sprintf('Tc_%s', extrinsics_reference_img_suffix))
        };
    end

    % Fill two consecutive rows.
    start_row_idx = (k - nocam_offset) * 2 - 1;
    end_row_idx = start_row_idx + 1;
    merged_bct(start_row_idx : end_row_idx, :) = [fields_save; values_calib];

    % Calculate DLT.
    dlt = krt_to_dlt(values_calib{2}, values_calib{4}, values_calib{5});
    dlts(:, k - nocam_offset) = dlt;

    % Update history of received files.
    history_received_files(1, k - nocam_offset) = calib_file;
    prompt_num = prompt_num + 1;
end

% Saving the unique view parameters for each view/file into the struct.
merged_struct = struct(merged_bct{:});

% Saving the shared parameter to the struct as well.
merged_struct.('ext_ref_suffix') = extrinsics_reference_img_suffix;

% Save the results to files.
[file, path] = uiputfile(['*' BCT_EXTENSION], sprintf(['PROMPT %s/%s: Choose ' ...
    'path to save the merged BCT calibration parameters to'], prompt_num, ...
    total_prompts), [BCT_MERGED_CALIB_BASENAME BCT_EXTENSION]);
if ~file
    saveloc_bct = BCT_MERGED_CALIB_PATH;
else
    saveloc_bct = fullfile(path, file);
end
prompt_num = prompt_num + 1;

[file, path] = uiputfile(['*' DLTDV_EXTENSION], sprintf(['PROMPT %s/%s: Choose ' ...
    'path to save the 11 DLT coefficients to (for DLTdv8a)'], prompt_num, ...
    total_prompts), [DLT_COEFS_BASENAME DLTDV_EXTENSION]);
if ~file
    saveloc_dlt = DLT_COEFS_PATH;
else
    saveloc_dlt = fullfile(path, file);
end
prompt_num = prompt_num + 1;

fprintf('\nGenerating files...\n')
save(saveloc_bct, '-struct', 'merged_struct')
writematrix(dlts, saveloc_dlt, 'Delimiter', ',')
fprintf('\tMerged BCT params saved to: "%s"\n\tDLT coefficients saved to: "%s"\n', ...
    saveloc_bct, saveloc_dlt);
fprintf(['All done! You may now consider undistorting the test video frames via script' ...
    '`undistort_video.m` BEFORE running DLTdv8a.\n'])