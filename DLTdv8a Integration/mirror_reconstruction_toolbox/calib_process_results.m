%{
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

default = load('defaults.mat');

fprintf( ...
    ['Enter paths to the calibration files for the camera and mirrors. A min-max of 2 and 3 files ' ...
    'are accepted.\nIt is expected that the first input file is the calibration of the actual ' ...
    'camera. To discard a view, leave\nthe corresponding input for the calibration file blank.\n'] ...
)

while true
    if ~default.HIDE_PROMPT_HELP
        fprintf(['\nHELP: The entered value should be numeric if image is part of calibration set, ' ...
            'and "ext" (w/o quotes)\nif reference extrinsics were computed on a separate image via ' ...
            'Compute Extrinsic function of BCT.\n'] ...
        )
    end
    extrinsics_reference_img_suffix = input(['[PROMPT] Enter calibration image suffix to use ' ...
        'as world reference image for extrinsics (blank = default): '], 's' ...
    );
    
    if isempty(extrinsics_reference_img_suffix)
        extrinsics_reference_img_suffix = default.EXTRINSICS_REFERENCE_IMG_SUFFIX;
    end

    % See if the input is "ext" for extrinsics from a non-calibration image
    % reference (Compute Extrinsic function of BCT). If that is not the 
    % case, then the input should be convertible to numeric.
    if extrinsics_reference_img_suffix ~= "ext"
        if isnan(str2double(extrinsics_reference_img_suffix))
            fprintf(['Extrinsics reference suffix contains non-numeric characters. Ensure it is ' ...
                'numeric-convertible or "ext" and try again.\n'] ...
            )
            continue
        end
    end
    break
end

%% MAIN %%

% Get the paths to the calibration files for the camera and mirrors. If the
% useer enters a blank, that view is discarded. However, at least two
% filepaths must be entered.

calib_files = {};
view_labels = [];
ui_prompt_count = 1;
ui_total_prompts = default.MAX_VIEWS + 2;  % +2 as we have two prompts after the 3 calibration inputs

for k = 1 : default.MAX_VIEWS
    skip_this_view = false;
    while true 
        % Camera view
        if k == 1
            [file, dir] = uigetfile( ...
                ['*' default.BCT_EXT], ...
                sprintf(['PROMPT %d/%d: Select BCT camera calibration results file (cancel = skip ' ...
                'this view): '], ui_prompt_count, ui_total_prompts), ...
                default.BCT_CALIB_DIR ...
            );
            
            if ~file
                skip_this_view = true;
                break
            end

            calib_file = fullfile(dir, file);
                        
            % Check if file exists.
            if ~isfile(calib_file)
                fprintf('File "%s" does not exist. Double-check path and try again.\n', calib_file)
                continue
            end

        % Mirror view(s)
        else
            [file, dir] = uigetfile( ...
                ['*' default.BCT_EXT], ...
                sprintf(['PROMPT %d/%d: Select BCT mirror %d calibration results file (cancel = ' ...
                'skip this view): '], ui_prompt_count, ui_total_prompts, k - 1), ...
                default.BCT_CALIB_DIR ...
            );

            if ~file
                skip_this_view = true;
                break
            end

            calib_file = fullfile(dir, file);

            % Check if file exists.
            if ~isfile(calib_file)
                fprintf('File "%s" does not exist. Double-check path and try again.\n', calib_file)
                continue
            end
        end
        
        % Duplicate file check
        if ismember(calib_file, calib_files)
            fprintf(['Duplicate calibration filepath encountered. Please make sure each calibration ' ...
                'file is distinct and try again.\n'] ...
            )
            continue
        end    
        break
    end
    
    ui_prompt_count = ui_prompt_count + 1;
    
    % If user canceled, skip the file (leave corresponding cell empty)
    if skip_this_view
        continue
    end

    % Assume user has a naming convention for views, and preserve the
    % current view number as the view label.
    view_labels(end + 1) = k;

    % Fill the k'th cell with the path to the file.
    calib_files{end + 1} = calib_file;
end

num_views = numel(calib_files);  % or view_labels, both have same dimensions

if num_views < default.MIN_VIEWS || num_views > default.MAX_VIEWS
    error(['Number of views (selected files: %d) disagrees with the maximum and minimum number of views.\n' ...
        'A minimum of %d and a maximum of %d views are currently accepted.'], ...
        num_views, default.MIN_VIEWS, default.MAX_VIEWS ...
    )
end

% Fill two consecutive rows of an array corresponding to the calibration 
% params and the fieldnames corresponding to the current file number. Idea 
% is to column-major flattern them into a comma separated value list with 
% arr{:} to save necessary values. This array should contain only the
% params unique to each view (i.e., not the shared parameter.
merged_bct = cell(num_views * 2, default.NUM_UNIQUE_VARS_PER_CAM); 

% 11 DLT coefficients against each input file.
dlts = zeros(11, num_views);

% Another loop, but this time we actually load in the filepaths.
for j = 1 : num_views

    k = view_labels(j);  % j doesn't preserve view identity, k does

    calib_file = calib_files{j};
    view_params = load(calib_file);

    % These are the fieldnames in the saved file. They are numbered
    % according to the current view/file.
    fields_save = {
        sprintf('CF_%d', k) ...  % calib file
        sprintf('kc_%d', k) ...  % distortion
        sprintf('KK_%d', k) ...  % intrinsics
        sprintf('Rc_%d', k) ...  % rotation mtx
        sprintf('Tc_%d', k)      % translation vec
    };
    
    % Performing permutation for mirror views in this script ensures 
    % we don't need to mess around in any other script. See `defaults.m` 
    % and `reconstruct_tracked_pts_dltdv8a.m` for more details.
    if k == 1
        values_calib = {
            calib_file ...
            view_params.kc ...
            view_params.KK ...
            view_params.(sprintf('Rc_%s', extrinsics_reference_img_suffix)) ...
            view_params.(sprintf('Tc_%s', extrinsics_reference_img_suffix))
        };
    else
        values_calib = {
            calib_file ...
            view_params.kc ...
            view_params.KK ...
            view_params.(sprintf('Rc_%s', extrinsics_reference_img_suffix)) * default.PERM_TRANSFORM ...
            view_params.(sprintf('Tc_%s', extrinsics_reference_img_suffix))
        };
    end
    
    start_row_idx = j * 2 - 1;        % j * 2 -1
    end_row_idx = start_row_idx + 1;  % j * 2

    % Per iteration, first row = fields, second row = values.
    merged_bct(start_row_idx : end_row_idx, :) = [fields_save; values_calib];

    % Calculate DLT.
    dlt = krt_to_dlt(values_calib{3}, values_calib{4}, values_calib{5});
    dlts(:, j) = dlt;
    
end

% Saving the unique view parameters for each view/file into the struct.
merged_struct = struct(merged_bct{:});

% Saving the shared parameter to the struct as well.
merged_struct.('ext_ref_suffix') = extrinsics_reference_img_suffix;
merged_struct.('view_labels') = view_labels;

% Save the results to files.
[file, path] = uiputfile( ...
    ['*' default.BCT_EXT], ...
    sprintf(['PROMPT %d/%d: Choose path to save merged BCT calibration parameters to (cancel = use ' ...
    'default path): '], ui_prompt_count, ui_total_prompts), ...
    [default.BCT_MERGED_CALIB_BASE default.BCT_EXT] ...
);

if ~file
    saveloc_bct = default.BCT_MERGED_CALIB_PATH;
else
    saveloc_bct = fullfile(path, file);
end

ui_prompt_count = ui_prompt_count + 1;

[file, path] = uiputfile( ...
    ['*' default.DLTDV_EXT], ...
    sprintf(['PROMPT %d/%d: Choose path to save 11 DLT coefficients for DLTdv8a to (cancel = use ' ...
    'default path): '], ui_prompt_count, ui_total_prompts), ...
    [default.DLT_COEFS_BASE default.DLTDV_EXT] ...
);

if ~file
    saveloc_dlt = default.DLT_COEFS_PATH;
else
    saveloc_dlt = fullfile(path, file);
end

ui_prompt_count = ui_prompt_count + 1;

fprintf('\nGenerating files...\n')
save(saveloc_bct, '-struct', 'merged_struct')
writematrix(dlts, saveloc_dlt, 'Delimiter', ',')
fprintf('\tMerged BCT params saved to: "%s"\n\tDLT coefficients saved to: "%s"\n', saveloc_bct, saveloc_dlt);
fprintf(['All done! You may now consider undistorting the test video frames via script ' ...
    '`create_undistorted_vid_and_frames.m`\nBEFORE running DLTDV8a.\n'])