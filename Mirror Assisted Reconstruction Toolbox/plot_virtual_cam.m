function plot_virtual_cam(R_cam, T_cam)
%{
Plot a virtual camera (mirror view) on current axis. These have a -ve
determinant, and rigidtform3d requires +ve determinants, requiring us to
write our own function for these views.

This creates a camera-like frustum similar to plotCamera but for mirror views.

TAKES
=====
R_cam:
    3x3 rotation matrix, specified such that it takes the world points to
    the camera coordinate system.
T_cam:
    3x1 translation vector, specified such that its coordinates are
    defined in the camera coordinate system, with the tail at the camera
    center and the head at the world origin.

%}

% Get camera position and orientation w.r.t. the world frame.
R_world = inv(R_cam);
T_world = -R_world * T_cam;

% Camera frustum parameters (matching plotCamera size).
% plotCamera uses Size=30, so we'll use similar dimensions.
frustum_size = 60;
frustum_length = frustum_size * 0.8;

% Create camera frustum vertices in camera coordinates.
% Camera frustum is a truncated pyramid pointing in -Z direction.
% Use much larger dimensions to match plotCamera size better.
frustum_width = frustum_size * 1.2;  % Increased significantly from 0.8
frustum_height = frustum_size * 1.0; % Increased significantly from 0.6

% Back face (wider) of frustum.
back_vertices = [
    -frustum_width/2, -frustum_height/2, 0;
    frustum_width/2, -frustum_height/2, 0;
    frustum_width/2, frustum_height/2, 0;
    -frustum_width/2, frustum_height/2, 0;
];

% Front face (narrower) of frustum.
front_vertices = [
    -frustum_width/3, -frustum_height/3, -frustum_length;
    frustum_width/3, -frustum_height/3, -frustum_length;
    frustum_width/3, frustum_height/3, -frustum_length;
    -frustum_width/3, frustum_height/3, -frustum_length;
];

% Camera body cuboid (behind the frustum).
% This represents the camera body like in plotCamera.
% For virtual cameras, the body is in the opposite direction from the frustum.
cuboid_depth = frustum_size * 0.8; % Increased depth to extend further back

% Front face of cuboid (connects to frustum tail).
% Use the tail face vertices of the frustum as the front face of the cuboid.
cuboid_front_vertices = front_vertices; % This is the frustum's tail (narrower face)

% Back face of cuboid (farthest from frustum).
% Extend the cuboid back by the depth amount.
cuboid_back_vertices = [
    front_vertices(1, 1), front_vertices(1, 2), front_vertices(1, 3) - cuboid_depth;
    front_vertices(2, 1), front_vertices(2, 2), front_vertices(2, 3) - cuboid_depth;
    front_vertices(3, 1), front_vertices(3, 2), front_vertices(3, 3) - cuboid_depth;
    front_vertices(4, 1), front_vertices(4, 2), front_vertices(4, 3) - cuboid_depth;
];

% Transform vertices to world coordinates.
all_vertices = [back_vertices; front_vertices; cuboid_back_vertices; cuboid_front_vertices];
num_vertices = size(all_vertices, 1);

% Transform each vertex to world coordinates.
world_vertices = zeros(num_vertices, 3);
for i = 1:num_vertices
    vertex_cam = all_vertices(i, :)';
    vertex_world = R_world * vertex_cam + T_world;
    world_vertices(i, :) = vertex_world';
end

% Separate vertices for different parts.
back_world = world_vertices(1:4, :);
front_world = world_vertices(5:8, :);
cuboid_back_world = world_vertices(9:12, :);
cuboid_front_world = world_vertices(13:16, :);

% Draw the camera frustum.
% Back face (wider).
patch(back_world(:, 1), back_world(:, 2), back_world(:, 3), ...
    'blue', 'FaceAlpha', 0.1, 'EdgeColor', 'blue', 'LineWidth', 1);

% Front face (narrower).
patch(front_world(:, 1), front_world(:, 2), front_world(:, 3), ...
    'blue', 'FaceAlpha', 0.1, 'EdgeColor', 'blue', 'LineWidth', 1);

% Connect back and front faces.
for i = 1:4
    line([back_world(i, 1), front_world(i, 1)], ...
         [back_world(i, 2), front_world(i, 2)], ...
         [back_world(i, 3), front_world(i, 3)], ...
         'Color', 'blue', 'LineWidth', 1);
end

% Draw the camera body cuboid.
% Back face of cuboid.
patch(cuboid_back_world(:, 1), cuboid_back_world(:, 2), cuboid_back_world(:, 3), ...
    'blue', 'FaceAlpha', 0.1, 'EdgeColor', 'blue', 'LineWidth', 1);

% Front face of cuboid (connects to frustum).
patch(cuboid_front_world(:, 1), cuboid_front_world(:, 2), cuboid_front_world(:, 3), ...
    'blue', 'FaceAlpha', 0.1, 'EdgeColor', 'blue', 'LineWidth', 1);

% Connect cuboid faces.
for i = 1:4
    line([cuboid_back_world(i, 1), cuboid_front_world(i, 1)], ...
         [cuboid_back_world(i, 2), cuboid_front_world(i, 2)], ...
         [cuboid_back_world(i, 3), cuboid_front_world(i, 3)], ...
         'Color', 'blue', 'LineWidth', 1);
end

% Draw camera axes at the center of the cuboid.
% Calculate the center of the cuboid in camera coordinates, then transform to world coordinates.
cuboid_center_cam_x = mean([cuboid_front_vertices(:, 1); cuboid_back_vertices(:, 1)]);
cuboid_center_cam_y = mean([cuboid_front_vertices(:, 2); cuboid_back_vertices(:, 2)]);
cuboid_center_cam_z = mean([cuboid_front_vertices(:, 3); cuboid_back_vertices(:, 3)]);
cuboid_center_cam = [cuboid_center_cam_x, cuboid_center_cam_y, cuboid_center_cam_z];

% Transform cuboid center to world coordinates.
cuboid_center_world = R_world * cuboid_center_cam' + T_world;
cuboid_center = cuboid_center_world';

axis_length = frustum_size * 1.0; % Increased significantly from 0.7 to make axes more visible

% X-axis (black with Xc label).
quiver3(cuboid_center(1), cuboid_center(2), cuboid_center(3), ...
    R_world(1,1), R_world(2,1), R_world(3,1), ...
    axis_length, ...
    "k", ...
    "LineWidth", 1, ...
    "HandleVisibility", "off" ...
);
text(cuboid_center(1) + R_world(1,1) * axis_length * 1.1, ...
     cuboid_center(2) + R_world(2,1) * axis_length * 1.1, ...
     cuboid_center(3) + R_world(3,1) * axis_length * 1.1, ...
     'X_c', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'black');

% Y-axis (black with Yc label).
quiver3(cuboid_center(1), cuboid_center(2), cuboid_center(3), ...
    R_world(1,2), R_world(2,2), R_world(3,2), ...
    axis_length, ...
    "k", ...
    "LineWidth", 1, ...
    "HandleVisibility", "off" ...
);
text(cuboid_center(1) + R_world(1,2) * axis_length * 1.1, ...
     cuboid_center(2) + R_world(2,2) * axis_length * 1.1, ...
     cuboid_center(3) + R_world(3,2) * axis_length * 1.1, ...
     'Y_c', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'black');

% Z-axis (black with Zc label).
quiver3(cuboid_center(1), cuboid_center(2), cuboid_center(3), ...
    R_world(1,3), R_world(2,3), R_world(3,3), ...
    axis_length, ...
    "k", ...
    "LineWidth", 1, ...
    "HandleVisibility", "off" ...
);
text(cuboid_center(1) + R_world(1,3) * axis_length * 1.1, ...
     cuboid_center(2) + R_world(2,3) * axis_length * 1.1, ...
     cuboid_center(3) + R_world(3,3) * axis_length * 1.1, ...
     'Z_c', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'black');

% Add camera label in the direction of the Y-axis, below the camera.
% Use the Y-axis direction from the camera center, plus negative X-axis direction.
label_distance = axis_length * 0.8; % Distance below the camera
label_x = cuboid_center(1) + R_world(1,2) * label_distance - R_world(1,1) * label_distance;
label_y = cuboid_center(2) + R_world(2,2) * label_distance - R_world(2,1) * label_distance;
label_z = cuboid_center(3) + R_world(3,2) * label_distance - R_world(3,1) * label_distance;

text(label_x, label_y, label_z, ...
    'M', 'FontSize', 12, ...
    'HorizontalAlignment', 'center', 'Color', 'blue');

end
