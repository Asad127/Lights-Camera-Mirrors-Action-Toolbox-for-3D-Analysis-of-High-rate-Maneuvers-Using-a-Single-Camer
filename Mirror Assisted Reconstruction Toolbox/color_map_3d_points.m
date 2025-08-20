function color_map_3d_points(points, start_idx, stop_idx, colormap_name, plot_colorbar)
    % COLOR_MAP_POINTS Maps 3D points to a colormap and plots them.
    % Inputs:
    %   points        - Nx3 or 3xN numeric array, or Nx1 cell array with 3x1 vectors
    %   start_idx     - Starting index (inclusive)
    %   stop_idx      - Stopping index (inclusive)
    %   colormap_name - String specifying the colormap (e.g., 'jet', 'hot')
    
    % Input validation and conversion
    if nargin < 4
        colormap_name = 'cool';  % default colormap
        plot_colorbar = false;
    elseif nargin < 5
        plot_colorbar = false;
    end
    if isempty(points)
        error('Input points cannot be empty.');
    end
    
    % Convert input to Nx3 matrix.
    if iscell(points)
        if size(points, 2) ~= 1
            error('Cell array input must be Nx1.');
        end
        num_points = length(points);
        if start_idx < 1 || stop_idx > num_points || start_idx > stop_idx
            error('Invalid start or stop index for cell array.');
        end
        selected_points = zeros(stop_idx - start_idx + 1, 3);
        for i = 1:(stop_idx - start_idx + 1)
            pt = points{start_idx + i - 1};
            if ~isnumeric(pt) || length(pt) ~= 3
                error('Each cell must contain a 3x1 numeric vector.');
            end
            selected_points(i, :) = pt';
        end
    else
        if ~isnumeric(points)
            error('Numeric array input must be a matrix.');
        end
        [rows, cols] = size(points);
        if (rows ~= 3 && cols ~= 3) || (rows * cols < 6)
            error('Numeric array must be Nx3 or 3xN with at least 2 points.');
        end
        if rows == 3
            selected_points = points';  % transpose 3xN to Nx3
        else
            selected_points = points;  % already Nx3
        end
        num_points = size(selected_points, 1);
        if start_idx < 1 || stop_idx > num_points || start_idx > stop_idx
            error('Invalid start or stop index for numeric array.');
        end
        selected_points = selected_points(start_idx:stop_idx, :);
    end
    
    % Generate colormap for intermediate points.
    cmap = colormap(colormap_name);
    cmap_size = size(cmap, 1);
    
    % Create figure.
    figure;
    hold on;
    
    % Plot start point (blue cross).
    scatter3(selected_points(1, 1), selected_points(1, 2), selected_points(1, 3), ...
        50, 'b', 'x', 'LineWidth', 2);
    
    % Plot intermediate points (colormapped filled circles), if any.
    if size(selected_points, 1) > 2
        intermediate_points = selected_points(2:end-1, :);
        num_intermediate = size(intermediate_points, 1);
        color_indices = linspace(1, cmap_size, num_intermediate);
        colors = interp1(1:cmap_size, cmap, color_indices);
        scatter3(intermediate_points(:, 1), intermediate_points(:, 2), intermediate_points(:, 3), ...
            50, colors, 'filled', 'Marker', 'o');
    end
    
    % Plot end point (red cross).
    scatter3(selected_points(end, 1), selected_points(end, 2), selected_points(end, 3), ...
        50, 'r', 'x', 'LineWidth', 2, 'MarkerFaceColor', 'r');
    
    % Add labels and title.
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    title(['3D Points with ', colormap_name, ' Colormap']);
    
    % Add colorbar (only if there are intermediate points).
    if plot_colorbar && size(selected_points, 1) > 2
        colorbar;
    end
    grid on;
    axis equal;
    hold off;
end