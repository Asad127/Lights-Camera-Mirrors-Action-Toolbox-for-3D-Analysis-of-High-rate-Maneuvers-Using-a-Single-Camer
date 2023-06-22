function plot_cam(R_cam, T_cam, size, color, label, axes_visible, opacity)
%{
Plot the original camera in the 3D view specified by the current axis.
Uses plotCamera() since +ve det rotation matrix. 

TAKES
=====
R_cam:
    3x3 rotation matrix, specified such that it takes the world points to
    the camera coordinate system.
T_cam:
    3x1 translation vector, specified such that its coordinates are
    defined in the camera coordinate system, with the tail at the camera
    center and the head at the world origin.
size (optional, default=50):
    Scale of the drawn camera object - "Size" option from plotCamera().
color (optional, default="red"):
    Color of the drawn camera object - "Color" option from plotCamera().
label (optional, default="C"):
    Label of the drawn camera object - "Label" option from plotCamera().
axes_visible (optional, default=true):
    Boolean indicating whether the frame orientation of the camera axes
    are drawn - "AxesVisible" option from plotCamera().
opacity (optional, default=0):
    Opacity of the drawn camera object - "Opacity" option from plotCamera().

RETURNS
=======
cam:
    The camera object.
%}


% Set defaults.
switch nargin
    case 0
        error("Require rotation matrix and translation vector (in camera coordinates).")
    case 1
        error("Require translation vector (in camera coordinates).")
    case 2
        size=50; color="red"; label="C"; axes_visible=true; opacity=0;
    case 3
        color="red"; label="C"; axes_visible=true; opacity=0;
    case 4
        label="C"; axes_visible=true; opacity=0;
    case 5
        axes_visible=true; opacity=0;
    case 6
        opacity=0;
end

pose_cam = rigidtform3d(R_cam, T_cam);

% pose_cam is the camera pose in CAMERA coordinates, pose_world is 
% the camera's pose in WORLD coordinates (inversion of pose_cam). 
% Note that invert(pose_cam) is equivalent to extr2pose(pose_cam).
pose_world = invert(pose_cam);

plotCamera( ...
    "AbsolutePose", pose_world, ...
    "Size", size, ...
    "Color", color, ...
    "Label", label, ...
    "AxesVisible", axes_visible, ...
    "Opacity", opacity...
);

end