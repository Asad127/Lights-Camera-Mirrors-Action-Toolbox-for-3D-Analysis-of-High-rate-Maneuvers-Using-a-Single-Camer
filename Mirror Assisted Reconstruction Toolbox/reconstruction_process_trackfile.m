function [framewise_tracked_pixels_converted, num_frames, mask_nan_rows, ...
     num_pts] = reconstruction_process_trackfile(trackfile_csv, num_views)
%{
Reads the 2D tracked points (pixels) as exported from DLTdv8a in "flat"
(csv, table-like) format. The returned format is intended for use with the
script `reconstruct_tracked_pts_bct.m`.

DLTdv8a exports pixel coordinates for all tracked points in the format:
pt1_cam1_X, pt1_cam1_Y, pt1_cam2_X, pt1_cam2_Y, pt2_cam1_X, ...
Each row of the csv has length (2*num_views*num_points).

`reconstruct_tracked_pts_bct.m` assumes the form:
pt1_cam1, pt2_cam1, pt1_cam2, pt2_cam2, ...

where each element is a column vector of size 3x1 (third element being
homogenous coordinate). So each frame gives a 2D array of size (3,
num_views*num_pts).

TODO: Add a reader for sparse format output from DLTdv8a.

TAKES
=====
trackfile_csv:
    Path to the .csv file containing the tracked pixel points.
num_views:
    Number of views in the current experiment - equal to the number of
    columns in the dlt-coefs file.

RETURNS
=======
framewise_tracked_pixels_converted:
    A cell array of size (f, 1), where f is the frame number (current line
    - 1), and each cell is a 2D array of size (3 x 3n), where n is the no.
    of points being tracked such that the first n cols correspond to the n
    points in the first camera, the second set of n cols to the n points in
    the second camera, and similarly for the third. Each row corresponds to
    the homogenous pixel location [x; y; 1].
num_frames:
    An integer representing the total number of frames (non-header rows) in
    the trackfile. This is before filtering out completely nan rows, so
    this is essentially the number of frames in the video assuming flat
    format point export from DLTdv8a.
num_pts:
    An interger representing the number of physical 2D points marked.
mask_nan_rows:
    A boolean vector mask of shape (num_frames, 1) with a value of 1 for
    rows (lines) in the csv file that offered no tracking data whatsoever.
    These correspond to invalid frames that we can discard. This is helpful
    at reconstruction time so as to know which frames to load in, and
    potnetially a sparse video frame extractor where we only store to disk
    the relevant frames containing data.

EXPLANATION
===========================================================================
The main idea is to combine all the x and y-coordinate values in the csv
file. For this, we can try to figure out the patten of indices for x and y
coordinates. The default dltdv8a coordinate ordering looks like:
    pt1_cam1_X, pt1_cam1_Y, pt1_cam2_X, pt1_cam2_y, pt2_cam1_X, ...

As you can see, the indices corresponding to x and y coordinates are:
    x_idx = [1 3 5 7 ...] & y_idx = [2 4 6 8 ...]

However, the reconstruction script and the trackfile differ in the critical
aspect of how they structure the data.

In trackfile, the first `num_views` elements of x_idx and y_idx correspond
to the x & y coordinate of the first pixel point as tracked in all views,
whether 2 or 3 views. Basically, the VIEW changes before the POINT. We need
to re-arrange this so that the POINT changes before the VIEW, i.e., the
first set of `num_pts` consecutive indices corresponds to all the points in
the 1st view. In other words, we loop over all the points for a given view
before moving to the next view.

And that's it! For each frame (each row of the dltdv8a generated csv file
for 2d points), we do this and put the result in a cell array, alongside
the frame number just in case there are missing nan rows in between (no
tracked data in-between different frame sets).

To be clear, if we had 2 views and 3 tracked points and wanted to
reconstruct them using the toolbox script, we would want the indices:
    x_idx = [1 5 9 3 7 11] and y_idx = [2 6 10 4 8 12]

where x_idx 1 5 9 correspond to the x coordinates of all 3 points in the
first view and x_idx 3 7 11 correspond to the same for the second view.
Similarly for the y_idx. This is compatible with our reconstruction script
after we combine each point's x and y coordinate into an array.

As compared to the original dltdv8a format:
    x_idx = [1 3 5 7 9 11] and y = [2 4 6 8 10 12]

where x_idx 1 3 correspond to the x coordinates of only the first point in
both the first and second views (not valid for our reconstruction script).
%}

DIM_COORDS = 2;  % 2 for pixels - unnamed constants not good ;)

% The XY ordering of the pixels in the exported csv. May be useful if you
% ever need to swap X and Y (e.g., to counter world XY-swap problem).
% NOTE FROM FUTURE: We permute the rotation matrix now instead of
% swapping the world X and Y, so this is no longer needed.

xy_order = [1 2];  % [1 2] X 1st, Y 2nd - [2 1] X 2nd, Y 1st.

% % Options for readmatrix with delimited text..
opts = delimitedTextImportOptions;
opts.VariableTypes = "double";
opts.Delimiter = ",";           % separate on comma
opts.DataLines = 2;             % line 2 and onwards contains data
opts.MissingRule = "omitrow";   % skip rows where any value is missing (missing not the same as NaN)
opts.EmptyLineRule = "skip";    % skip any empty lines - won't ever happen

% We should never get two commas without a value in between from DLTdv8a.
% If that happens, something's wrong.
opts.ConsecutiveDelimitersRule = "error";

framewise_tracked_pixels_dltdv8a = readmatrix(trackfile_csv, opts);
num_frames = size(framewise_tracked_pixels_dltdv8a, 1);

% Delete rows where all the data is NaN along the columns (invalid frames)
mask_nan_rows = all(isnan(framewise_tracked_pixels_dltdv8a), 2);
valid_frames = find(~mask_nan_rows);
% invalid_frames = find(mask_nan_rows);
framewise_tracked_pixels_dltdv8a = framewise_tracked_pixels_dltdv8a(~mask_nan_rows, :);

% Extract and define some info for indexing.
num_valid_frames = length(valid_frames);
num_values_per_frame = size(framewise_tracked_pixels_dltdv8a, 2);
num_pts = num_values_per_frame / (num_views * DIM_COORDS);
num_pix_per_frame = num_views * num_pts;

% Warn user if entires rows are NaN.
if num_frames ~= num_valid_frames
    fprintf("[WARNING] Encountered completely NaN rows. This means some frames had no tracked data." + ...
        "\nIf that is expected on your end, this is not a problem.\n")
end

% Init cell array which we'll be putting our re-structured pixel locations in.
% The first column has the pixels, the second has the associated frame
% number.
framewise_tracked_pixels_converted = cell(num_valid_frames, 2);

% Capture the pixel locations for ALL points from a SINGLE frame on a
% PER-VIEW basis. This looks ugly, but does the job.

x_idx = NaN(1, num_pix_per_frame);  % vector of x indices
y_idx = NaN(1, num_pix_per_frame);  % vector of y indices

% Fill the vectors with the indices corresponding to x and y pixel coords
% in the required order of all pixels for a view before changing the view.
for k = 1 : num_views
    x_idx(num_pts*(k-1)+1 : num_pts*k) = ...
        xy_order(1) + DIM_COORDS * (k-1) ...  % init
        : DIM_COORDS * num_views ...          % step
        : num_values_per_frame;               % stop

    y_idx(num_pts*(k-1)+1 : num_pts*k) = ...
        xy_order(2) + DIM_COORDS * (k-1) ...  % init
        : DIM_COORDS * num_views ...          % step
        : num_values_per_frame;               % stop
end

% Populate each cell element with a frame's homogenous pixel locations for
% all points as a (3, num_views * num_points) array.
homogenous_ones = ones(1, num_pts * num_views);
for f = 1 : num_valid_frames
    pixels_f = framewise_tracked_pixels_dltdv8a(f, :);  % the entire row - mixed x and y for all points
    x = pixels_f(x_idx);                                % only the x coords of pixels for all points
    y = pixels_f(y_idx);                                % only the y coords of pixels for all points
    framewise_tracked_pixels_converted{f, 1} = [x; y; homogenous_ones];
    framewise_tracked_pixels_converted{f, 2} = valid_frames(f);
end

return

end