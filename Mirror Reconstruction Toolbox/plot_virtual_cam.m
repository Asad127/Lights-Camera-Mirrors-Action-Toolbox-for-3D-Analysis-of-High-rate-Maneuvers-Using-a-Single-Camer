function plot_virtual_cam(R_cam, T_cam)
%{
Plot a virtual camera (mirror view) on current axis. These have a -ve 
determinant, and rigidtform3d requires +ve determinants, requiring us to 
write our own function for these views.

This obviously does not use plotCamera, and just plots the camera axes (for
now, maybe more fancy later).

red = x, green = y, blue = z axes.

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

% Scale the drawn quivers representing the axes.
size = 50;

% LET THE PLOTTING COMMENCE... said I, as I drew some measly axes :)

% Camera X-axis orientation plot at the camera center in the world.
quiver3(T_world(1), T_world(2), T_world(3), ...
    R_world(1,1), R_world(2,1), R_world(3,1), ...
    size, ...
    "r", ...
    "LineWidth", 4, ...
    "HandleVisibility", "off" ...
);
% text(T_world(1), T_world(2), T_world(3), "X", "FontSize", 14)

% Camera Y-axis orientation plot at the camera center in the world.
quiver3(T_world(1), T_world(2), T_world(3), ...
    R_world(1,2), R_world(2,2), R_world(3,2), ...
    size, ...
    "g", ...
    "LineWidth", 4, ...
    "HandleVisibility", "off" ...
);
% text(T_world(1), T_world(2), T_world(3), "Y", "FontSize", 14)

% Camera Z-axis orientation plot at the camera center in the world.
quiver3(T_world(1), T_world(2), T_world(3), ...
    R_world(1,3), R_world(2,3), R_world(3,3), ...
    size, ...
    "b", ...
    "LineWidth", 4, ...
    "HandleVisibility", "off" ...
);
% text(T_world(1), T_world(2), T_world(3), "Z", "FontSize", 14)

end

