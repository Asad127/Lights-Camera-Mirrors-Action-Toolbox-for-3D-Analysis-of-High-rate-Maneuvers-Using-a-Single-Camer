% To test: https://www.mathworks.com/matlabcentral/fileexchange/26186-absolute-orientation-horn-s-method
% Conclusion: Assumes non-permutation transforms - doesn't work too well with reflections. I made a custom version in
% register_points_3d_horn.m that should tackle those scenarios.

set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultAxesFontSize', 12);
set(groot, 'defaultfigurecolor', [1 1 1]);

points_query = [
    [0.3745, 0.0206, 0.6119];
    [0.9507, 0.9699, 0.1395];
    [0.7320, 0.8324, 0.2921];
    [0.5987, 0.2123, 0.3664];
    [0.1560, 0.1818, 0.4561];
    [0.1560, 0.1834, 0.7852];
    [0.0581, 0.3042, 0.1997];
    [0.8662, 0.5248, 0.5142];
    [0.6011, 0.4319, 0.5924];
    [0.7081, 0.2912, 0.0465];
]';
%
% % Nx3 point array.
% % This data achieved with s = 2.0, T = [1, 2, 3], R = [0 1 0; -1 0 0; 0 0 1] + Gaussian Noise (0, 0.05) at rng(42)
% points_target = [
%     [1.0614, 1.1852, 4.3310];
%     [2.8919, 0.0975, 3.3190];
%     [2.6486, 0.4920, 3.6441];
%     [1.5486, 0.8581, 3.8376];
%     [1.4406, 1.6648, 3.9315];
%     [1.4082, 1.7212, 4.6226];
%     [1.6005, 1.8573, 3.3308];
%     [2.0066, 0.2697, 3.9805];
%     [1.8838, 0.8055, 4.0514];
%     [1.5712, 0.5678, 3.0528];
% ]';

% Randomly generate 3D sample points.
rng(42);
% points_query = rand(3, 10);

% Define the transformation.
rotation_matrix = [0, 1, 0; 1, 0, 0; 0, 0, 1];
scale_factor = 2.0;
translation = [1; 2; 3];

% Apply the transformation.
points_target = scale_factor * (rotation_matrix * points_query) + translation;

% Add some Gaussian noise to the points.
points_target = points_target + normrnd(0, 0.05, [3, 10]);

fprintf('Original point set:\n');
for i = 1:size(points_query, 1)
    fprintf('Point %2d: [%.4f, %.4f, %.4f]\n', i, points_query(1, i), points_query(2, i), points_query(3, i));
end

fprintf('\nTransformed point set:\n');
for i = 1:size(points_target, 1)
    fprintf('Point %2d: [%.4f, %.4f, %.4f]\n', i, points_target(1, i), points_target(2, i), points_target(3, i));
end

% Perform the horn registration.
[registeration_params, registered_query_points, error_stats] = absor( ...
    points_query, points_target, 'doScale', true, 'doTrans', true ...
);
disp(error_stats)

% Create a new figure.
figure;

% Plot the original (query) points.
scatter3( ...
    points_query(1,:), points_query(2,:), points_query(3,:), ...
    'bo', 'filled', 'DisplayName', 'Original Points (points1)' ...
);
hold on;

% Plot the target (transformed from query) points.
scatter3( ...
    points_target(1,:), points_target(2,:), points_target(3,:), ...
    'ro', 'filled', 'DisplayName', 'Transformed Points (points2)' ...
);

% Plot the registered (query -> target) points.
scatter3( ...
    registered_query_points(1,:), registered_query_points(2,:), registered_query_points(3,:), ...
    'go', 'DisplayName', 'Registered Points (Bfit)' ...
);

% Add lines between corresponding query and registered points, as well as query and target points.
for i = 1:size(points_query, 2)
    plot3( ...
        [points_query(1,i), registered_query_points(1,i)], ...
        [points_query(2,i), registered_query_points(2,i)], ...
        [points_query(3,i), registered_query_points(3,i)], ...
        'k--', ...
        'HandleVisibility', 'off', ...
        'Color', [0 0 0 0.3] ...
    );
    plot3( ...
        [points_query(1,i), points_target(1,i)], ...
        [points_query(2,i), points_target(2,i)], ...
        [points_query(3,i), points_target(3,i)], ...
        'HandleVisibility', 'off', ...
        'Color', [1 0 1 0.3] ...
    );
end

title('3D Point Sets: Original, Transformed, and Registered');
xlabel('X');
ylabel('Y');
zlabel('Z');
grid on;
legend('show');
axis equal;
hold off;