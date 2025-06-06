% This script processes all approaches in the MDE directory, computes metric depth maps for each image, and saves
% a .mat file per view (e.g., metric_depth_depth_anything_v2_cam_rect.mat) containing metric depth maps for that view.

% Set the root directory for MDE.
MDE_ROOT = fullfile('..', 'Data', 'MDE');

% Get a list of all approaches.
approach_dirs = dir(MDE_ROOT);
approach_dirs = approach_dirs([approach_dirs.isdir] & ~startsWith({approach_dirs.name}, '.'));

for a = 1 : length(approach_dirs)
    approach_name = approach_dirs(a).name;
    approach_path = fullfile(MDE_ROOT, approach_name);

    % Find all views in this approach.
    view_dirs = dir(approach_path);
    view_dirs = view_dirs([view_dirs.isdir] & ~startsWith({view_dirs.name}, '.'));

    for v = 1 : length(view_dirs)
        view_name = view_dirs(v).name;
        view_path = fullfile(approach_path, view_name);
        depth_dir = fullfile(view_path, 'depth');
        depth_scale_path = fullfile(view_path, 'depth_scales.json');
        % Get all scaled depth images in this view.
        depth_images = dir(fullfile(depth_dir, 'img*.png'));
        % Load the depth scales JSON and convert to containers.Map.
        fid = fopen(depth_scale_path, 'r');
        raw = fread(fid, inf);
        str = char(raw');
        fclose(fid);
        json_data = jsondecode(str);
        % Convert JSON struct to containers.Map to preserve original keys.
        depth_scales = containers.Map(fieldnames(json_data), struct2cell(json_data));
        % Debug: Print Map keys.
        fprintf('Map keys for view %s:\n', view_name);
        disp(keys(depth_scales));
        % Initialize struct for metric depth maps for this view.
        view_metric_depth_struct = struct();
        % Loop over all scaled depth images in this view.
        for d = 1 : length(depth_images)
            % Get the base name of the depth image.
            [~, image_base, ~] = fileparts(depth_images(d).name);
            % Form JSON key to match depth_scales.json (e.g., 'img1').
            json_key = image_base;
            % Debug: Print file name and JSON key.
            fprintf('Processing file: %s, json_key: %s\n', depth_images(d).name, json_key);
            % Check if JSON key exists.
            if isKey(depth_scales, json_key)
                depth_scale = depth_scales(json_key);
            else
                error('JSON key %s not found in depth_scales Map', json_key);
            end
            % Read the depth image.
            depth_image_path = fullfile(depth_dir, depth_images(d).name);
            depth_image = double(imread(depth_image_path));
            % Compute metric depth.
            metric_depth = depth_image ./ depth_scale;
            % Store in view-specific struct.
            view_metric_depth_struct.(image_base) = metric_depth;
        end

        % Save metric depth maps for this view.
        view_matfile_name = sprintf('metric_depth.mat');
        save(fullfile(view_path, view_matfile_name), '-struct', 'view_metric_depth_struct');
    end
end