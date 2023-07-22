function save_reconstructed_pts_dltdv8a(framewise_tracked_world_pts, save_filepath)
%{
Create the 'xyzpts' file containing the 3D world coordinates for each
tracked physical point in the format accepted by DLTdv8a. If n physical
points were tracked, we would get the following exported format:

pt1_X, pt1_Y, pt1_Z, pt2_X, pt2_Y, pt2_Z ... ptn_X, ptn_Y, ptn_Z
frame 1
frame 2
.
.
.
frame f

While dltdv8a doesn't really do anything with the 3D points, this feature
is added for future compatibility and potentially skipping the triangulation
part within dltdv8a and isolating it to the reconstruction script in this
toolbox.

TAKES
=====
framewise_world_pts:
    A cell vector of size f x 1, where f is the total number of VALID
    frames from the tracked physical points.
save_filepath:
    Where and with what name to save the file.

%}

default = load('defaults.mat');

DIM_WORLD_COORDS = 3;

num_pts = size(framewise_tracked_world_pts{1}, 2);
num_valid_frames = size(framewise_tracked_world_pts, 1);

num_rows = num_valid_frames + default.DLTDV_TRACKFILE_HEADER_OFFSET;
entries_per_row = num_pts * DIM_WORLD_COORDS;

% Define the matrix we'll convert to csv.
cellarr_to_write = cell(num_rows, entries_per_row);

% Populate header row.
file_header = cell(1, entries_per_row);
for i = 1 : num_pts
    % Must use string to avoid character vectors for headers, which would
    % mess with the size on assignment.
    X_header = sprintf("pt%d_X", i);
    Y_header = sprintf("pt%d_Y", i);
    Z_header = sprintf("pt%d_Z", i);
    file_header(1, 3*(i-1)+1 : 3*i) = {X_header Y_header Z_header};
end

% Fill header row of final matrix.
cellarr_to_write(1, :) = file_header;

% Populate rows for each valid frame.
for f = 1 : num_valid_frames
    X_est = framewise_tracked_world_pts{f};
    file_row = reshape(X_est, 1, []);
    % Each entry is a row vector of floats, so we need to use arrayfun to
    % convert each entry to a 6 decimal-place character vector value with
    % uniform output set to false to make sure we get cells.
    file_row = arrayfun(@(coordinate_value) sprintf('%.6f', coordinate_value), file_row, 'UniformOutput', false);
    cellarr_to_write(f+1, :) = file_row;
end

writecell(cellarr_to_write, save_filepath, 'Delimiter', ',')

end