%% SETUP %%
%{
Mark the corresponding points on a set of at least 2 or at most 3 images
corresponding to a single camera and 2-mirror setup.
%}

default = load('defaults.mat');

img_filter = cellfun(@(extension) ['*' extension], default.SUPPORTED_IMG_EXTS, 'UniformOutput', false)';
[img_file, img_dir] = uigetfile( ...
    img_filter, ...
    'Locate the image containing the object you want to reconstruct' ...
);
if ~img_file
    error('Operation canceled by user.')
end
img_filepath = fullfile(img_dir, img_file);

% The no. of points to click.
while true
    num_points = input("[PROMPT] Enter the no. of points to mark: ");
    if num_points <= 0
        fprintf('[BAD INPUT] No. of marked points must be a positive integer > 0.')
        continue
    end
    break
end

while true
    num_views = input("[PROMPT] Enter the no. of views (min %d, max %d): ");
    if num_views < default.MIN_VIEWS || num_views > default.MAX_VIEWS
        fprintf('[BAD INPUT] Unsupported no. of views. Please try again.\n')
        continue
    end
    break
end

fprintf('\nBeginning to mark points...\n')
fprintf('\tNOTE: Press "q" to zoom in, "e" to zoom out, and "r" to reset zoom level.\n\tZooms are around cursor!\n')

x = [];
% For each input image (view)...
for j = 1 : num_views
    fprintf("\tView %d - Marking Points: ", j)

    % Load image and click points to estimate world coordinates of.
    img = imread(img_filepath);
    [img_height, img_width, ~] = size(img);

    figure(j, 'Units', 'normalized', 'Position', [0 0.15 0.8 0.8]);
    imshow(img); hold on;
    xlabel('x (pixel)'); ylabel('y (pixel)');

    if j == 1
        title(sprintf('View %d - Click any %d points (q = zoom in, e = zoom out, r = zoom reset)', j, num_points))
    else
        title(sprintf(['View %d - Click any %d corresponding points in mirrors ' ...
            '(q = zoom in, e = zoom out, r = zoom reset)'], j, num_points))
    end

    for i = 1 : num_points
        progress_msg = sprintf("%d/%d...", i, num_points);
        fprintf(progress_msg)
        num_chars = strlength(progress_msg);
        
        while true
            [x_click, y_click, button] = ginput(1);
            if isempty(button)
                break
            elseif button == 113  % q = zoom in
                % The axis manipulations focus in around cursor location.
                ax = axis; width = ax(2) - ax(1); height = ax(4) - ax(3);
                axis([x_click - width / 2, x_click + width / 2, ...
                    y_click - height / 2, y_click + height / 2] ...
                );
                zoom(2)
            elseif button == 101  % e = zoom out
                ax = axis; width = ax(2) - ax(1); height = ax(4) - ax(3);
                axis([x_click - width / 2, x_click + width / 2, ...
                    y_click - height / 2, y_click + height / 2] ...
                );
                zoom(1/2)
            elseif button == 114  % r = reset zoom
                ax = axis; width = img_width; height = img_height;
                axis([1, width, 1, height]);
                zoom reset
            else
                plot(x_click, y_click, 'r+', 'linewidth', 2, 'MarkerSize', 12);
                x = [x cat(2, x_click, y_click, 1)'];
                break
            end
        end

        if i < num_points
            for c = 1 : num_chars
                fprintf("\b")
            end
        end
    end
    fprintf("done.\n")
    hold off;
end

pause(1);

% Save to disk and cleanup.
[marks_file, marks_dir] = uiputfile( ...
    '*.mat', ...
    'Choose path to save the marked points to (cancel = use default location)', ...
    [default.MARKED_POINTS_BASE default.BCT_EXT] ...
);
if ~marks_file
    marks_filepath = fullfile(default.RECONSTRUCTION_DIR, default.MARKED_POINTS_BASE);
else
    marks_filepath = fullfile(marks_dir, marks_file);
end

save(marks_filepath, 'num_points', 'x')
close all
disp("All done! Check script directory for the results.")