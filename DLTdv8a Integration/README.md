This is practically an indepdenent part of the toolbox. It is inteded for use with DLTdv8a tracking software, which allows working with video data. This is a functional version that, in conjunction with Bouguet Calibration Toolbox (BCT), allows for quickly setting up projects with mirrors.

> Very few of these functions/scripts are not used in the standard workflow &ndash; they may be removed later. Apart from that, a couple of scripts have untested features (such as mp4 conversion for videos).

# Instructions (download the tutorial videos in this directory)
You can follow along by downloading the `mirror_reconstruction_toolbox` folder and videos from the `test_videos` folder as well.

Note that the majority of inputs have a default option. Such prompts are skippable by entering blank for Command Window prompts, and pressing the *Cancel* button for UI prompts. In case of a skip, the default file locations in `defaults.mat` within a project are used. Note that `defaults.mat` is generated in the project root based on the parameters set in `defaults.m` whenever a project is setup using the script `project_setup.m`. Be careful when changing the parameters in `defaults.m`!

## Step 1: Toolbox Initialization, Project Setup, and Camera + Mirror Calibration

1. To add the toolbox to the path and generate a couple of important files to keep track of projects you'll be creating, run `setup_mirror_recosntruction_toolbox.m`.
2. Create a project in any directory using `project_setup.m`. This will create a 'skeleton' of the project, with pre-defined folders and two files: `project_dir.mat`, that contains the absolute path of this project on the computer, and `defaults.mat`, that contains the default settings shared between various scripts and functions to ensure smooth functionality.
3. Begin the calibration process by running `calib_import_media.m` from the created project's root directory (setting up a project automatically changes directory to the project root).
4. When prompted, enter whether you have calibration images (`i`) or video (`v`).

#### *Images Route*
5. In the pop-up UI box, browse and select the calibration images anywhere on your computer.
6. In the next pop-up UI box, choose the directory to put the images in relative to the project's root directory. The script will automatically rename them in a format optimized for BCT as described in `defaults.m`.

> If you have manually imported the calibration images into the project root, skip Steps 3&ndash;6 and just rename them sequentially using the script `sequential_rename_imgs.m`. This ensures BCT performs optimally and gets rid of any gaps in the image numbers.

#### *Video Route*
5. In the pop-up UI box, browse and select the calibration video from anywhere on your computer. The script will copy and auto-convert it to MP4 if it is in any other format.
6. In the next pop-up UI box, select the path to save the video to within the project directory. The script will then auto-run `calib_extract_vid_frames.m` to extract the video frames.
7. Enter the starting and stopping times for the video in HMS format when prompted. E.g., for 15&ndash;30 seconds, enter `00:00:15` for start and `00:00:30` for stop time. By default (blank inputs) the whole video is used.
8. Enter the format in which to extract the frames (by default, JPG). The script will now extract the frames as {Frame1.jpg, Frame2.jpg, ..., FrameF.jpg} and auto-run `calib_select_img_subset`.
9. Select a subset of the extracted frames to use as calibration images. These frames will be renamed in consecutive order sequetntially, so if you selected {Frame40, Frame80, Frame100, Frame180}, these would be renamed to {Image1, Image2, Image3, Image4} respectively.

> If you have manually imported the calibration video into the project root and it is already MP4, run `calib_extract_vid_frames.m` instead. If the video is not MP4, run `convert_vid_to_mp4.m` instead.

Once you have the calibration images, you can now begin the calibration process with BCT by moving to the image directory and calling `calib_gui` (the toolbox will automatically change directory to the calibration images upon reaching this point after running the import script). The calibration process itself requires Bouguet Calibration Toolbox, which must also be added to the MATLAB path. BCT's usage is detailed on the main `README.md` file.

Note that you may configure the default settings in `defaults.m` within the toolbox path. Any new projects after these changes will use the new settings. To update existing projects' settings, head to the existing project's directory and run `create_defaults_matfile.m`.

### Notes On Calibration
Accuracy is heavily dependent upon good calibration, so make sure you cover a variety of poses when taking the calibration images or recording the calibration video. Signs that your calibration is faulty: Extremely awkward undistortions, or maybe reprojections are good at some points and bad at others.

Remember that you only need one common reference image of the checker which is visible in all views (camera + both mirrors) in case of a 3 view setup. Since each view's calibration is independent, you can select different image subsets for calibrating each view, as long as:

1. You ensure that neither the camera, nor the mirrors, move.
2. You ensure that at least one image is commonly visible in all views.

A good choice for point 2 is to leave the checker flat in front of both the mirrors. Usually, we keep this as the first image. After that, you can free yourself of the worry that the checker is visisble in all views and focus only on one particular view at a time. You may also use BCT's Compute Extrinsic function after calibration to generate extrinsics based on a non-calibration image. Again, this image should be visible in all views.

## Step 2: Calibration Result From BCT to DLTdv8a Format (11 DLT Coefficients)

Once we have the calibration results for each view, we need to merge the necessary variables into one mat-file. The script that performs this in conjunction with generating the 11 DLT coefficients file for DLTdv8a is `calib_process_results.m`. By default, the merged calibration file is named `bct_params.mat` and the DLT coefficients file is named `dlt_coefs.csv`.

After running the script, simply follow the prompts:
- Choose the extrinsic reference image via its suffix. E.g., if calibration set was labeled {Image1, Image2, ..., Image15.jpg}, the suffixes are {1, 2, ..., 15}. If the extrinsic reference is not part of the calibration set (meaning extrinsics were computed via Compute Extrinsic function of BCT), you would enter 'ext' here without the quotes.
- Choose the camera, mirror 1, and mirror 2 calibration result files one by one. If not using a particular view, cancel its selection and it will be skipped. However, you need a minimum of 2 views for this to work.
- Decide where to save the merged BCT parameters and the DLT coefficients file.

This will generate the consolidated BCT parameters file and the DLT coefficients file.

## Step 3 (Optional): Video and Frame Undistortion

If your camera has noticeable distortion or you would just like to work with undistorted videos and images, you can begin the undistortion procedure (otherwise, skip ahead to step 3):

- Run `vid_import.m` in the command window from within the project root directory.
- Locate the video containing the object to be tracked on your computer. The video could be in the various formats accepted by MATLAB's VideoReader, but the import process will convert a copy of it to MP4 and save it in either the default project directory or to a path of your choosing.
- When prompted to undistort the video, type 'y' (w/o quotes) to begin the undistortion process described in `create_undistorted_vid_and_frames.m`.
- When prompted, located and select the merged BCT calibration parameters file from earlier.
- Choose a directory to extract the video frames into. These frames are then undistorted using the distortion coefficients for each view and stored in new folders (one per view) in the extracted frames' directory. The folders are named after the corresponding views, so `cam_rect`, `mir1_rect`, and `mir2_rect`.
- Wait until the script undistorts frames for each view and then re-creates the videos from these undistorted frames. Thus, you will get as many videos as the number of views, each one using a different distortion profile. The videos are stored in the same directory as the original video wit the same name, but suffixed with `{original-name}_cam_rect.mp4`, `{original-name}_mir1_rect.mp4`, and `{original-name}_mir2_rect.mp4`.

Note that color is preserved in the undistorted videos and frames by default. Grayscale conversion will eventually be added as a configurable parameter in `defaults.m`. The function to perform it already exists as `undistort_img_gray.m`. Currently, you can force grayscale conversion by setting grayscale argument of undistort_imgs to `true` in `create_undistorted_vid_and_frames.m`.

> If you already have the video in your project directory, directly run `create_undistorted_vid_and_frames.m` instead of `vid_import.m`. If you want to undistort a directory or a set of images instead of a video, use `create_undistorted_imgs.m` instead.

## Step 4: DLTdv8a Execution and Trackfile Generation

This step is fairly straightforward. Extensive video tutorials as well as written manuals on how to work with DLTdv8a are provided by the authors of the software. If you are just starting with the tool, we recommend that you start learning from the [official DLTdv8a online manual](https://biomech.web.unc.edu/dltdv8_manual/). You can also clone their [git repository](https://github.com/tlhedrick/dltdv) which contains additional information and the codebase.

> The toolbox has only been tested with the app version of DLTdv8a.

- Open up the DLTdv8a app in the project root.
- Create a new project within DLTdv8a and load the videos. Generally, load order is important as it must correspond to the order of DLT coefficients (1st video uses 11 DLT coefficients in the first column of the csv file, 2nd video uses the 2nd column and so on). However, we have only one video, and the mirrors serve as our other two videos, so we can load the same file in twice or thrice for 2 or 3 views.
- When prompted, add the DLT coefficients file generated in the previous step.
- Create as many points as you want to track, and mark each one in the first video on the actual physical object.
- Each marked point generates an epipolar line in the other video frames. Assuming well-calibrated cameras, these are good hints for where the corresponding point is on the mirror views.
- Mark the corresponding points ON THE REFLECTIONS of the object in the second and third videos. If a point is not visible in any view, skip marking it for that view and it will become NaN, which is expected and handled by the toolbox's reconstruction scripts.
- Once the points are marked in all relevant views, set the tracking settings in the DLTdv8a interface according to your project's needs and begin tracking.
- Once you have a suitable tracked result, head to the Points tab in the main DLTdv8a dialog box and export points to begin generating the trackfiles.
- This will pop up a few confirmation boxes &ndash; the important one is that you export the points in "flat" format as sparse is not currently supported.
- Save the entire project DLTdv8a project as a matfile if you wish to do more work later or keep the full state of the project.

The main trackfile that's relevant to us is `{prefix}xypts.csv`, which contains the framewise tracked 2D point (pixel) information for all views.

> Note that you may export the trackfiles anywhere on your device, but for your convenience, it would be best to place them in the trackfiles folder from the project root directory. You can also add any prefix when DLTdv8a asks you to.

## Step 5: DLTdv8a Tracked Point Reconstruction and Estimated World Coordinate Export in DLTdv8a Format

- Run `reconstruct_tracked_pts_bct.m` inside the MATLAB command window from the project root directory.
- You will be prompted for a total of 4 things:
    1. The merged BCT calibration results file (default: `bct_params.mat`) generated in Step 2.
    2. The DLTdv8a 2D points trackfile (default: `{prefix}xypts.csv`) generated in Step 4.
    3. Where to save the estimated 3D world points to (default: `reconstruction/{prefix}xyzpts.csv`).
    4. Whether to use undistorted video frames or not (only valid if the optional Step 3 was completed).

And that's it. The script will then estimate the 3D world coordinates for each tracked point in each view using non-linear least squares (`lsqnonlin`). It will then reproject pixels on to the images using these estimated coordinates, reconstruct them in 3D, plot the cameras alongside the reconstrcuted points, and finally export them in DLTdv8a format.

> Step 2 might produce a warning that the number of frames in the trackfile does not agree with the number of extracted frames. That is not usually much cause for concern since 1 or 2 frames might be off owing to issues with total number of frames and the time-based frame extraction within VideoReader when working with video frames.