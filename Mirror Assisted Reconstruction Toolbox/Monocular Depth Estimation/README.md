# Evaluating Monocular Depth Estimation

Download the [Data](https://drive.google.com/file/d/1w-3NBuTVDN48zmKIkGa3WdiIsypWO2KR/view?usp=sharing) to quickly reproduce some results and get familiar with the scripts.

You are going to need the MDE as well as LCMART data (intrinsics, extrinsics, 3D world points, marked points) in the same format as presented in the [Data/MDE](Data/MDE/) and [Data/LCMART](Data/LCMART/) directories. The following file structured is required:

```tree
Data/
├── MDE/
│   └── <approach_name>/
│       └── <view_name>/
│           ├── color/
│           │   └── <image_name>.jpg
│           ├── depth/
│           │   └── <image_name>_depth_scaled.png
│           └── depth_scales.json
└── LCMART/
    ├── Calibration/
    │   └── bct_params.mat
    ├── Media/
    │   └── Images/
    │       ├── <image_name>.jpg
    │       └── <image_name>_distorted.jpg
    └── Reconstruction/
        └── <image_identifier>/
            ├── <image_name>.jpg
            ├── output.txt
            ├── pixel_reprojections_Camera.png
            ├── pixel_reprojections_Mirror 1.png
            ├── reconstruction.fig
            ├── reprojection_errors.mat
            └── xyzpts.mat
```

- <approach_name> for now is either `Depth-Anything-V2` or `Metric3D-V2`.
- <view_name> is one of: `distorted`, `cam_rect`, `mir1_rect`, and potentially `mir2_rect` per the LCMART conventions if you used two mirrors. `rect` means rectified, i.e., the images are undistorted w.r.t their particular distortion model and intrinsics.

## Usage

We recommend using the **undistorted** images end-to-end.

### MATLAB

The only thing you really need here is to compute the raw depth data from the MDE workflow (unless you already have the raw depth map, in which case you can skip running `scaled_depth_to_metric.m`). This will require two things:

- Depth image: typically a 16-bit PNG file that has been scaled to utilize the full dynamic range of the 16-bit image for viewing ease.
- Pixelwise depth scale (JSON file): this is a JSON file that contains the pixelwise depth scale for the depth image in order to recover the raw metric depth information from the image.

The `scaled_depth_to_metric.m` script does exactly this. It takes in the depth image and the depth scale JSON file, and saves the metric depth map as a .mat file.

If you already had the depth map, then you can head straight to running the eval script as you should already have everything else available through the regular LCMART workflow (camera parameters, i.e. intrinsics AND extrinsics, the marked pixel points, and the reconstructed 3D world points).

> [!NOTE]
> We could perform the same comparison in camera space as well, but the results would more or less be the same, so we stick to the world space for now.

The results of the evaluation workflow as triggered by running `evaluate.m` are saved in the same directory under a folder `evaluation`.

### Python

**WORK IN-PROGRESS** *(and probably not needed, but I like Python too much).*

It's highly recommended to setup a virtual environment with mamba (see [Miniforge](https://github.com/conda-forge/miniforge) for installation details).

```bash
mamba create -n lcmart python=3.10 && mamba activate lcmart
pip install -r requirements.txt
```

Once done, here's generally how you excecute the evaluation workflow:

1. Run either `mark_points.py` to manually mark points in the images, or if you already marked the points in MATLAB and have the .mat file, use `mat_to_py.py` to convert the .mat file to .py format, from where you can convert it to `annotated_coordinates.json` quite easily.

## Terms

### Annotated Coordinates

These are homogenous pixel coordinates for points on an image.

```matlab
% LCMART - created by `point_marker.m`
PATH_MARKED_POINTS = Path(BASEDIR, "marked_points.mat")

% x: 3xN homgenous array of pixel points on the images
% num_points: number of unique physical points in each image
% num_views: not included, but calculatable as N / num_points.
```

We assume 1:1 shape correspondence between the color and depth images, which is mostly true for recent MDE methods.

We recommend using view-wise undistorted images to provide the pixel points for the best accuracy. If you had 2 views, you'd mark the first 100 using the first view's undistorted image, and the next 100 using the second view's undistorted image. The underlying correspondence between points is understood: 1 -> 101, 2 -> 102, and so on.

```python
# Python - created by `mark_points.py`, or converted from .mat to .json
# with `convert_matfiles.py`
PATH_ANNOTATED_COORDINATES = Path(BASEDIR, "annotated_coordinates.json")
```

Where the JSON has the following format (notice the shape is Nx2 instead of 3xN):

```json
[
  {
    "filename": "image_name.jpg",
    "num_physical_points": 100,
    "points": [
      [x_1, y_1],      // start of the first view's 100 points...
      [x_2, y_2],
      ...
      [x_100, y_100],  // end of the first view's 100 points...
      [x_101, y_101],  // start of the second view's 100 points...
      ...
      [x_200, y_200]   // end of the second view's 100 points...
    ]
  }
]
```

You can use `mark_points.py` to create the `annotated_coordinates.json` file using the LCMART images (distorted/undistorted) directly in the JSON format, or if you have a way of converting the `marked_points.mat` files from LCMART to JSON, you can do that too, but you would need to align the format with the JSON format. Assuming two views with a 100 unique physical points, the JSON format would look like this:

### Depth Scale

When encoding depth maps as images, either for viewing ease or precision reasons, dataset curators tend to scale their output by some value. For example, KITTI does so for a precision reason by a factor of 256.0 because they have a long-range dataset. Others could do it so that the maximum depth measurable with their system is represented as "white" (farthest point) in the image. Otherwise, images would appear too dark to make out any details (often for indoor scenes or synthetic datasets, where getting this is easy).

However, this poses a problem when attempting to load depth maps from depth images. Depth maps, or at least the way we define them here, are the *raw* depth values in some metric units (mostly meters/millimeters), unscaled. In most datasets, this definition of a depth map is the ACTUAL METRIC DEPTH as measured by their sensing apparatus.

However, since mostly this is a uniform scaling, we can usually easily recover the original depth. The equation representing this is typically pretty simple:

```plaintext
metric_depth(i, j) = depth_image(i, j) / depth_scale(i, j)
```

Scaled depth is typically 16-bit PNG, so 0-65535; a dataset with maximum depth of 10 meters would have a depth scale computed as 65535 / 10 = 6553.5, s.t. 65535 / 6553.5 = 10 meters, which would be the highest depth representable with the dataset as "white" in the PNG.

The above is used to recover the "metric" depth in [`scaled_depth_to_metric.m`](MATLAB/scaled_depth_to_metric.m). In Python, doing this is very simple, and is performed directly by reading the image and dividing the array by the depth scale where needed (e.g., [`Python`](Python/plot_marked_points_3d_no_align.py)).

Note that in some contexts, the depth_scale may be defined as requiring a MULTIPLICATION with the depth image. Be sure to check which definition applies to your case. But the "divide by" definition above is what we use here.

This is neither strictly related to MATLAB or Python, but rather to Monocular Depth Estimation (MDE) models and depth images vs. depth maps. The format for storing these is not standardized, so I personally create a .json representing each image's depth scale - it's pretty flexible. See an example [JSON](Data/MDE/Depth_Anything_V2/distorted/depth_scales.json).

### Camera Parameters

Camera parameters are primarily intrinsics, extrinsics, and distortion coefficients computed via Bouguet Calibration Toolbox as part of the LCMART workflow. These intrinsics should be used when running depth inference with monocular depth estimation (MDE) models.

You can find an example of the MATLAB version in [bct_params.mat](Data/LCMART/Calibration/bct_params.mat). This can be converted to a `camera_parameters.json` using `convert_matfiles.py` for the Pythonic implementation of the evaluation workflow.

### Baseline Points

Baseline points are the 3D world space coordinates estimated in the 3D reconstruction step of the LCMART workflow. This assumes that the reconstructed 3D points from LCMART are indeed sensible representations of the physical world. This assumption is reasonable due to the reconstruction approach being performed as a non linear least squares optimization problem (via the Levenberg-Marquardt algorithm) with multiple camera views (thus resolving the depth ambiguity in single camera setups).

You can find an example of the MATLAB version in [xyzpts.mat](Data/LCMART/Reconstruction/img1/xyzpts.mat). This can be converted to a `baseline_world_points.json` using `convert_matfiles.py`.

### Point-Set Registration Algorithm

A point-set registration algorithm is used to align two different sets of 3D points on top of each other (or a query on top of a target, depending on how you formulate the problem). Both methods' implementations (in MATLAB as well as Python) is homegrown but should work just fine. We utilize two main algorithms: Horn's Quaternion-Based Absolute Orientation and Procrustes Analysis.

In MATLAB, this is implemented within [`register_points_3d_horn.m`](MATLAB/register_points_3d_horn.m) and [`register_points_3d_procrustes.m`](MATLAB/register_points_3d_procrustes.m), and can be tested with the relevant [test script](MATLAB/Tests/test_register_points_3d.m). You'll also find a `fex_absor.m`, which is a helper function to check `absor.m` from MATLAB File Exchange.

In Python, this is implemented within [`point_set_registration_3d.py`](Python/point_set_registration_3d.py), and can be tested by running it as a script. You'll also find a [`procrustes_scipy.py`](Python/Tests/procrustes_scipy.py) script that tests implementation of `scipy.spatial.procrustes`, but it is an orthognal procrustes solution that does not solve for translation and scale (only rotation). It is a very barebones and provides standardized output (which we can technically unstandardize but it requires extra steps, plus we never get to see the transformation matrix).

## Camera Projection and Backprojection Equations

The following equations describe the relationship between world coordinates, camera coordinates, and image (pixel) coordinates using the camera intrinsic matrix \( K \) and extrinsic parameters \([R|T]\):

\[
\begin{bmatrix}
u' \\
v' \\
s
\end{bmatrix}
=

K_{3 \times 3}
\begin{bmatrix}
R & T
\end{bmatrix}_{3 \times 4}
\begin{bmatrix}
X_w \\
Y_w \\
Z_w \\
1
\end{bmatrix}
\]

where

\[
\begin{bmatrix}
R & T
\end{bmatrix}
\begin{bmatrix}
X_w \\
Y_w \\
Z_w \\
1
\end{bmatrix}
=

\begin{bmatrix}
X_c \\
Y_c \\
Z_c
\end{bmatrix}
\]

Thus,

\[
\begin{bmatrix}
u' \\
v' \\
s
\end{bmatrix}
=

K
\begin{bmatrix}
X_c \\
Y_c \\
Z_c
\end{bmatrix}
\]

This implies

\[
K^{-1}
\begin{bmatrix}
u \\
v \\
1
\end{bmatrix}
=

\begin{bmatrix}
X_c \\
Y_c \\
Z_c
\end{bmatrix}
\]

and

\[
\begin{bmatrix}
X_w \\
Y_w \\
Z_w
\end{bmatrix}
=

\left[
R^T \mid -R^T T
\right]
\begin{bmatrix}
X_c \\
Y_c \\
Z_c
\end{bmatrix}
\]

The camera intrinsic matrix \( K \) is:

\[
K =
\begin{bmatrix}
f_x & 0 & c_x \\
0 & f_y & c_y \\
0 & 0 & 1
\end{bmatrix}
\]

Assuming \( f_x = f_y = f \):

\[
\begin{bmatrix}
u' \\
v' \\
s
\end{bmatrix}
=

\begin{bmatrix}
f X_c + c_x Z_c \\
f Y_c + c_y Z_c \\
Z_c
\end{bmatrix}
\]

So,

\[
u' = f X_c + c_x Z_c
\]
\[
v' = f Y_c + c_y Z_c
\]
\[
s = Z_c
\]

After the perspective divide (\( u = u'/s, v = v'/s \)):

\[
u = \frac{f X_c}{Z_c} + c_x
\]
\[
v = \frac{f Y_c}{Z_c} + c_y
\]
\[
s = 1
\]

From here, we can solve for \( X_c \) and \( Y_c \):

\[
X_c = \frac{u - c_x}{f} Z_c
\]
\[
Y_c = \frac{v - c_y}{f} Z_c
\]

Thus, to recover the 3D camera coordinates from pixel coordinates, we need the depth \( Z_c \), which is provided by monocular depth estimation (MDE) models.
